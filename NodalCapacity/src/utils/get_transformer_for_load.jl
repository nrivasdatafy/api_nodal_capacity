"""
Get transformer upstream of a given load in the rooted tree.

# Arguments
- `rooted_tree::SimpleDiGraph{Int}`: The directed graph representing the rooted tree.
- `network::NetworkData`: The network data containing mappings.
- `load_name::String`: The name of the load to search for.

# Returns
- `Union{String, Nothing}`: The name of the upstream transformer, or `nothing` if not found.
"""
function get_transformer_for_load(rooted_tree::SimpleDiGraph{Int}, network::NetworkData, load_name::String)::Union{String, Nothing}
    # Verify if the load exists in the load_to_index mapping
    if !haskey(network.load_to_index, load_name)
        println("Warning: Load $load_name not found in the network data.")
        return nothing
    end

    # Get the index of the load and its corresponding fictitious node
    load_idx = network.load_to_index[load_name]
    load_edge = network.load_to_nodes_idx[load_name]
    fictitious_node_idx = load_edge[2]  # Destination node (fictitious)

    # Traverse upwards in the rooted tree to find the transformer
    current_node = load_edge[1]  # Start traversal from the source node of the load
    while true
        for parent in inneighbors(rooted_tree, current_node)
            # Check if the parent corresponds to a transformer
            for (trf_name, (src, dst)) in network.trfo_to_nodes_idx
                if dst == parent
                    return trf_name  # Return the transformer name
                end
            end
            current_node = parent
        end
        # Stop if no parent is found
        if isempty(inneighbors(rooted_tree, current_node))
            break
        end
    end

    println("Warning: No upstream transformer found for load $load_name.")
    return nothing
end
