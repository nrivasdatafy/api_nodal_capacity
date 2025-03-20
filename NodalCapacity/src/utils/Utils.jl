module Utils

# Import required packages
using OpenDSSDirect
using Graphs
using GraphPlot
using Plots
using Colors
using Compose
using NetworkLayout
using DataStructures
#using DataFrames
#using PrettyTables

# Include the files from the src folder
include(joinpath(@__DIR__, "validate_model_files.jl"))
include(joinpath(@__DIR__, "create_opendss_model.jl"))
include(joinpath(@__DIR__, "compile_opendss_model.jl"))
include(joinpath(@__DIR__, "add_feeder_meter.jl"))
include(joinpath(@__DIR__, "run_simulation.jl"))
include(joinpath(@__DIR__, "check_isolated_elements.jl"))
include(joinpath(@__DIR__, "get_network_infrastructure.jl"))
include(joinpath(@__DIR__, "get_general_simulation_results.jl"))
include(joinpath(@__DIR__, "plot_network_map.jl"))
include(joinpath(@__DIR__, "plot_voltage_profile.jl"))
include(joinpath(@__DIR__, "create_small_network_model.jl"))
include(joinpath(@__DIR__, "create_network_graph.jl"))
include(joinpath(@__DIR__, "generate_rooted_tree.jl"))
include(joinpath(@__DIR__, "plot_network_graph.jl"))
include(joinpath(@__DIR__, "get_transformer_for_load.jl"))
include(joinpath(@__DIR__, "get_transformer_for_node.jl"))
include(joinpath(@__DIR__, "get_subgraph_from_transformer.jl"))
include(joinpath(@__DIR__, "count_loads_under_transformers.jl"))
include(joinpath(@__DIR__, "evaluate_project_connection.jl"))
include(joinpath(@__DIR__, "total_pv_capacity.jl"))
include(joinpath(@__DIR__, "find_load_transformer.jl"))
include(joinpath(@__DIR__, "get_hosting_capacity.jl"))
include(joinpath(@__DIR__, "compute_nodal_capacity.jl"))
include(joinpath(@__DIR__, "plot_capacity_map.jl"))
include(joinpath(@__DIR__, "plot_voltage_heatmap.jl"))
include(joinpath(@__DIR__, "check_loops_in_network.jl"))
include(joinpath(@__DIR__, "create_mt_model.jl"))
include(joinpath(@__DIR__, "check_and_create_folders.jl"))
include(joinpath(@__DIR__, "get_transformer_nominal_capacities.jl"))
include(joinpath(@__DIR__, "compute_all_transformers_dmin.jl"))

# Export the functions for use outside the module
export  validate_model_files,
        create_opendss_model,
        compile_opendss_model,
        add_feeder_meter,
        run_simulation,
        check_isolated_elements,
        get_network_infrastructure,
        get_general_simulation_results,
        plot_network_map,
        plot_voltage_profile,
        create_small_network_model,
        create_network_graph,
        generate_rooted_tree,
        plot_network_graph,
        get_transformer_for_load,
        get_transformer_for_node,
        get_subgraph_from_transformer,
        count_loads_under_transformers,
        evaluate_project_connection,
        total_pv_capacity,
        find_load_transformer,
        get_hosting_capacity,
        compute_nodal_capacity,
        plot_capacity_map,
        plot_voltage_heatmap,
        check_loops_in_network,
        create_mt_model,
        check_and_create_folders,
        get_transformer_nominal_capacities,
        compute_all_transformers_dmin
end