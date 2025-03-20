"""
Count the number of loads under each secondary transformer in the system, along with additional stats, and optionally print the results in a table.

# Arguments:
- `graph::SimpleDiGraph{Int}`: The directed graph of the network.
- `network::NetworkData`: The network data containing node and edge mappings, and additional fields:
   - `trfo_to_nodes_idx`: Dict mapping transformer name to its nodes.
   - `trfo_nominal_power`: Dict mapping transformer name to its nominal power (e.g., in kVA).
   - `load_to_nodes_idx`: Dict mapping load id to a tuple `(src, dst)`.
   - `load_to_phase`: Dict mapping load id to its phase ("1", "2", or "3").
- `show_table::Bool`: Flag para indicar si se debe imprimir la tabla (por defecto es `true`).

# Returns:
- `Dict{String, Dict{String, Any}}`: Un diccionario donde cada transformador se asocia a otro diccionario con:
   - `"load_count"`: Número total de cargas.
   - `"nominal_power"`: Potencia nominal del transformador.
   - `"total_consumption"`: Consumo total (1 kW por carga).
   - `"phase1"`, `"phase2"`, `"phase3"`: Número de cargas en cada fase.
"""
function count_loads_under_transformers(graph::SimpleDiGraph{Int}, network::NetworkData, show_table::Bool = true)
    # Obtener la lista de transformadores
    transformer_names = collect(keys(network.trfo_to_nodes_idx))
    if isempty(transformer_names)
        error("No se encontraron transformadores en la red.")
    end

    # Excluir el transformador primario y el denominado "at_mt"
    secondary_transformers = filter(trfo_name -> trfo_name != "at_mt", transformer_names)
    
    # Diccionario para almacenar las estadísticas por transformador
    transformer_stats = Dict{String, Dict{String, Any}}()

    # Para cada transformador secundario, contar cargas y acumular estadísticas
    for trfo_name in secondary_transformers
        # Obtener el subgrafo asociado al transformador
        subgraph, subnetwork = get_subgraph_from_transformer(graph, network, trfo_name)
        load_count = 0
        phase1 = 0
        phase2 = 0
        phase3 = 0
        
        # Iterar sobre cada carga en el subgrafo
        for (load_id, (src, dst)) in subnetwork.load_to_nodes_idx
            if src in vertices(subgraph) && dst in vertices(subgraph)
                load_count += 1
                # Contabilizar cargas por fase usando network.load_to_phase
                phase = network.load_to_phase[load_id]
                if phase == "1"
                    phase1 += 1
                elseif phase == "2"
                    phase2 += 1
                elseif phase == "3"
                    phase3 += 1
                end
            end
        end
        
        # Obtener la potencia nominal del transformador (se asume que está en network.trfo_nominal_power)
        nominal_power = network.trfo_nominal_power[trfo_name]
        # Calcular el consumo total: 1 kW por carga
        total_consumption = load_count * 1  # en kW

        # Guardar los resultados en el diccionario
        transformer_stats[trfo_name] = Dict(
            "load_count"        => load_count,
            "nominal_power"     => nominal_power,
            "total_consumption" => total_consumption,
            "phase1"            => phase1,
            "phase2"            => phase2,
            "phase3"            => phase3
        )
    end

    # Imprimir la tabla si show_table es verdadero
    if show_table
        header = ["Transformer", "Load Count", "Nominal Power (kVA)", "Total Consumption (kW)", "Phase 1", "Phase 2", "Phase 3"]
        data = Any[]
        for (trfo, stats) in transformer_stats
            push!(data, [trfo,
                         stats["load_count"],
                         stats["nominal_power"],
                         stats["total_consumption"],
                         stats["phase1"],
                         stats["phase2"],
                         stats["phase3"]])
        end

        pretty_table(data, header)
    end

    return transformer_stats
end
