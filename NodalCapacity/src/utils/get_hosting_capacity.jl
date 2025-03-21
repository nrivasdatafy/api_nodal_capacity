"""
get_hosting_capacity(
    rooted_tree::SimpleDiGraph{Int},
    rooted_network::NetworkData,
    node_name::String
)::Float64

Computes the hosting capacity (Capacidad Instalada Permitida, CIP) for a specific node in the network,
according to simplified normative criteria. The steps are:

1. Identify the upstream transformer of the node (via get_transformer_for_node).
2. Compute the transformer's daytime and nighttime minimum demands (via compute_all_transformers_dmin).
3. Extract the subgraph (subtree) downstream of that transformer (via get_subgraph_from_transformer).
4. Find the deepest node in that subtree (via find_deepest_node).
5. Compute the short-circuit level (SCC) at that deepest node (via get_node_short_circuit_level).
6. Apply two simplified normative criteria:
   a) Voltage fluctuation criterion (CIP_FV = SCC / (Kvs * Kman))
   b) Short-circuit current impact criterion (CIP_CCC = 0.1 * SCC)
7. The CIP is the minimum of these two criteria.
8. (Optional) The CIP can be further adjusted based on the transformer's minimum demand.

Returns:
  - Float64: The calculated hosting capacity (kW).
"""
function get_hosting_capacity(
    rooted_tree::SimpleDiGraph{Int},
    rooted_network::NetworkData,
    node_name::String
)::Float64
    # 1. Check if the node exists in the network
    if !haskey(rooted_network.node_to_index, node_name)
        error("Node $node_name not found in the network.")
    end

    # 2. Identify the upstream transformer of the node
    transformer_name = get_transformer_for_node(rooted_tree, rooted_network, node_name)
    if transformer_name === nothing
        error("No upstream transformer found for node $node_name.")
    end
    println("Upstream transformer for $node_name: $transformer_name")

    # 3. Compute the transformer's minimum demands (daytime and nighttime)
    #    (Example values for feeder demands; adjust as needed.)
    feeder_dmin_day = 50.0
    feeder_dmin_night = 30.0
    transformer_dmin = compute_all_transformers_dmin(feeder_dmin_day, feeder_dmin_night)

    if !haskey(transformer_dmin, transformer_name)
        error("Transformer $transformer_name not found in the computed minimum-demand dictionary.")
    end
    dmin_day, dmin_night = transformer_dmin[transformer_name]
    println("Minimum demand for $transformer_name -> Day: $dmin_day kW, Night: $dmin_night kW")

    # 4. Extract the subtree for the transformer
    subtree, subnetwork = get_subgraph_from_transformer(rooted_tree, rooted_network, transformer_name)
    println("Subgraph extracted for transformer $transformer_name.")

    # 5. Find the deepest node in the subtree (using distances if available)
    farthest_node, farthest_bus, total_distance = find_deepest_node(subtree, subnetwork, rooted_network)
    println("Deepest node in subtree (index=$farthest_node) is bus: $farthest_bus, distance: $total_distance meters")

    # 6. Compute the short-circuit level (SCC) at that deepest node
    println("Computing short-circuit level at $farthest_bus...")
    scc = get_node_short_circuit_level(farthest_bus)
    println("Short-circuit level at $farthest_bus: $scc kVA")

    # 7. Apply simplified normative criteria
    # 7a) Voltage fluctuation criterion
    Kvs = 33.0   # e.g. for low-voltage connections
    Kman = 1.0   # e.g. for inverter-based generation
    CIP_FV = scc / (Kvs * Kman)
    println("CIP_FV (voltage fluctuation) = $CIP_FV kW")

    # 7b) Short-circuit current impact criterion
    CIP_CCC = 0.1 * scc
    println("CIP_CCC (short-circuit impact) = $CIP_CCC kW")

    # CIP is the minimum of the two
    CIP = min(CIP_FV, CIP_CCC)
    println("Hosting capacity (CIP) = $CIP kW")

    # 8. (Optional) Adjust CIP based on transformer minimum demand
    # Example:
    # available_margin = dmin_day
    # CIP = min(CIP, available_margin)
    # println("CIP adjusted by margin = $CIP kW")

    return CIP
end
