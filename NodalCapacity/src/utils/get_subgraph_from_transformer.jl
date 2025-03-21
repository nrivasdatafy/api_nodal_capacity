"""
Get a subgraph starting from the upstream node of a transformer, identified by its name,
and include all downstream nodes and edges.

# Arguments
- `graph::SimpleDiGraph{Int}`: The directed graph.
- `network::NetworkData`: The network data containing node and edge mappings (including load_to_phase).
- `transformer_name::String`: The name of the transformer.

# Returns
- `SimpleDiGraph{Int}`: A directed graph representing the rooted tree of the subgraph.
- `NetworkData`: Updated network data with consistent indices for the subgraph.
"""
function get_subgraph_from_transformer(
    graph::SimpleDiGraph{Int},
    network::NetworkData,
    transformer_name::String
)
    # Validate that the transformer exists
    if !(haskey(network.trfo_to_nodes_idx, transformer_name))
        error("Transformer '$transformer_name' does not exist in the network data.")
    end

    # Obtain the transformer edge (src = upstream, dst = downstream)
    src, dst = network.trfo_to_nodes_idx[transformer_name]

    # DFS starting from the downstream node (dst)
    visited = Vector{Int}()
    function dfs_collect(node::Int)
        if !(node in visited)
            push!(visited, node)
            for neighbor in outneighbors(graph, node)
                if !(neighbor in visited)
                    dfs_collect(neighbor)
                end
            end
        end
    end

    dfs_collect(dst)  # Start DFS from downstream node

    # Manually add the upstream node (src) and its connection with dst
    pushfirst!(visited, src)

    # Create the mapping of old node indices to new indices
    node_index_map = Dict(node => i for (i, node) in enumerate(visited))

    # Create the directed subgraph
    rooted_tree = SimpleDiGraph(length(visited))
    for node in visited
        for neighbor in outneighbors(graph, node)
            if neighbor in visited
                add_edge!(rooted_tree, node_index_map[node], node_index_map[neighbor])
            end
        end
    end
    # Ensure the transformer edge is present
    add_edge!(rooted_tree, node_index_map[src], node_index_map[dst])

    # Update NetworkData mappings
    updated_node_to_index = Dict(k => node_index_map[v] for (k, v) in network.node_to_index if v in visited)
    
    updated_line_to_nodes_idx = Dict(
        k => (node_index_map[s], node_index_map[d])
        for (k, (s, d)) in network.line_to_nodes_idx if s in visited && d in visited
    )
    updated_trfo_to_nodes_idx = Dict(
        k => (node_index_map[s], node_index_map[d])
        for (k, (s, d)) in network.trfo_to_nodes_idx if s in visited && d in visited
    )
    updated_load_to_nodes_idx = Dict(
        k => (node_index_map[s], node_index_map[d])
        for (k, (s, d)) in network.load_to_nodes_idx if s in visited && d in visited
    )
    updated_pvsy_to_nodes_idx = Dict(
        k => (node_index_map[s], node_index_map[d])
        for (k, (s, d)) in network.pvsy_to_nodes_idx if s in visited && d in visited
    )

    # Recalculate indices for lines, transformers, loads, and PV systems
    updated_line_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_line_to_nodes_idx)))
    updated_trfo_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_trfo_to_nodes_idx)))
    updated_load_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_load_to_nodes_idx)))
    updated_pvsy_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_pvsy_to_nodes_idx)))
    
    # Update load_to_phase: include only those loads that are present in the updated load mapping
    updated_load_to_phase = Dict{String, String}(k => network.load_to_phase[k]
        for k in keys(network.load_to_phase) if haskey(updated_load_to_nodes_idx, k))

    # Create updated NetworkData
    updated_network = NetworkData(
        node_to_index = updated_node_to_index,
        line_to_index = updated_line_to_index,
        trfo_to_index = updated_trfo_to_index,
        load_to_index = updated_load_to_index,
        pvsy_to_index = updated_pvsy_to_index,
        line_to_nodes_idx = updated_line_to_nodes_idx,
        trfo_to_nodes_idx = updated_trfo_to_nodes_idx,
        load_to_nodes_idx = updated_load_to_nodes_idx,
        pvsy_to_nodes_idx = updated_pvsy_to_nodes_idx,
        load_to_phase = updated_load_to_phase
    )

    return rooted_tree, updated_network
end
