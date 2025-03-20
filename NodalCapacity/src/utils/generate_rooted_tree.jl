"""
Generate a rooted tree from an undirected graph and update NetworkData mappings.

# Arguments
- `graph::SimpleGraph{Int}`: The undirected tree graph.
- `network::NetworkData`: The network data containing node and edge mappings (including load_to_phase).
- `root::Int`: The node to use as the root.

# Returns
- `SimpleDiGraph{Int}`: A directed graph representing the rooted tree.
- `NetworkData`: Updated network data with consistent indices.
"""
function generate_rooted_tree(graph::SimpleGraph{Int}, network::NetworkData, root::Int)
    rooted_tree = SimpleDiGraph(nv(graph))  # Directed graph with the same number of nodes
    visited = Set{Int}()
    node_index_map = Dict{Int, Int}()  # Old node index => New node index
    new_index = 1

    # Depth-First Search to build the rooted tree and map new node indices
    function dfs(node::Int)
        if !(node in visited)
            push!(visited, node)
            node_index_map[node] = new_index
            new_index += 1
        end

        for neighbor in neighbors(graph, node)
            if !(neighbor in visited)
                add_edge!(rooted_tree, node_index_map[node], new_index)
                dfs(neighbor)
            end
        end
    end

    # Start DFS from the root node
    dfs(root)

    # Update NetworkData indices
    updated_node_to_index = Dict(k => node_index_map[v] for (k, v) in network.node_to_index)
    updated_line_to_nodes_idx = Dict(
        k => (node_index_map[src], node_index_map[dst])
        for (k, (src, dst)) in network.line_to_nodes_idx if src in visited && dst in visited
    )
    updated_trfo_to_nodes_idx = Dict(
        k => (node_index_map[src], node_index_map[dst])
        for (k, (src, dst)) in network.trfo_to_nodes_idx if src in visited && dst in visited
    )
    updated_load_to_nodes_idx = Dict(
        k => (node_index_map[src], node_index_map[dst])
        for (k, (src, dst)) in network.load_to_nodes_idx if src in visited && dst in visited
    )
    updated_pvsy_to_nodes_idx = Dict(
        k => (node_index_map[src], node_index_map[dst])
        for (k, (src, dst)) in network.pvsy_to_nodes_idx if src in visited && dst in visited
    )

    # Recalculate the indices for lines, transformers, loads, and PV systems based on the new structure
    updated_line_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_line_to_nodes_idx)))
    updated_trfo_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_trfo_to_nodes_idx)))
    updated_load_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_load_to_nodes_idx)))
    updated_pvsy_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_pvsy_to_nodes_idx)))

    # Update load_to_phase: only include those loads that are present in the updated load mapping
    updated_load_to_phase = Dict{String, String}(k => network.load_to_phase[k]
        for k in keys(network.load_to_phase) if haskey(updated_load_to_nodes_idx, k))

    # Build and return the updated NetworkData
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
