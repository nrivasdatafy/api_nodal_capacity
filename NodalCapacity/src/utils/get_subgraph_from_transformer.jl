# File: get_subgraph_from_transformer.jl

"""
Extract a subgraph starting from the upstream node of a transformer (case-insensitive),
including all downstream nodes and edges, and update the NetworkData mappings accordingly.

Returns a tuple:
  - rooted_tree::SimpleDiGraph{Int}: The directed subgraph (rooted tree).
  - updated_network::NetworkData: The updated network data with new indices.
"""
function get_subgraph_from_transformer(
    graph::SimpleDiGraph{Int},
    network::NetworkData,
    transformer_name::String
)
    # Find transformer name in a case-insensitive way.
    local found_transformer = nothing
    for key in keys(network.trfo_to_nodes_idx)
        if lowercase(key) == lowercase(transformer_name)
            found_transformer = key
            break
        end
    end
    if found_transformer === nothing
        error("Transformer '$transformer_name' does not exist in the network data.")
    end
    transformer_name = found_transformer

    # Obtain the transformer edge (src = upstream, dst = downstream)
    src, dst = network.trfo_to_nodes_idx[transformer_name]

    # Perform DFS starting from the downstream node (dst)
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
    dfs_collect(dst)
    pushfirst!(visited, src)  # Manually add the upstream node

    # Create mapping from old node indices to new indices
    node_index_map = Dict{Int, Int}(node => i for (i, node) in enumerate(visited))

    # Build the directed subgraph
    rooted_tree = SimpleDiGraph(length(visited))
    for node in visited
        for neighbor in outneighbors(graph, node)
            if neighbor in visited
                add_edge!(rooted_tree, node_index_map[node], node_index_map[neighbor])
            end
        end
    end
    add_edge!(rooted_tree, node_index_map[src], node_index_map[dst])  # Ensure transformer edge is included

    # Update NetworkData mappings
    updated_node_to_index = Dict{String, Int}(k => node_index_map[v] for (k, v) in network.node_to_index if v in visited)
    
    updated_line_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.line_to_nodes_idx
        if s in visited && d in visited
            updated_line_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_trfo_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.trfo_to_nodes_idx
        if s in visited && d in visited
            updated_trfo_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_load_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.load_to_nodes_idx
        if s in visited && d in visited
            updated_load_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_pvsy_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.pvsy_to_nodes_idx
        if s in visited && d in visited
            updated_pvsy_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    updated_line_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_line_to_nodes_idx)))
    updated_trfo_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_trfo_to_nodes_idx)))
    updated_load_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_load_to_nodes_idx)))
    updated_pvsy_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_pvsy_to_nodes_idx)))
    
    updated_load_to_phase = Dict{String, String}(k => network.load_to_phase[k]
        for k in keys(network.load_to_phase) if haskey(updated_load_to_nodes_idx, k))

    # Update line lengths: keep only lines whose endpoints are in visited.
    updated_line_to_length = Dict{String, Float64}()
    for (line_name, length_val) in network.line_to_length
        if haskey(network.line_to_nodes_idx, line_name)
            s, d = network.line_to_nodes_idx[line_name]
            if s in visited && d in visited
                updated_line_to_length[line_name] = length_val
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
