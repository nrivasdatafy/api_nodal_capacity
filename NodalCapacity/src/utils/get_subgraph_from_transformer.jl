"""
Get a subgraph starting from the upstream node of a transformer, identified by its name,
and include all downstream nodes and edges.

# Arguments
- `graph::SimpleDiGraph{Int}`: The directed graph.
- `network::NetworkData`: The network data containing node and edge mappings.
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
    # Validar que el transformador existe
    if !(haskey(network.trfo_to_nodes_idx, transformer_name))
        error("Transformer '$transformer_name' does not exist in the network data.")
    end

    # Obtener el edge del transformador (src = aguas arriba, dst = aguas abajo)
    src, dst = network.trfo_to_nodes_idx[transformer_name]

    # DFS desde el nodo aguas abajo (dst)
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

    dfs_collect(dst)  # Iniciar DFS desde el nodo aguas abajo

    # Agregar manualmente el nodo aguas arriba (src) y su conexión con dst
    pushfirst!(visited, src)

    # Crear el mapeo de índices
    node_index_map = Dict(node => i for (i, node) in enumerate(visited))

    # Crear el subgrafo dirigido
    rooted_tree = SimpleDiGraph(length(visited))
    for node in visited
        for neighbor in outneighbors(graph, node)
            if neighbor in visited
                add_edge!(rooted_tree, node_index_map[node], node_index_map[neighbor])
            end
        end
    end
    # Agregar manualmente el edge del transformador
    add_edge!(rooted_tree, node_index_map[src], node_index_map[dst])

    # Actualizar NetworkData
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

    # Recalcular índices para líneas, transformadores y cargas
    updated_line_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_line_to_nodes_idx)))
    updated_trfo_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_trfo_to_nodes_idx)))
    updated_load_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_load_to_nodes_idx)))
    updated_pvsy_to_index = Dict(k => i for (i, k) in enumerate(keys(updated_pvsy_to_nodes_idx)))

    # Crear NetworkData actualizado
    updated_network = NetworkData(
        node_to_index=updated_node_to_index,
        line_to_index=updated_line_to_index,
        trfo_to_index=updated_trfo_to_index,
        load_to_index=updated_load_to_index,
        pvsy_to_index=updated_pvsy_to_index,
        line_to_nodes_idx=updated_line_to_nodes_idx,
        trfo_to_nodes_idx=updated_trfo_to_nodes_idx,
        load_to_nodes_idx=updated_load_to_nodes_idx,
        pvsy_to_nodes_idx=updated_pvsy_to_nodes_idx
    )

    return rooted_tree, updated_network
end