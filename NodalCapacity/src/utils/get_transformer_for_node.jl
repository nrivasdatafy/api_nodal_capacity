"""
Get transformer upstream of a given node in the rooted tree.

# Arguments
- `rooted_tree::SimpleDiGraph{Int}`: The directed graph representing the rooted tree.
- `network::NetworkData`: The network data containing mappings.
- `node_name::String`: The name of the node to search for.

# Returns
- `Union{String, Nothing}`: The name of the upstream transformer, or `nothing` if not found.
"""
function get_transformer_for_node(rooted_tree::SimpleDiGraph{Int}, network::NetworkData, node_name::String)::Union{String, Nothing}
    # Verify if the node exists in the node_to_index mapping
    if !haskey(network.node_to_index, node_name)
        println("Warning: Node $node_name not found in the network data.")
        return nothing
    end

    # Get the index of the node
    current_node = network.node_to_index[node_name]

    # Traverse upwards in the rooted tree to find the transformer
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

    println("Warning: No upstream transformer found for node $node_name.")
    return nothing
end
