"""
Find the transformer upstream of a given load in the network model.

# Inputs
- `folder_name_model::String`: Path to the folder containing the OpenDSS model of the network.
- `load_name::String`: The name of the load to search for.

# Returns
- `String`: The name of the upstream transformer for the specified load.
"""
function find_load_transformer(folder_name_model::String, load_name::String)
    # Load and compile the OpenDSS model
    output_folder = joinpath(folder_name_model, "outputs")
    output_filename = "master.txt"
    create_opendss_model(folder_name_model, output_folder, output_filename)
    compile_opendss_model(joinpath(output_folder, output_filename))
    add_feeder_meter()

    # Generate the network graph and rooted tree
    graph, network, root_node = create_network_graph()
    rooted_tree, rooted_network = generate_rooted_tree(graph, network, root_node)

    # Find the transformer upstream of the specified load
    transformer_name = get_transformer_for_load(rooted_tree, rooted_network, load_name)

    return transformer_name
end
