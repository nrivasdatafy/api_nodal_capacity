"""
Compute the hosting capacity for all nodes in the network, excluding fictitious nodes.

# Inputs
- `folder_name_model::String`: Path to the folder containing the OpenDSS model of the network.
- `output_folder::String`: Path to the folder where outputs will be saved.

# Returns
- `Dict{String, Float64}`: A dictionary mapping node names to their normalized hosting capacities.
"""
function compute_nodal_capacity(folder_name_model::String, output_folder::String)::Dict{String, Float64}
    # Load and compile the OpenDSS model
    #output_filename = "master.txt"
    #create_opendss_model(folder_name_model, output_folder, output_filename)
    #compile_opendss_model(output_folder, output_filename)
    #add_feeder_meter()

    # Generate the network graph and rooted tree
    graph, network, root_node = create_network_graph()
    rooted_tree, rooted_network = generate_rooted_tree(graph, network, root_node)

    # Compute the hosting capacity for all nodes
    nodal_capacity = Dict{String, Float64}()
    for (node_name, _) in rooted_network.node_to_index
        # Skip nodes that start with "e_"
        if !startswith(node_name, "e_")
            nodal_capacity[node_name] = get_hosting_capacity(rooted_tree, rooted_network, node_name)
        end
    end

    # Normalize capacities between 0 and 1
    min_capacity = minimum(values(nodal_capacity))
    max_capacity = maximum(values(nodal_capacity))
    for node_name in keys(nodal_capacity)
        if max_capacity > min_capacity
            nodal_capacity[node_name] = (nodal_capacity[node_name] - min_capacity) / (max_capacity - min_capacity)
        else
            nodal_capacity[node_name] = 1.0  # All nodes have the same capacity
        end
    end

    return nodal_capacity
end
