"""
Get transformer upstream of a given load in the rooted tree, ignoring case.

# Arguments
- `rooted_tree::SimpleDiGraph{Int}`: The directed graph representing the rooted tree.
- `network::NetworkData`: The network data containing mappings.
- `load_name::String`: The name of the load to search for (case-insensitive).

# Returns
- `Union{String, Nothing}`: The name of the upstream transformer, or `nothing` if not found.
"""
function get_transformer_for_load(rooted_tree::SimpleDiGraph{Int}, network::NetworkData, load_name::String)::Union{String, Nothing}
    # Find the canonical load name ignoring case
    canonical_load = nothing
    for k in keys(network.load_to_index)
        if lowercase(k) == lowercase(load_name)
            canonical_load = k
            break
        end
    end
    if canonical_load === nothing
        println("Warning: Load $load_name not found in the network data.")
        return nothing
    end

    # Get the load's node indices
    load_edge = network.load_to_nodes_idx[canonical_load]
    # Start the traversal from the source node of the load edge
    current_node = load_edge[1]

    while true
        local_parents = inneighbors(rooted_tree, current_node)
        if isempty(local_parents)
            break
        end
        for parent in local_parents
            # Check if the parent corresponds to any transformer (case-insensitive check can be added if needed)
            for (trf_name, (src, dst)) in network.trfo_to_nodes_idx
                if dst == parent
                    return trf_name  # Return the transformer name as stored
                end
            end
            current_node = parent
        end
    end

    println("Warning: No upstream transformer found for load $load_name.")
    return nothing
end
