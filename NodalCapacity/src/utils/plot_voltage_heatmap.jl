"""
Plots a combined voltage heatmap (for buses) and network map, highlighting:
1) Looped lines in red dotted style.
2) Low-voltage (<= umbral_kv) vs. medium-voltage lines in different colors (based on Bus.kVBase).
3) The final line to each load in magenta.
4) Hover tooltips for lines and transformers (showing their names).
5) Medium-voltage lines are drawn in blue dotted style.
6) Load-connected buses are shown as triangles, transformer-connected buses as squares, 
   and other buses as circles, all colored by voltage using the same heatmap.
7) The figure is sized larger (800x600) and uses an equal aspect ratio.

Uses the PlotlyJS backend.

# Arguments
- folder_name_model::String: Path to the folder containing input files 
  (Buses.txt, Lines.txt, Transformers.txt, Loads.txt).
- output_folder::String: Path to the folder where the plot will be saved.
- output_file::String: Name of the output file (e.g., "network_map_voltage_loops.html").
- umbral_kv::Float64: Voltage threshold (kV) to distinguish LV vs. MV lines. Default 1.0.
- alpha_level::Float64: Transparency for bus markers in the heatmap (0.0 = fully transparent, 1.0 = opaque).

# Returns
- p::Union{Plots.Plot, Nothing}: The generated plot, or nothing if an error occurs.
"""
function plot_voltage_heatmap(
    folder_name_model::String,
    output_folder::String,
    output_file::String;
    umbral_kv::Float64 = 1.0,
    alpha_level::Float64 = 0.6
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
        # 3) Parse Lines (storing line_name, bus1, bus2, coords)
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
        # 4) Parse Transformers (storing bus coords + transformer_name)
        #     We'll also track which buses are "transformer buses".
        # ------------------------------------------------------------
        trfos_file = joinpath(folder_name_model, "Transformers.txt")
        trfo_segments = Vector{Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64},String}}()
        transformer_buses = Set{String}()

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
                            push!(transformer_buses, bus1)
                            push!(transformer_buses, bus2)

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
        # 5) Read Loads to Identify Final Lines to Loads + load buses
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
        # 7) Get bus voltage results. We'll separate them into three categories:
        #    a) load buses
        #    b) transformer buses (that aren't load)
        #    c) other buses
        # ------------------------------------------------------------
        all_bus_names = OpenDSSDirect.Circuit.AllBusNames()
        all_voltages_pu = OpenDSSDirect.Circuit.AllBusMagPu()

        global_min_v = minimum(all_voltages_pu)
        global_max_v = maximum(all_voltages_pu)

        load_xs,         load_ys,         load_vs         = Float64[], Float64[], Float64[]
        load_hovertext = String[]

        transf_xs,       transf_ys,       transf_vs       = Float64[], Float64[], Float64[]
        transf_hovertext = String[]

        other_xs,        other_ys,        other_vs        = Float64[], Float64[], Float64[]
        other_hovertext = String[]

        missing_buses = String[]

        for (i, bus) in enumerate(all_bus_names)
            bus_lower = lowercase(bus)
            if haskey(bus_coords, bus_lower)
                (x, y) = bus_coords[bus_lower]
                v_pu   = all_voltages_pu[i]
                # Priority: if in load => triangle; else if in transf => square; else circle
                if bus_lower in load_buses
                    push!(load_xs, x)
                    push!(load_ys, y)
                    push!(load_vs, v_pu)
                    push!(load_hovertext, "Load Bus: $bus\nVoltage: $(round(v_pu, digits=3)) p.u.")
                elseif bus_lower in transformer_buses
                    push!(transf_xs, x)
                    push!(transf_ys, y)
                    push!(transf_vs, v_pu)
                    push!(transf_hovertext, "Transformer Bus: $bus\nVoltage: $(round(v_pu, digits=3)) p.u.")
                else
                    push!(other_xs, x)
                    push!(other_ys, y)
                    push!(other_vs, v_pu)
                    push!(other_hovertext, "Bus: $bus\nVoltage: $(round(v_pu, digits=3)) p.u.")
                end
            else
                push!(missing_buses, bus)
            end
        end

        if !isempty(missing_buses)
            println("Warning: The following buses are missing in Buses.txt: ", join(missing_buses, ", "))
        end

        println("Bus voltages parsed successfully.")

        # ------------------------------------------------------------
        # 8) Create the Plot
        #    - Tamaño: (800, 600)
        #    - aspect_ratio=:equal para mantener la misma escala en X/Y
        # ------------------------------------------------------------
        p = plot(
            title         = "Voltage Heatmap & Network",
            xlabel        = "X Coordinate",
            ylabel        = "Y Coordinate",
            legend        = :topright,
            aspect_ratio  = :equal,
            size          = (800, 600)
        )

        println("Plot initialized successfully.")

        # ------------------------------------------------------------
        # 9) Plot Lines con Leyenda:
        #    - Si la línea está en loop => rojo punteado
        #    - Si bus2 es load => magenta
        #    - Si la tensión de línea <= umbral_kv => verde sólido (LV)
        #    - Si no => azul punteado (MV)
        # ------------------------------------------------------------
        # Variables para controlar que se añada la etiqueta solo la primera vez
        plotted_looped   = false
        plotted_final_load = false
        plotted_lv       = false
        plotted_mv       = false

        for ((x1,y1), (x2,y2), line_name, bus1_lower, bus2_lower) in line_segments
            circuit_line_name = lowercase("line.$line_name")
            line_kv = get_line_voltage_from_buses(bus1_lower, bus2_lower)
            line_hover = repeat(["Line: $line_name"], 2)

            if circuit_line_name in looped_set
                label_val = !plotted_looped ? "Line - Loop" : ""
                plot!(p, [x1, x2], [y1, y2],
                    color = :red,
                    linestyle = :dot,
                    lw = 2.5,
                    label = label_val,
                    hover = line_hover
                )
                plotted_looped = true
            else
                if bus2_lower in load_buses
                    label_val = !plotted_final_load ? "Line - Load" : ""
                    plot!(p, [x1, x2], [y1, y2],
                        color = :magenta,
                        linestyle = :solid,
                        lw = 1,
                        label = label_val,
                        hover = line_hover
                    )
                    plotted_final_load = true
                else
                    if line_kv <= umbral_kv
                        label_val = !plotted_lv ? "Line - LV" : ""
                        plot!(p, [x1, x2], [y1, y2],
                            color = :green,
                            linestyle = :solid,
                            lw = 2,
                            label = label_val,
                            hover = line_hover
                        )
                        plotted_lv = true
                    else
                        label_val = !plotted_mv ? "Line - MV" : ""
                        plot!(p, [x1, x2], [y1, y2],
                            color = :blue,
                            linestyle = :dot,
                            lw = 3,
                            label = label_val,
                            hover = line_hover
                        )
                        plotted_mv = true
                    end
                end
            end
        end
        println("Lines plotted successfully.")

        # ------------------------------------------------------------
        # 10) Plot Transformers (en cyan dashed) con leyenda
        # ------------------------------------------------------------
        plotted_trf = false
        for ((x1, y1), (x2, y2), trf_name) in trfo_segments
            trf_hover = repeat(["Transformer: $trf_name"], 2)
            label_val = !plotted_trf ? "Transformer" : ""
            plot!(p, [x1, x2], [y1, y2],
                color = :cyan,
                lw = 1.5,
                linestyle = :dash,
                label = label_val,
                hover = trf_hover
            )
            plotted_trf = true
        end
        println("Transformers plotted successfully.")

        # ------------------------------------------------------------
        # 11) Plot the Buses en 3 conjuntos:
        #     a) Otros (círculos, con colorbar)
        #     b) Transformer (cuadrados)
        #     c) Load (triángulos)
        # ------------------------------------------------------------
        zlims_val = (global_min_v, global_max_v)

        # 11a) "Otros" Buses => círculos (con colorbar)
        scatter!(
            p,
            other_xs,
            other_ys,
            marker_z       = other_vs,
            hover          = other_hovertext,
            alpha          = alpha_level,
            markersize     = 6,
            c              = :viridis,
            colorbar_title = "Voltage (p.u.)",
            cbar           = true,
            zlims          = zlims_val,
            shape          = :circle,
            label          = "Nodes - Other"
        )
        println("Other buses plotted successfully.")

        # 11b) Transformer Buses => cuadrados (sin colorbar)
        scatter!(
            p,
            transf_xs,
            transf_ys,
            marker_z  = transf_vs,
            hover     = transf_hovertext,
            alpha     = alpha_level,
            markersize= 6,
            c         = :viridis,
            cbar      = false,
            zlims     = zlims_val,
            shape     = :square,
            label     = "Nodes - Transformers"
        )
        println("Transformer buses plotted successfully.")

        # 11c) Load Buses => triángulos (sin colorbar)
        scatter!(
            p,
            load_xs,
            load_ys,
            marker_z  = load_vs,
            hover     = load_hovertext,
            alpha     = alpha_level,
            markersize= 6,
            c         = :viridis,
            cbar      = false,
            zlims     = zlims_val,
            shape     = :utriangle,
            label     = "Nodes - Loads"
        )
        println("Load buses plotted successfully.")

        # ------------------------------------------------------------
        # 12) Save & (Optionally) Display
        # ------------------------------------------------------------
        if !isdir(output_folder)
            println("Creating output folder: $output_folder")
            mkdir(output_folder)
        end

        savefig(p, joinpath(output_folder, output_file))
        println("Plot saved to $(joinpath(output_folder, output_file))")
        println("Voltage heatmap with loops plot generated successfully.")

        return p
    catch e
        println("Error in plot_voltage_heatmap_with_loops: ", e)
        return nothing
    end
end