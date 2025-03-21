"""
compute_nodal_capacity(folder_name_model::String, output_folder::String; umbral_kv::Float64=1.0)::Dict{String, Float64}

Computes the (normalized) hosting capacity for all **low-voltage** nodes in the network, excluding fictitious nodes
(i.e., those starting with "e_"). It uses OpenDSSDirect to check each bus's nominal voltage (Bus.kVBase()) against
the `umbral_kv` threshold.

Steps:
1. Optionally load/compile the OpenDSS model. (Commented out here, adjust as needed.)
2. Create the undirected network graph (graph, network) using `create_network_graph`.
3. For each node in `network.node_to_index`, skip if:
   - The node name starts with "e_"
   - Or the bus voltage >= umbral_kv
4. For each qualifying node, call `get_hosting_capacity(graph, network, node_name)` and store the result.
5. Normalize the capacities between 0 and 1 and return the resulting dictionary.

Arguments:
- folder_name_model::String: Path to the folder containing the OpenDSS model.
- output_folder::String: Path to the folder where outputs will be saved.
- umbral_kv::Float64: The voltage threshold below which a bus is considered low-voltage. Default is 1.0 kV.

Returns:
- Dict{String, Float64}: A dictionary mapping low-voltage node names to their normalized hosting capacities.
"""
function compute_nodal_capacity(
    folder_name_model::String,
    output_folder::String;
    umbral_kv::Float64=1.0
)::Dict{String, Float64}
    # -----------------------------------------------------------------------
    # 1) (Optionally) load and compile the OpenDSS model, if not already done.
    # create_opendss_model(folder_name_model, output_folder)
    # compile_opendss_model(output_folder)
    # add_feeder_meter()
    #
    # This part is commented out here. Adjust or remove as needed.
    # -----------------------------------------------------------------------

    # 2) Create the undirected network graph (and NetworkData) from the OpenDSS model
    graph, network = create_network_graph()

    # Prepare a dictionary to store hosting capacities
    nodal_capacity = Dict{String, Float64}()

    # 3) For each node in the network, skip if "e_" or if voltage >= umbral_kv
    for (node_name, _) in network.node_to_index
        # Skip fictitious nodes
        if startswith(node_name, "e_")
            continue
        end

        # Use OpenDSSDirect to set the active bus and get its base voltage
        OpenDSSDirect.Circuit.SetActiveBus(node_name)
        kv_base = OpenDSSDirect.Bus.kVBase()

        println("Node: $node_name, kV Base: $kv_base")

        # If bus is valid and below the threshold, compute hosting capacity
        if kv_base > 0 && kv_base < umbral_kv
            println("Computing hosting capacity for node: $node_name")
            nodal_capacity[node_name] = get_hosting_capacity(graph, network, node_name)
        end
    end

    # If no nodes qualified, return empty dictionary
    if isempty(nodal_capacity)
        return nodal_capacity
    end

    # 4) Normalize the capacities between 0 and 1
    min_capacity = minimum(values(nodal_capacity))
    max_capacity = maximum(values(nodal_capacity))
    for node_name in keys(nodal_capacity)
        if max_capacity > min_capacity
            nodal_capacity[node_name] = (nodal_capacity[node_name] - min_capacity) / (max_capacity - min_capacity)
        else
            nodal_capacity[node_name] = 1.0
        end
    end

    return nodal_capacity
end
