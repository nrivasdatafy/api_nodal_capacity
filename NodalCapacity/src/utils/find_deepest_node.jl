"""
find_deepest_node(
    subtree::SimpleDiGraph{Int},
    subnetwork::NetworkData,
    network::NetworkData
) -> (farthest_node::Int, farthest_bus::String, total_distance::Float64)

Finds the deepest node in a subtree by:
1. Dynamically finding the 'root_sub' (the node with no parents).
2. Doing a DFS from 'root_sub', accumulating distances from subnetwork.line_to_length.
3. If the farthest node is fictitious (starts with \"e_\"), returns its parent instead.

Returns a tuple: (subtree_node_index, bus_name, distance).
"""
function find_deepest_node(
    subtree::SimpleDiGraph{Int},
    subnetwork::NetworkData,
    network::NetworkData
)

    # 1) Identificar el nodo raíz del subgrafo: aquel que no tiene inneighbors
    function find_subtree_root(subtree::SimpleDiGraph{Int})::Int
        for n in 1:nv(subtree)
            if isempty(inneighbors(subtree, n))
                return n
            end
        end
        error("No root found in this subtree (no node with empty inneighbors).")
    end

    local root_sub = find_subtree_root(subtree)

    # 2) Crear un mapeo invertido: índice => nombre del bus en el subgrafo
    local index_to_node = Dict{Int, String}()
    for (bus, idx) in subnetwork.node_to_index
        index_to_node[idx] = bus
    end

    # 3) Función auxiliar para calcular la distancia entre dos nodos (s, d)
    #    según subnetwork.line_to_nodes_idx y subnetwork.line_to_length.
    function get_distance(parent_idx::Int, child_idx::Int)
        for (line_name, (s, d)) in subnetwork.line_to_nodes_idx
            if s == parent_idx && d == child_idx
                if haskey(subnetwork.line_to_length, line_name)
                    return subnetwork.line_to_length[line_name]
                else
                    break
                end
            end
        end
        return 1.0  # default if no match found
    end

    # 4) DFS para acumular distancias desde root_sub
    local max_distance = Ref(0.0)
    local farthest_node = Ref(root_sub)
    local node_distance = Dict{Int, Float64}()

    function dfs(node::Int, dist_accum::Float64)
        node_distance[node] = dist_accum
        if dist_accum > max_distance[]
            max_distance[] = dist_accum
            farthest_node[] = node
        end
        for neighbor in outneighbors(subtree, node)
            dfs(neighbor, dist_accum + get_distance(node, neighbor))
        end
    end

    # 5) Iniciar DFS desde root_sub
    dfs(root_sub, 0.0)

    # 6) Recuperar el nodo más lejano
    local final_node = farthest_node[]
    local final_bus = index_to_node[final_node]
    local final_distance = node_distance[final_node]

    # 7) Si es un nodo ficticio (\"e_\"), tomar su padre en vez
    if startswith(final_bus, "e_")
        local parents = inneighbors(subtree, final_node)
        if !isempty(parents)
            local parent_node = first(parents)
            final_node = parent_node
            final_bus = index_to_node[parent_node]
            final_distance = node_distance[parent_node]
        end
    end

    return (final_node, final_bus, final_distance)
end
