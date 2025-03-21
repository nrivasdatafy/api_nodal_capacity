"""
get_subgraph_from_transformer(
    graph::SimpleDiGraph{Int},
    network::NetworkData,
    transformer_name::String
)

Builds a subgraph starting from the upstream node (src) of the given transformer, 
and traversing all downstream nodes. The returned subgraph is a directed graph
with node indices 1..N, where index 1 corresponds to src if it is visited first.

Returns:
  - rooted_tree::SimpleDiGraph{Int}: The directed subgraph of all reachable nodes from src.
  - updated_network::NetworkData: The new network data for this subgraph.
"""
function get_subgraph_from_transformer(
    graph::SimpleDiGraph{Int},
    network::NetworkData,
    transformer_name::String
)
    # 1) Find the transformer in a case-insensitive manner
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

    # 2) Identify src, dst from the transformer's (src, dst)
    local src, dst = network.trfo_to_nodes_idx[transformer_name]

    # 3) Perform a BFS starting from src to collect all downstream nodes
    #    This ensures a consistent subgraph where src is the root
    local queue = [src]
    local visited = Set{Int}([src])
    while !isempty(queue)
        local current = popfirst!(queue)
        for neighbor in outneighbors(graph, current)
            if !(neighbor in visited)
                push!(visited, neighbor)
                push!(queue, neighbor)
            end
        end
    end

    # 4) Create a list from visited (so we can enumerate it)
    local visited_list = collect(visited)

    # 5) Create mapping old -> new
    local node_index_map = Dict(node => i for (i, node) in enumerate(visited_list))

    # 6) Build the subgraph as a directed SimpleDiGraph
    local rooted_tree = SimpleDiGraph(length(visited_list))
    for node in visited_list
        for neighbor in outneighbors(graph, node)
            if neighbor in visited
                add_edge!(rooted_tree, node_index_map[node], node_index_map[neighbor])
            end
        end
    end

    # 7) Update the NetworkData for the subgraph
    local updated_node_to_index = Dict{String, Int}(k => node_index_map[v] for (k, v) in network.node_to_index if v in visited)
    
    local updated_line_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.line_to_nodes_idx
        if s in visited && d in visited
            updated_line_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    local updated_trfo_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.trfo_to_nodes_idx
        if s in visited && d in visited
            updated_trfo_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    local updated_load_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.load_to_nodes_idx
        if s in visited && d in visited
            updated_load_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    local updated_pvsy_to_nodes_idx = Dict{String, Tuple{Int, Int}}()
    for (k, (s, d)) in network.pvsy_to_nodes_idx
        if s in visited && d in visited
            updated_pvsy_to_nodes_idx[k] = (node_index_map[s], node_index_map[d])
        end
    end

    local updated_line_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_line_to_nodes_idx)))
    local updated_trfo_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_trfo_to_nodes_idx)))
    local updated_load_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_load_to_nodes_idx)))
    local updated_pvsy_to_index = Dict{String, Int}(k => i for (i, k) in enumerate(keys(updated_pvsy_to_nodes_idx)))

    local updated_load_to_phase = Dict{String, String}(k => network.load_to_phase[k]
        for k in keys(network.load_to_phase) if haskey(updated_load_to_nodes_idx, k))

    # Keep line lengths for lines that exist in the subgraph
    local updated_line_to_length = Dict{String, Float64}()
    for (line_name, length_val) in network.line_to_length
        if haskey(network.line_to_nodes_idx, line_name)
            local s, d = network.line_to_nodes_idx[line_name]
            if s in visited && d in visited
                updated_line_to_length[line_name] = length_val
            end
        end
    end

    local updated_network = NetworkData(
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
