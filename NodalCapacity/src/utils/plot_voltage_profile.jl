"""
Plots voltage profile for load nodes along the feeder.

# Arguments
- `output_folder::String`: Path to the folder where the plot will be saved.
- `output_filename::String`: Name of the plot file (e.g., "voltage_profile.png").

# Returns
- `plt`: The generated plot.
"""
function plot_voltage_profile(output_folder::String, output_filename::String)
    try
        # ------------------------------------------------------------
        # 1) Retrieve Global Data from OpenDSSDirect
        # ------------------------------------------------------------
        all_node_names    = OpenDSSDirect.Circuit.AllNodeNames()
        all_voltages_pu   = OpenDSSDirect.Circuit.AllBusMagPu()
        all_bus_names     = OpenDSSDirect.Circuit.AllBusNames()
        all_bus_distances = OpenDSSDirect.Circuit.AllBusDistances()
        
        println("Global circuit data retrieved successfully.")
        
        # ------------------------------------------------------------
        # 2) Identify Load Nodes by Iterating Over Loads
        # ------------------------------------------------------------
        load_node_names = String[]
        l = OpenDSSDirect.Loads.First()
        while l > 0
            # Get load name (not used further, but available if needed)
            load_name = OpenDSSDirect.Loads.Name()

            # Get bus names connected to the load
            bus_names = OpenDSSDirect.CktElement.BusNames()
            load_bus = bus_names[1]

            # Split to extract bus name and phases (if specified)
            parts = split(load_bus, ".")
            bus_name = parts[1]

            if length(parts) > 1
                # Explicit phases indicated
                phases = parse.(Int, parts[2:end])
                for ph in phases
                    push!(load_node_names, "$(bus_name).$(ph)")
                end
            else
                # No explicit phases; use default phases
                num_ph = OpenDSSDirect.Loads.Phases()
                for ph in 1:num_ph
                    push!(load_node_names, "$(bus_name).$(ph)")
                end
            end

            l = OpenDSSDirect.Loads.Next()
        end
        
        println("Load nodes identified successfully.")
        
        # ------------------------------------------------------------
        # 3) Filter Load Nodes for Voltages and Distances
        # ------------------------------------------------------------
        load_voltages = Float64[]
        load_distances = Float64[]
        load_nodes_filtered = String[]

        for (i, node) in enumerate(all_node_names)
            if node in load_node_names
                # Extract bus name from node
                node_parts = split(node, ".")
                bus_of_node = node_parts[1]

                # Find the bus index to retrieve its distance
                bus_index = findfirst(x -> x == bus_of_node, all_bus_names)
                if bus_index !== nothing
                    dist = all_bus_distances[bus_index]
                    push!(load_distances, dist)
                    push!(load_voltages, all_voltages_pu[i])
                    push!(load_nodes_filtered, node)
                end
            end
        end
        
        println("Load nodes filtered by voltage and distance successfully.")
        
        # ------------------------------------------------------------
        # 4) Sort Data by Distance
        # ------------------------------------------------------------
        combined_data = collect(zip(load_distances, load_voltages, load_nodes_filtered))
        sort!(combined_data, by = x -> x[1])
        distances_sorted = getindex.(combined_data, 1)
        voltages_sorted  = getindex.(combined_data, 2)
        
        println("Data sorted by distance successfully.")
        
        # ------------------------------------------------------------
        # 5) Generate Voltage Profile Plot
        # ------------------------------------------------------------
        plotlyjs()  # Use the PlotlyJS backend
        
        plt = plot(
            distances_sorted,
            voltages_sorted,
            title      = "Voltage Profile of Load Nodes Along the Feeder",
            xlabel     = "Distance from Feeder Head (km)",
            ylabel     = "Voltage [p.u.]",
            seriestype = :scatter,
            marker     = :o,
            markersize = 1,
            legend     = false,
            size       = (800, 600)  # Larger figure size
        )
        
        println("Voltage profile plot generated successfully.")
        
        # ------------------------------------------------------------
        # 6) Save Plot to Output Folder
        # ------------------------------------------------------------
        if !isdir(output_folder)
            println("Creating output folder: $output_folder")
            mkdir(output_folder)
        end
        
        savefig(plt, joinpath(output_folder, output_filename))
        println("Voltage profile saved to $(joinpath(output_folder, output_filename))")
        
        return plt
    catch e
        println("Error in plot_voltage_profile: ", e)
        return nothing
    end
end
