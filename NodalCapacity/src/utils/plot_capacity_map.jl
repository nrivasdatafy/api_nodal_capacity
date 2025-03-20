"""
Plots the hosting capacity results on the network map.

# Arguments
- `folder_name_model::String`: Folder containing the input files (Lines.txt, Transformers.txt, Loads.txt, Buses.txt).
- `output_folder::String`: Folder to save the plotted network map.
- `output_file::String`: Name of the output file for the network map.
- `nodal_capacity::Dict{String, Float64}`: Dictionary containing the hosting capacity results for each node.

# Returns
- `plt::Plots.Plot{Plots.PlotlyJSBackend}`: Plot object
"""
function plot_capacity_map(folder_name_model::String, output_folder::String, output_file::String, nodal_capacity::Dict{String, Float64})
    
    # Define file paths
    lines_file = joinpath(folder_name_model, "Lines.txt")
    trfos_file = joinpath(folder_name_model, "Transformers.txt")
    loads_file = joinpath(folder_name_model, "Loads.txt")
    buses_file = joinpath(folder_name_model, "Buses.txt")

    # Read bus coordinates
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

    # Collect line segments, transformer segments, and load connections
    line_segments = []
    trfo_segments = []
    load_segments = []

    # Read lines
    open(lines_file, "r") do file
        for line in eachline(file)
            if startswith(lowercase(line), "new line.")
                matches = match(r"bus1=([^.\s]+).*bus2=([^.\s]+)", lowercase(line))
                if matches !== nothing
                    bus1 = matches.captures[1]
                    bus2 = matches.captures[2]
                    if haskey(bus_coords, bus1) && haskey(bus_coords, bus2)
                        push!(line_segments, (bus_coords[bus1], bus_coords[bus2]))
                    end
                else
                    println("Read lines matches == nothing") 
                end
            end
        end
    end

    # Read transformers
    open(trfos_file, "r") do file
        for line in eachline(file)
            if startswith(lowercase(line), "new transformer.")
                matches = match(r"buses=\[([^.\s]+)\s+([^.\s]+)\]", lowercase(line))
                if matches !== nothing
                    bus1 = matches.captures[1]
                    bus2 = matches.captures[2]
                    if haskey(bus_coords, bus1) && haskey(bus_coords, bus2)
                        push!(trfo_segments, (bus_coords[bus1], bus_coords[bus2]))
                    end
                else
                    println("Read transformers matches == nothing") 
                end
            end
        end
    end

    # Read loads
    open(loads_file, "r") do file
        for line in eachline(file)
            if startswith(lowercase(line), "new load.")
                matches = match(r"bus1=([^.:\s]+)", lowercase(line))
                if matches !== nothing
                    bus = matches.captures[1]
                    if haskey(bus_coords, bus)
                        push!(load_segments, bus_coords[bus])
                    end
                else
                    println("Read loads matches == nothing") 
                end
            end
        end
    end

    # Plot the network  
    plotlyjs()
    plt = plot(title="Electrical Network Map", xlabel="X Coordinate", ylabel="Y Coordinate", legend=false)

    # Plot buses with hosting capacity colors
    count = 0
    for (bus_name, coords) in bus_coords
        count = count + 1
        display(count)
        if haskey(nodal_capacity, bus_name)
            capacity = nodal_capacity[bus_name]
            color = cgrad(:viridis)[round(Int, capacity * 255) + 1]  # Map capacity to a color
            scatter!(plt, [coords[1]], [coords[2]], color=color, markersize=3, label="")
        end
    end

    # Plot lines
    for segment in line_segments
        start, end_ = segment
        plot!(plt,[start[1], end_[1]], [start[2], end_[2]], color=:blue, lw=0.5, label="")
    end
    
    # Plot transformers
    for segment in trfo_segments
        start, end_ = segment
        plot!(plt,[start[1], end_[1]], [start[2], end_[2]], color=:red, lw=1.0, label="")
    end

    # Save the plot
    savefig(plt, joinpath(output_folder, output_file))
    println("Hosting capacity map saved to $(joinpath(output_folder, output_file))")

    return plt
end
