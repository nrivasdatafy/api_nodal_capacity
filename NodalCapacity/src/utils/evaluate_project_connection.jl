"""
Evaluate if a project meets all technical connection criteria.

# Inputs
- `folder_name_model::String`: Path to the folder containing the OpenDSS model of the network.
- `output_folder::String`: Path to the folder where outputs will be saved.
- `project_name::String`: Name of the PV project.
- `project_capacity::Float64`: Installed capacity of the PV system in kVA.
- `max_injection::Float64`: Maximum allowable power injection in kVA.
- `connection_node::String`: Name of the network node where the project will be connected.
- `power_factor::Float64`: Power factor of the PV system.
- `connection_with_inverter::Bool`: Indicates whether the connection is made through an inverter (default: `true`).

# Outputs
- `can_connect::Bool`: Indicates whether the PV project can be connected to the network.
- `results::SortedDict{String, Bool}`: Detailed results of the evaluation, including the status of each criterion.
"""

# Function to evaluate if a project meets all technical connection criteria
function evaluate_project_connection(
    folder_name_model::String,
    output_folder::String,
    project_name::String,
    project_capacity::Float64, 
    max_injection::Float64, 
    connection_node::String,
    power_factor::Float64,
    connection_with_inverter::Bool=true
)
    # Initialize the results dictionary
    results = Dict{String, Bool}()
    can_connect = true

    # Create the OpenDSS model
    output_filename = "master.txt"
     (folder_name_model, output_folder, output_filename)

    # Compile the OpenDSS model
    master_file_path = joinpath(output_folder, output_filename)
    compile_opendss_model(master_file_path)

    # Add the feeder meter
    add_feeder_meter()

    # Create the graph
    graph, network, root = create_network_graph();
    graph, network = generate_rooted_tree(graph, network, root);


    # =======================
    # 1) EXPEDITED PROCESS CRITERIA
    # =======================

    # 1.1) Inverter-based connection
    function criterion_inverter_based(connection_with_inverter)
        return connection_with_inverter
    end
    results["1.1) Conexión mediante inversor"] = criterion_inverter_based(connection_with_inverter)

    # 1.2) Injection limit criterion
    function criterion_injection_limit(connection_node, max_injection)
        if occursin(r"(?i)BT", connection_node)  # Low Voltage node
            return max_injection <= 10
        elseif occursin(r"(?i)MT", connection_node)  # Medium Voltage node
            return max_injection <= 30
        else
            return false  # Unknown node
        end
    end
    results["1.2) Límite de inyección"] = criterion_injection_limit(connection_node, max_injection)

    # 1.3) Transformer capacity criterion
    function criterion_transformer_capacity(graph, network, connection_node, project_capacity)
        # Get the transformer connected to the connection node
        transformer_name = get_transformer_for_node(graph, network, connection_node);
        println("Transformer: ", transformer_name)
        # Get the subnetwork and subgraph for the transformer
        subgraph, subnetwork = get_subgraph_from_transformer(graph, network, transformer_name);
        # Get the PV systems connected to the subnetwork
        pv_dict = subnetwork.pvsy_to_index
        # Calculate the total PV capacity connected to the transformer plus the project capacity
        pv_capacity = total_pv_capacity(pv_dict) + project_capacity
        # Get the transformer capacity
        OpenDSSDirect.Transformers.Name(transformer_name)
        trfo_capacity = OpenDSSDirect.Transformers.kVA()
        # Check if the total PV capacity is less than 20% or 15% of the transformer capacity
        if occursin(r"(?i)BT", connection_node)  # Low Voltage node
            return 100*pv_capacity/trfo_capacity <= 20
        elseif occursin(r"(?i)MT", connection_node)  # Medium Voltage node
            return 100*pv_capacity/trfo_capacity <= 15
        else
            return false  # Unknown node
        end
    end
    results["1.3) Capacidad del Transformador"] = criterion_transformer_capacity(graph, network, connection_node, project_capacity)


    # =======================
    # 2) IEP AND CIP DETERMINATION
    # =======================

    # 2.1) Permissible Excess Injection (IEP)
    function criterion_ie_current_impact()
        # Simplified example: Replace with real current impact logic
        return true
    end
    results["2.1.1) Impacto en corriente"] = criterion_ie_current_impact()

    function criterion_ie_voltage_impact()
        # Simplified example: Replace with real voltage impact logic
        return true
    end
    results["2.1.2) Impacto en tensión"] = criterion_ie_voltage_impact()

    # 2.2) Permissible Installed Capacity (CIP)
    function criterion_cip_voltage_fluctuation()
        # Simplified example: Replace with real voltage fluctuation logic
        return true
    end
    results["2.2.1) Fluctuación de tensión"] = criterion_cip_voltage_fluctuation()

    function criterion_cip_short_circuit_current()
        # Simplified example: Replace with real short-circuit current logic
        return true
    end
    results["2.2.2) Corriente de corto circuito"] = criterion_cip_short_circuit_current()

    # =======================
    # 3) CONNECTION STUDIES
    # =======================

    # 3.1) Power flow study
    function criterion_power_flow_study()
        # Simplified example: Replace with real power flow analysis logic
        return true
    end
    results["3.1) Flujo de potencia"] = criterion_power_flow_study()

    # =======================
    # FINAL RESULT
    # =======================

    # Verify if all criteria are passed
    for (_, passed) in results
        if !passed
            can_connect = false
            break
        end
    end

    results = SortedDict(results)

    return can_connect, results
end