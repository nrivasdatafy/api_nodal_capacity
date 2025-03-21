using OpenDSSDirect

"""
get_hosting_capacity(
    rooted_tree::SimpleDiGraph{Int},
    rooted_network::NetworkData,
    node_name::String,
    folder_path_model::String
)::Float64

Computes a single numeric "allowed capacity" for a PV system (without storage) at the specified node,
based on both the Installed Capacity Limit (CIP) and the Permitted Excess Injection (IEP).
If the final computed IEP exceeds CIP, it is clamped to CIP. Negative partial results for IEP are
clamped to zero.

Algorithm Outline:

1) **Read FeederData.txt**: Retrieve feeder_dmin_day and feeder_dmin_night from the file located in `folder_path_model`.
2) **Upstream Transformer**: Find the transformer's name that feeds `node_name` via `get_transformer_for_node`.
3) **Minimum Demands**: Use `compute_all_transformers_dmin(feeder_dmin_day, feeder_dmin_night)` to compute each transformer's day/night minimum demands. Select the relevant transformer's demands (dmin_day, dmin_night).
4) **Subgraph Extraction**: Extract the subtree for that transformer (using `get_subgraph_from_transformer`). Sum the capacities of other PV systems in that subgraph (sum_other_GD).
5) **Deepest Node**: Call `find_deepest_node` on the subtree to find the node that yields the highest short-circuit level impact. Then compute SCC via `get_node_short_circuit_level`.
6) **CIP Calculation**: 
   - CIP_FV = SCC / (Kvs * Kman)
   - CIP_CCC = 0.1 * SCC
   - CIP = min(CIP_FV, CIP_CCC)
7) **IEP Calculation** for a PV system without storage:
   - IEP_F = max(0, dmin_day - sum_other_GD)
   - IEP_RT = max(0, (SCC / 20) - sum_other_GD)
   - IEP = min(IEP_F, IEP_RT)
   - If IEP > CIP, IEP = CIP
8) **Return**: The final single numeric value = IEP.

Assumptions and Notes:
- This example is simplified for a single-phase, purely PV system at low voltage. 
- In a real implementation, you may need to handle asynchronous/synchronous machines, storages, or multi-phase systems.
- If the user wants to exclude the new system's capacity from `sum_other_GD`, additional logic is required to detect that system in the subgraph and skip it.
- Negative partial values for IEP are interpreted as zero injection capacity.

Arguments:
- rooted_tree: A directed graph (rooted) for the entire system.
- rooted_network: The associated NetworkData structure for the entire system.
- node_name: The name of the node (bus) where the new PV is considered.
- folder_path_model: Path to the folder containing "FeederData.txt" for day/night min demands.

Returns:
- Float64: A single numeric value (kW) representing the final allowed injection capacity.
"""
function get_hosting_capacity(
    rooted_tree::SimpleDiGraph{Int},
    rooted_network::NetworkData,
    node_name::String,
    folder_path_model::String
)::Float64

    println("\nCalculating hosting capacity for node $node_name...")

    # 1) Read feeder min demands from FeederData.txt
    println("\nReading feeder data...")
    local feed_data_path = joinpath(folder_path_model, "FeederData.txt")
    local feed_data = Dict{String, Float64}()
    open(feed_data_path, "r") do file
        for line in eachline(file)
            local key, value = split(line, "=")
            feed_data[key] = parse(Float64, value)
        end
    end
    local feeder_dmin_day   = feed_data["feeder_dmin_day"]
    local feeder_dmin_night = feed_data["feeder_dmin_night"]

    # 2) Check node existence, find upstream transformer
    println("\nFinding upstream transformer for $node_name...")
    if !haskey(rooted_network.node_to_index, node_name)
        error("Node $node_name not found in the network.")
    end
    local transformer_name = get_transformer_for_node(rooted_tree, rooted_network, node_name)
    if transformer_name === nothing
        error("No upstream transformer found for node $node_name.")
    end
    println("Upstream transformer for $node_name: $transformer_name")

    # 3) Compute transformer's min demands (day/night)
    println("\nComputing transformer min demands...")
    local transformer_dmin = compute_all_transformers_dmin(feeder_dmin_day, feeder_dmin_night)
    if !haskey(transformer_dmin, transformer_name)
        error("Transformer $transformer_name not found in the min-demand dictionary.")
    end
    local (dmin_day, dmin_night) = transformer_dmin[transformer_name]
    println("Min demand for $transformer_name -> Day: $dmin_day kW, Night: $dmin_night kW")

    # 4) Extract subtree for the transformer, sum other PV capacities
    println("\nExtracting subtree for transformer $transformer_name...")
    local subtree, subnetwork = get_subgraph_from_transformer(rooted_tree, rooted_network, transformer_name)
    println("Subgraph extracted for transformer $transformer_name.")

    local sum_other_GD = 0.0
    local pv_idx = OpenDSSDirect.PVsystems.First()
    while pv_idx > 0
        local pv_name = OpenDSSDirect.PVsystems.Name()
        if haskey(subnetwork.pvsy_to_nodes_idx, pv_name)
            local capacity = OpenDSSDirect.PVsystems.Pmpp()  # in kW
            sum_other_GD += capacity
        end
        pv_idx = OpenDSSDirect.PVsystems.Next()
    end
    println("Sum of other PV systems under $transformer_name: $sum_other_GD kW")

    # 5) Find deepest node in subtree, compute SCC
    println("\nFinding the deepest node in the subtree...")
    local (farthest_node, farthest_bus, total_distance) = find_deepest_node(subtree, subnetwork, rooted_network)
    println("Deepest node in subtree is index=$farthest_node, bus=$farthest_bus, distance=$total_distance m")

    println("Computing short-circuit level at $farthest_bus...")
    local scc = get_node_short_circuit_level(farthest_bus)
    println("Short-circuit level at $farthest_bus: $scc kVA")

    # --------------------------------------------------------------------
    # CIP Calculation
    # CIP_FV = SCC / (Kvs * Kman)
    # CIP_CCC = 0.1 * SCC
    # CIP = min(CIP_FV, CIP_CCC)
    # (For a PV system with inverters at BT)
    # --------------------------------------------------------------------
    println("\nComputing Capacidad de Instalada Permitida (CIP)...")
    local Kvs  = 33.0
    local Kman = 1.0
    local CIP_FV  = scc / (Kvs * Kman)
    local CIP_CCC = 0.1 * scc
    local CIP     = min(CIP_FV, CIP_CCC)

    println("CIP_FV = $CIP_FV kW")
    println("CIP_CCC = $CIP_CCC kW")
    println("CIP = $CIP kW")

    # --------------------------------------------------------------------
    # IEP Calculation (PV system without storage)
    # IEP = min(IEP_F, IEP_RT)
    # If IEP > CIP => IEP = CIP
    # Also clamp negative partial values to 0
    # --------------------------------------------------------------------
    println("\nComputing Inyección de Exceso Permitida (IEP)...")
    # 6a) IEP_F: (daytime min demand - sum_other_GD)
    local raw_IEPF_day = dmin_day - sum_other_GD
    local IEP_F        = max(0.0, raw_IEPF_day)

    println("IEP_F (current flow) = $IEP_F kW")

    # 6b) IEP_RT: (SCC / 20) - sum_other_GD
    local MCIP   = scc / 20.0
    local raw_IEP_RT = MCIP - sum_other_GD
    println("MCIP = $MCIP kW")
    println("sum_other_GD = $sum_other_GD kW")
    local IEP_RT     = max(0.0, raw_IEP_RT)

    println("IEP_RT (voltage reg) = $IEP_RT kW")

    local IEP = min(IEP_F, IEP_RT)

    println("IEP (final) = $IEP kW")

    # 7) If IEP > CIP => clamp to CIP

    println("\n resumen")
    println("CIP = $CIP kW")
    println("IEP = $IEP kW")

    if IEP > CIP
        IEP = CIP
    end
    println("Hosting Capacity = $IEP kW")

    return IEP
end
