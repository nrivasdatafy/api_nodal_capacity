"""
get_transformer_for_node(rooted_tree::SimpleDiGraph{Int}, network::NetworkData, node_name::String)::Union{String, Nothing}

Finds the **immediately upstream** transformer of a given node in the rooted tree (case-insensitive).
If the node itself is the secondary side of a transformer, that transformer's name is returned
immediately (rather than climbing further up to a higher-level transformer).

Arguments:
- `rooted_tree::SimpleDiGraph{Int}`: A directed graph representing the rooted tree.
- `network::NetworkData`: The network data containing mappings (trfo_to_nodes_idx, etc.).
- `node_name::String`: The name of the node to search for (case-insensitive).

Returns:
- `Union{String, Nothing}`: The name of the upstream transformer, or `nothing` if not found.
"""
function get_transformer_for_node(
    rooted_tree::SimpleDiGraph{Int},
    network::NetworkData,
    node_name::String
)::Union{String, Nothing}
    # 1) Find the canonical node name (case-insensitive)
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

    # 2) Get the index of the canonical node
    current_node_idx = network.node_to_index[canonical_node]

    # 3) We'll climb up the tree until we find a transformer for which `dst == current_node_idx`.
    #    If the node itself is the `dst` side of a transformer, we return it right away.

    while true
        # 3a) Check if current_node_idx is the secondary side of a transformer
        for (trf_name, (src, dst)) in network.trfo_to_nodes_idx
            if dst == current_node_idx
                return trf_name
            end
        end

        # 3b) If not found, move one step upward in the tree
        parents = inneighbors(rooted_tree, current_node_idx)
        if isempty(parents)
            # No more parents, no transformer found
            break
        end

        # 3c) In a tree, there's usually only one parent, so we take the first
        current_node_idx = first(parents)
    end

    println("Warning: No upstream transformer found for node $node_name.")
    return nothing
end
