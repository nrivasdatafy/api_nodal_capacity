# File: create_network_graph.jl

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
    load_to_phase::Dict{String, String}         # Mapping of load IDs to their phase ("1", "2", or "3")
    line_to_length::Dict{String, Float64}       # Mapping of line names to their lengths in meters
end

"""
Generate an undirected network graph from an OpenDSS model.

This function uses OpenDSSDirect functions to obtain model data. It processes transformers, lines, loads,
and PV systems (as fictitious edges) to build a network graph and populate a NetworkData object.

Returns a tuple:
  - graph::SimpleGraph{Int64}: The generated undirected network graph.
  - network::NetworkData: A structure containing mappings of network components.
"""
function create_network_graph()
    
    # Initialize an empty undirected graph
    graph = SimpleGraph()

    # Initialize the mapping dictionaries
    node_to_index = Dict{String, Int64}()
    line_to_index = Dict{String, Int64}()
    trfo_to_index = Dict{String, Int64}()
    load_to_index = Dict{String, Int64}()
    pvsy_to_index = Dict{String, Int64}()

    line_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    trfo_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    load_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()
    pvsy_to_nodes_idx = Dict{String, Tuple{Int64, Int64}}()

    load_to_phase = Dict{String, String}()
    line_to_length = Dict{String, Float64}()

    # Internal dictionary for bus coordinates (used only for potential distance calculations)
    # Not returned as output.
    bus_coords = Dict{String, Tuple{Float64,Float64}}()

    # Use a Ref to hold current index (to assign node indices)
    current_index = Ref(1)
    root_node = nothing  # To store the Bus1 of the first transformer

    # Helper function to get or create a node index from a bus name.
    function get_or_create_node(node_name::AbstractString)
        node_name = string(node_name)
        if !haskey(node_to_index, node_name)
            add_vertex!(graph)
            node_to_index[node_name] = current_index[]
            current_index[] += 1
        end
        return node_to_index[node_name]
    end

    # Process transformers using OpenDSSDirect functions.
    transformer_idx = OpenDSSDirect.Transformers.First()
    while transformer_idx > 0
        trfo_name = OpenDSSDirect.Transformers.Name()
        buses = OpenDSSDirect.CktElement.BusNames()
        if length(buses) >= 2
            # Remove any phase suffixes (e.g. ".1")
            bus1 = replace(buses[1], r"\..*" => "")
            bus2 = replace(buses[2], r"\..*" => "")
            source_idx = get_or_create_node(bus1)
            target_idx = get_or_create_node(bus2)
            if root_node === nothing
                root_node = source_idx
            end
            add_edge!(graph, source_idx, target_idx)
            trfo_to_index[trfo_name] = length(edges(graph))
            trfo_to_nodes_idx[trfo_name] = (source_idx, target_idx)
            # Optionally, store bus coordinates from OpenDSSDirect if available.
            # For example: bus_coords[lowercase(bus1)] = (x_value, y_value)
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
        # Retrieve line length from OpenDSSDirect (assumed to be in km, convert to meters)
        length_val = OpenDSSDirect.Lines.Length()  # This should return the length in meters or km (adjust accordingly)
        # If the length is given in km, multiply by 1000.0; here we assume it's in meters:
        line_to_length[line_name] = length_val
        line_idx = OpenDSSDirect.Lines.Next()
    end

    # Process loads as fictitious edges
    load_idx = OpenDSSDirect.Loads.First()
    while load_idx > 0
        load_name = OpenDSSDirect.Loads.Name()
        bus_full = OpenDSSDirect.CktElement.BusNames()[1]
        base_bus = split(bus_full, ".")[1]
        source_idx = get_or_create_node(base_bus)
        fictitious_node_name = "e_" * load_name
        target_idx = get_or_create_node(fictitious_node_name)
        add_edge!(graph, source_idx, target_idx)
        load_to_index[load_name] = target_idx
        load_to_nodes_idx[load_name] = (source_idx, target_idx)
        parts = split(bus_full, ".")
        load_to_phase[load_name] = length(parts) > 1 ? parts[2] : "1"
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
        node_to_index = node_to_index,
        line_to_index = line_to_index,
        trfo_to_index = trfo_to_index,
        load_to_index = load_to_index,
        pvsy_to_index = pvsy_to_index,
        line_to_nodes_idx = line_to_nodes_idx,
        trfo_to_nodes_idx = trfo_to_nodes_idx,
        load_to_nodes_idx = load_to_nodes_idx,
        pvsy_to_nodes_idx = pvsy_to_nodes_idx,
        load_to_phase = load_to_phase,
        line_to_length = line_to_length
    )

    graph, network = generate_rooted_tree(graph, network, root_node);

    return graph, network
end
