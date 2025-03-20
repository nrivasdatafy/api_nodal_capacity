# Actualización de la estructura NetworkData para incluir load_to_phase
Base.@kwdef mutable struct NetworkData
    node_to_index::Dict{String, Int64}          # Mapping of node names to graph indices
    line_to_index::Dict{String, Int64}          # Mapping of line names to graph indices
    trfo_to_index::Dict{String, Int64}          # Mapping of transformer names to graph indices
    load_to_index::Dict{String, Int64}          # Mapping of load names to graph indices
    pvsy_to_index::Dict{String, Int64}          # Mapping of PV systems to graph indices
    line_to_nodes_idx::Dict{String, Tuple{Int64, Int64}} # Mapping of lines to (source, target)
    trfo_to_nodes_idx::Dict{String, Tuple{Int64, Int64}} # Mapping of transformers to (source, target)
    load_to_nodes_idx::Dict{String, Tuple{Int64, Int64}} # Mapping of loads to (source, fictitious node)
    pvsy_to_nodes_idx::Dict{String, Tuple{Int64, Int64}} # Mapping of PV systems to (source, fictitious node)
    load_to_phase::Dict{String, String}         # Mapping of load id to its phase ("1", "2", or "3")
end

"""
Generate an undirected network graph from an OpenDSS model.

# Returns
- `SimpleGraph{Int64}`: The generated undirected network graph.
- `NetworkData`: A structure containing mappings of network components (including load_to_phase).
- `Root node`: The root node of the network graph.
"""
function create_network_graph()
    # Initialize the graph and supporting structures
    graph = SimpleGraph()

    node_to_index = Dict{String, Int64}()
    
    line_to_index = Dict{String, Int64}()
    trfo_to_index = Dict{String, Int64}()
    load_to_index = Dict{String, Int64}()
    pvsy_to_index = Dict{String, Int64}()
    
    line_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    trfo_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    load_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    pvsy_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    
    # Nuevo diccionario para mapear la fase de cada carga
    load_to_phase = Dict{String, String}()

    current_index = 1
    root_node = nothing  # To store the Bus1 of the first transformer

    # Helper function to get or create node indices
    function get_or_create_node(node_name::String)
        if !haskey(node_to_index, node_name)
            add_vertex!(graph)
            node_to_index[node_name] = current_index
            current_index += 1
        end
        return node_to_index[node_name]
    end

    # Process transformers (ensure the first transformer Bus1 as the root)
    transformer_idx = OpenDSSDirect.Transformers.First()
    while transformer_idx > 0
        trfo_name = OpenDSSDirect.Transformers.Name()
        buses = OpenDSSDirect.CktElement.BusNames()

        if length(buses) >= 2
            bus1 = replace(buses[1], r"\..*" => "")
            bus2 = replace(buses[2], r"\..*" => "")
            
            source_idx = get_or_create_node(bus1)
            target_idx = get_or_create_node(bus2)

            if root_node === nothing  # Set root node only for the first transformer
                root_node = source_idx
            end

            add_edge!(graph, source_idx, target_idx)
            trfo_to_index[trfo_name] = length(edges(graph))
            trfo_to_nodes_idx[trfo_name] = (source_idx, target_idx)
        end

        transformer_idx = OpenDSSDirect.Transformers.Next()
    end

    # Process lines
    line_idx = OpenDSSDirect.Lines.First()
    while line_idx > 0
        line_name = OpenDSSDirect.Lines.Name()
        bus1 = replace(OpenDSSDirect.Lines.Bus1(), r"\..*" => "")
        bus2 = replace(OpenDSSDirect.Lines.Bus2(), r"\..*" => "")
        
        source_idx = get_or_create_node(bus1)
        target_idx = get_or_create_node(bus2)

        add_edge!(graph, source_idx, target_idx)
        line_to_index[line_name] = length(edges(graph))
        line_to_nodes_idx[line_name] = (source_idx, target_idx)

        line_idx = OpenDSSDirect.Lines.Next()
    end

    # Process loads as fictitious edges
    load_idx = OpenDSSDirect.Loads.First()
    while load_idx > 0
        load_name = OpenDSSDirect.Loads.Name()
        bus = replace(OpenDSSDirect.CktElement.BusNames()[1], r"\..*" => "")
        
        source_idx = get_or_create_node(bus)
        fictitious_node_name = "e_" * load_name
        target_idx = get_or_create_node(fictitious_node_name)

        add_edge!(graph, source_idx, target_idx)
        load_to_index[load_name] = target_idx
        load_to_nodes_idx[load_name] = (source_idx, target_idx)
        
        # Obtain the load phase using OpenDSSDirect (e.g., OpenDSSDirect.Loads.Phases())
        # Convert the result to a string; assuming Loads.Phases() returns an integer or similar.
        load_phase = string(OpenDSSDirect.Loads.Phases())
        load_to_phase[load_name] = load_phase

        load_idx = OpenDSSDirect.Loads.Next()
    end

    # Process PV systems as fictitious edges
    pvsy_idx = OpenDSSDirect.PVsystems.First()
    while pvsy_idx > 0
        pvsy_name = OpenDSSDirect.PVsystems.Name()
        bus = replace(OpenDSSDirect.CktElement.BusNames()[1], r"\..*" => "")
        
        source_idx = get_or_create_node(bus)
        fictitious_node_name = "e_" * pvsy_name
        target_idx = get_or_create_node(fictitious_node_name)

        add_edge!(graph, source_idx, target_idx)
        pvsy_to_index[pvsy_name] = target_idx
        pvsy_to_nodes_idx[pvsy_name] = (source_idx, target_idx)

        pvsy_idx = OpenDSSDirect.PVsystems.Next()
    end

    network = NetworkData(
            node_to_index=node_to_index,
            line_to_index=line_to_index,
            trfo_to_index=trfo_to_index,
            load_to_index=load_to_index,
            pvsy_to_index=pvsy_to_index,
            line_to_nodes_idx=line_to_nodes_idx,
            trfo_to_nodes_idx=trfo_to_nodes_idx,
            load_to_nodes_idx=load_to_nodes_idx,
            pvsy_to_nodes_idx=pvsy_to_nodes_idx,
            load_to_phase=load_to_phase
        )

    # Return the undirected graph, the network data structure, and the root node
    return graph, network, root_node
end
