"""
Count the number of loads under each secondary transformer in the system, differentiated by phase.
Only the loads under each transformer (excluding the primary transformer, e.g., "at_mt") are counted.
For each transformer, the function returns:
   - "load_count": Total number of loads.
   - "phase1", "phase2", "phase3": Number of loads in each phase.
Optionally, the results are printed in a table.

# Arguments:
- `graph::SimpleDiGraph{Int}`: The directed graph of the network.
- `network::NetworkData`: The network data containing node and edge mappings, including:
   - `trfo_to_nodes_idx`: Dict mapping transformer name to its nodes.
   - `load_to_nodes_idx`: Dict mapping load id to a tuple `(src, fictitious node)`.
   - `load_to_phase`: Dict mapping load id to its phase ("1", "2", or "3").
- `show_table::Bool`: Flag indicating whether to print the table (default is `true`).

# Returns:
- `Dict{String, Dict{String, Int}}`: A dictionary where each transformer is associated with a dictionary containing:
   - `"load_count"`: Total number of loads.
   - `"phase1"`, `"phase2"`, `"phase3"`: Number of loads in each phase.
"""
function count_loads_under_transformers(graph::SimpleDiGraph{Int}, network::NetworkData, show_table::Bool = true)
    println("\n⏳ Counting loads under each transformer...")

    # Obtain the list of transformer names from network.trfo_to_nodes_idx
    transformer_names = collect(keys(network.trfo_to_nodes_idx))
    if isempty(transformer_names)
        error("No transformers found in the network.")
    end

    # Exclude the primary transformer (e.g., named "at_mt")
    secondary_transformers = filter(trfo_name -> trfo_name != "at_mt", transformer_names)
    
    # Dictionary to store statistics for each transformer
    transformer_stats = Dict{String, Dict{String, Int}}()

    # For each secondary transformer, count loads and accumulate statistics by phase
    for trfo_name in secondary_transformers
        # Obtain the subgraph associated with the transformer
        subgraph, subnetwork = get_subgraph_from_transformer(graph, network, trfo_name)
        load_count = 0
        phase1 = 0
        phase2 = 0
        phase3 = 0
        
        # Iterate over each load in the subgraph
        for (load_id, (src, dst)) in subnetwork.load_to_nodes_idx
            if src in vertices(subgraph) && dst in vertices(subgraph)
                load_count += 1
                # Count loads per phase using the updated load_to_phase mapping
                phase = subnetwork.load_to_phase[load_id]
                if phase == "1"
                    phase1 += 1
                elseif phase == "2"
                    phase2 += 1
                elseif phase == "3"
                    phase3 += 1
                end
            end
        end
        
        transformer_stats[trfo_name] = Dict(
            "load_count" => load_count,
            "phase1" => phase1,
            "phase2" => phase2,
            "phase3" => phase3
        )
    end

    # Print the table if show_table is true
    if show_table
        # Use a DataFrame to ensure correct column structure
        
        df = DataFrame(
            Transformer = String[],
            Load_Count = Int[],
            Phase1 = Int[],
            Phase2 = Int[],
            Phase3 = Int[]
        )
        for (trfo, stats) in transformer_stats
            push!(df, (trfo, stats["load_count"], stats["phase1"], stats["phase2"], stats["phase3"]))
        end

        pretty_table(df)
    end

    return transformer_stats
end
