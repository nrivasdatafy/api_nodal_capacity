"""
Get transformer upstream of a given node in the rooted tree, ignoring case.

# Arguments
- `rooted_tree::SimpleDiGraph{Int}`: The directed graph representing the rooted tree.
- `network::NetworkData`: The network data containing mappings.
- `node_name::String`: The name of the node to search for (case-insensitive).

# Returns
- `Union{String, Nothing}`: The name of the upstream transformer, or `nothing` if not found.
"""
function get_transformer_for_node(rooted_tree::SimpleDiGraph{Int}, network::NetworkData, node_name::String)::Union{String, Nothing}
    # Find the canonical node name (case-insensitive)
    canonical_node = nothing
    for k in keys(network.node_to_index)
        if lowercase(k) == lowercase(node_name)
            canonical_node = k
            break
        end
    end
    if canonical_node === nothing
        println("Warning: Node $node_name not found in the network data.")
        return nothing
    end

    # Get the index of the canonical node
    current_node = network.node_to_index[canonical_node]

    # Traverse upwards in the rooted tree to find the transformer
    while true
        local_parents = inneighbors(rooted_tree, current_node)
        if isempty(local_parents)
            break
        end
        for parent in local_parents
            # Check if the parent corresponds to a transformer
            for (trf_name, (src, dst)) in network.trfo_to_nodes_idx
                if dst == parent
                    return trf_name  # Return the transformer name
                end
            end
            current_node = parent
        end
    end

    println("Warning: No upstream transformer found for node $node_name.")
    return nothing
end
