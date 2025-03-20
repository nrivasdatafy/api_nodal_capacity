"""
Plots a combined network map, highlighting:
1) Looped lines in red dotted style.
2) Low-voltage (<= voltage_threshold) vs. medium-voltage lines in different colors (based on Bus.kVBase).
3) The final line to each load in magenta.
4) Hover tooltips for lines and transformers (showing their names).
5) Medium-voltage lines are drawn in blue dotted style.
6) Transformers are drawn in cyan dashed style.
7) The figure is sized larger (800x600) and uses an equal aspect ratio.

Uses the PlotlyJS backend.

# Arguments
- `folder_name_model::String`: Path to the folder containing input files 
  (Buses.txt, Lines.txt, Transformers.txt, Loads.txt).
- `output_folder::String`: Path to the folder where the plot will be saved.
- `output_file::String`: Name of the output file (e.g., "network_map_loops.html").
- `voltage_threshold::Float64`: Voltage threshold (kV) to distinguish LV vs. MV lines. Default 1.0.

# Returns
- `p::Union{Plots.Plot, Nothing}`: The generated plot, or `nothing` if an error occurs.
"""
function plot_network_map(
    folder_name_model::String,
    output_folder::String,
    output_file::String;
    voltage_threshold::Float64 = 1.0
)
    try
        plotlyjs()  # Use the PlotlyJS backend

        # ------------------------------------------------------------
        # 1) Helper function to get nominal line voltage from bus1 & bus2
        # ------------------------------------------------------------
        function get_line_voltage_from_buses(bus1::String, bus2::String)::Float64
            bus1_kv = 0.0
            bus2_kv = 0.0

            if OpenDSSDirect.Circuit.SetActiveBus(bus1) != -1
                bus1_kv = OpenDSSDirect.Bus.kVBase()
            end

            if OpenDSSDirect.Circuit.SetActiveBus(bus2) != -1
                bus2_kv = OpenDSSDirect.Bus.kVBase()
            end

            return min(bus1_kv, bus2_kv)
        end

        # ------------------------------------------------------------
        # 2) Read Bus Coordinates
        # ------------------------------------------------------------
        buses_file = joinpath(folder_name_model, "Buses.txt")
        bus_coords = Dict{String, Tuple{Float64, Float64}}()

        open(buses_file, "r") do file
            for line in eachline(file)
                parts = split(line)
                if length(parts) >= 3
                    bus_name = lowercase(parts[1])
                    x = parse(Float64, parts[2])
                    y = parse(Float64, parts[3])
                    bus_coords[bus_name] = (x, y)
                end
            end
        end

        println("Bus coordinates read successfully.")

        # ------------------------------------------------------------
        # 3) Parse Lines (storing line_name, bus1, bus2, coordinates)
        # ------------------------------------------------------------
        lines_file = joinpath(folder_name_model, "Lines.txt")
        line_segments = Vector{Tuple{
            Tuple{Float64,Float64},  # (x1,y1)
            Tuple{Float64,Float64},  # (x2,y2)
            String,                  # line_name
            String,                  # bus1
            String                   # bus2
        }}()

        if isfile(lines_file)
            open(lines_file, "r") do file
                for raw_line in eachline(file)
                    line_lower = lowercase(raw_line)
                    if startswith(line_lower, "new line.")
                        line_name_match = match(r"(?i)new\s+line\.([^.\s]+)", raw_line)
                        bus1_match = match(r"(?i)bus1=([^.\s]+)", raw_line)
                        bus2_match = match(r"(?i)bus2=([^.\s]+)", raw_line)

                        parsed_line_name = line_name_match !== nothing ? line_name_match.captures[1] : "unknown"
                        parsed_bus1 = bus1_match !== nothing ? bus1_match.captures[1] : ""
                        parsed_bus2 = bus2_match !== nothing ? bus2_match.captures[1] : ""

                        parsed_bus1_lower = lowercase(parsed_bus1)
                        parsed_bus2_lower = lowercase(parsed_bus2)

                        if haskey(bus_coords, parsed_bus1_lower) && haskey(bus_coords, parsed_bus2_lower)
                            (x1, y1) = bus_coords[parsed_bus1_lower]
                            (x2, y2) = bus_coords[parsed_bus2_lower]
                            push!(line_segments, ((x1, y1), (x2, y2), parsed_line_name, parsed_bus1_lower, parsed_bus2_lower))
                        end
                    end
                end
            end
        else
            println("Warning: Lines.txt not found in $folder_name_model")
        end

        println("Line segments parsed successfully.")

        # ------------------------------------------------------------
        # 4) Parse Transformers (storing bus coordinates + transformer_name)
        #     Also track which buses are transformer buses.
        # ------------------------------------------------------------
        trfos_file = joinpath(folder_name_model, "Transformers.txt")
        trfo_segments = Vector{Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64},String}}()

        if isfile(trfos_file)
            open(trfos_file, "r") do file
                for line in eachline(file)
                    line_lower = lowercase(line)
                    if startswith(line_lower, "new transformer.")
                        # e.g. "new transformer.mytransf phases=2 ..."
                        name_match = match(r"(?i)new\s+transformer\.([^.\s]+)", line)
                        trf_name = name_match !== nothing ? name_match.captures[1] : "unknown"

                        matches = match(r"buses=\[([^.\s]+)\s+([^.\s]+)\]", line_lower)
                        if matches !== nothing
                            bus1 = matches.captures[1]
                            bus2 = matches.captures[2]

                            if haskey(bus_coords, bus1) && haskey(bus_coords, bus2)
                                push!(trfo_segments, (bus_coords[bus1], bus_coords[bus2], trf_name))
                            end
                        end
                    end
                end
            end
        else
            println("Warning: Transformers.txt not found in $folder_name_model")
        end

        println("Transformer segments parsed successfully.")

        # ------------------------------------------------------------
        # 5) Read Loads to Identify Final Lines to Loads
        # ------------------------------------------------------------
        loads_file = joinpath(folder_name_model, "Loads.txt")
        load_buses = Set{String}()
        if isfile(loads_file)
            open(loads_file, "r") do file
                for line in eachline(file)
                    line_lower = lowercase(line)
                    if startswith(line_lower, "new load.")
                        matches = match(r"bus1=([^.:\s]+)", line_lower)
                        if matches !== nothing
                            load_bus = matches.captures[1]
                            push!(load_buses, load_bus)
                        end
                    end
                end
            end
        else
            println("Warning: Loads.txt not found in $folder_name_model")
        end

        println("Load buses parsed successfully.")

        # ------------------------------------------------------------
        # 6) Retrieve looped elements (AllLoopedPairs -> Vector{String})
        # ------------------------------------------------------------
        looped_elements_array = OpenDSSDirect.Topology.AllLoopedPairs()
        looped_set = Set{String}(lowercase.(looped_elements_array))

        println("Looped elements retrieved successfully.")

        # ------------------------------------------------------------
        # 7) Create the Plot
        #    - Size: (800, 600)
        #    - aspect_ratio=:equal to maintain the same scale in X/Y
        # ------------------------------------------------------------
        p = plot(
            title         = "Network Map",
            xlabel        = "X Coordinate",
            ylabel        = "Y Coordinate",
            legend        = :topright,
            aspect_ratio  = :equal,
            size          = (800, 600)
        )

        println("Plot initialized successfully.")

        # ------------------------------------------------------------
        # 8) Plot Lines with Legend:
        #    - If the line is looped => red dotted
        #    - If bus2 is a load => magenta
        #    - If the line voltage <= voltage_threshold => solid green (LV)
        #    - Otherwise => blue dotted (MV)
        # ------------------------------------------------------------
        # Variables to control that the label is added only the first time
        plotted_looped    = false
        plotted_final_load = false
        plotted_lv        = false
        plotted_mv        = false

        for ((x1, y1), (x2, y2), line_name, bus1_lower, bus2_lower) in line_segments
            circuit_line_name = lowercase("line.$line_name")
            line_kv = get_line_voltage_from_buses(bus1_lower, bus2_lower)
            line_hover = repeat(["Line: $line_name"], 2)

            if circuit_line_name in looped_set
                label_val = !plotted_looped ? "Line - Loop" : ""
                plot!(p, [x1, x2], [y1, y2],
                    color     = :red,
                    linestyle = :dot,
                    lw        = 2.5,
                    label     = label_val,
                    hover     = line_hover
                )
                plotted_looped = true
            else
                if bus2_lower in load_buses
                    label_val = !plotted_final_load ? "Line - Load" : ""
                    plot!(p, [x1, x2], [y1, y2],
                        color     = :magenta,
                        linestyle = :solid,
                        lw        = 1,
                        label     = label_val,
                        hover     = line_hover
                    )
                    plotted_final_load = true
                else
                    if line_kv <= voltage_threshold
                        label_val = !plotted_lv ? "Line - LV" : ""
                        plot!(p, [x1, x2], [y1, y2],
                            color     = :green,
                            linestyle = :solid,
                            lw        = 2,
                            label     = label_val,
                            hover     = line_hover
                        )
                        plotted_lv = true
                    else
                        label_val = !plotted_mv ? "Line - MV" : ""
                        plot!(p, [x1, x2], [y1, y2],
                            color     = :blue,
                            linestyle = :dot,
                            lw        = 3,
                            label     = label_val,
                            hover     = line_hover
                        )
                        plotted_mv = true
                    end
                end
            end
        end
        println("Lines plotted successfully.")

        # ------------------------------------------------------------
        # 9) Plot Transformers (in cyan dashed) with Legend
        # ------------------------------------------------------------
        plotted_trf = false
        for ((x1, y1), (x2, y2), trf_name) in trfo_segments
            trf_hover = repeat(["Transformer: $trf_name"], 2)
            label_val = !plotted_trf ? "Transformer" : ""
            plot!(p, [x1, x2], [y1, y2],
                color     = :cyan,
                lw        = 1.5,
                linestyle = :dash,
                label     = label_val,
                hover     = trf_hover
            )
            plotted_trf = true
        end
        println("Transformers plotted successfully.")

        # ------------------------------------------------------------
        # 10) Save & (Optionally) Display
        # ------------------------------------------------------------
        if !isdir(output_folder)
            println("Creating output folder: $output_folder")
            mkdir(output_folder)
        end

        savefig(p, joinpath(output_folder, output_file))
        println("Plot saved to $(joinpath(output_folder, output_file))")
        println("Network map with loops plot generated successfully.")

        return p
    catch e
        println("Error in plot_network_map_with_loops: ", e)
        return nothing
    end
end
