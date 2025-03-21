# File: generate_rooted_tree.jl

"""
Generate a rooted tree from an undirected graph and update NetworkData mappings.

This function performs a depth-first search starting from a given root and assigns new indices to nodes.
It also updates the line_to_length field to include only those lines whose endpoints are in the tree.

Returns a tuple:
  - rooted_tree::SimpleDiGraph{Int}: The resulting directed (rooted) tree.
  - updated_network::NetworkData: The updated network data with new indices.
"""
function generate_rooted_tree(graph::SimpleGraph{Int}, network::NetworkData, root::Int)
    
    # Create a directed graph with the same number of vertices as the undirected graph
    rooted_tree = SimpleDiGraph(nv(graph))
    visited = Set{Int}()
    node_index_map = Dict{Int, Int}()  # Original index -> new index
    new_index = 1

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

    dfs(root)

    # Update network mappings
    updated_node_to_index = Dict{String, Int}(k => node_index_map[v] for (k, v) in network.node_to_index if v in visited)
    
    updated_line_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (line, (s, d)) in network.line_to_nodes_idx
        if s in visited && d in visited
            updated_line_to_nodes_idx[line] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_trfo_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (trf, (s, d)) in network.trfo_to_nodes_idx
        if s in visited && d in visited
            updated_trfo_to_nodes_idx[trf] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_load_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (load, (s, d)) in network.load_to_nodes_idx
        if s in visited && d in visited
            updated_load_to_nodes_idx[load] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_pvsy_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (pv, (s, d)) in network.pvsy_to_nodes_idx
        if s in visited && d in visited
            updated_pvsy_to_nodes_idx[pv] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_line_to_index = Dict{String, Int}()
    for (i, line) in enumerate(keys(updated_line_to_nodes_idx))
        updated_line_to_index[line] = i
    end

    updated_trfo_to_index = Dict{String, Int}()
    for (i, trf) in enumerate(keys(updated_trfo_to_nodes_idx))
        updated_trfo_to_index[trf] = i
    end

    updated_load_to_index = Dict{String, Int}()
    for (i, load) in enumerate(keys(updated_load_to_nodes_idx))
        updated_load_to_index[load] = i
    end

    updated_pvsy_to_index = Dict{String, Int}()
    for (i, pv) in enumerate(keys(updated_pvsy_to_nodes_idx))
        updated_pvsy_to_index[pv] = i
    end

    updated_load_to_phase = Dict{String, String}(k => network.load_to_phase[k]
        for k in keys(network.load_to_phase) if haskey(updated_load_to_nodes_idx, k))

    # Update line lengths: keep only lines whose endpoints are in visited.
    updated_line_to_length = Dict{String, Float64}()
    for (line, len_val) in network.line_to_length
        if haskey(network.line_to_nodes_idx, line)
            s, d = network.line_to_nodes_idx[line]
            if s in visited && d in visited
                updated_line_to_length[line] = len_val
            end
        end
    end

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
        load_to_phase = updated_load_to_phase,
        line_to_length = updated_line_to_length
    )

    return rooted_tree, updated_network
end
