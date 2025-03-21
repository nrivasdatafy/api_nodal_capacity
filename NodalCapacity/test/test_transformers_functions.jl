# 1) Include and use your main module (Utils)
include(joinpath("..", "src", "utils", "Utils.jl"))
using .Utils

# 2) Define input/output paths
folder_path_model   = joinpath(@__DIR__, "..", "inputs", "001")
folder_path_outputs = joinpath(@__DIR__, "..", "outputs")

# 3) Check and create folders
if check_and_create_folders(folder_path_model, folder_path_outputs)
    println("✅ Folders checked/created.")
else
    error("❌ Failed to check/create folders.")
end

# 4) Create the OpenDSS model
if create_opendss_model(folder_path_model, folder_path_outputs)
    println("✅ OpenDSS model created.")
else
    error("❌ Failed to create the OpenDSS model.")
end

# 5) Compile the OpenDSS model
if compile_opendss_model(folder_path_outputs)
    println("✅ OpenDSS model compiled.")
else
    error("❌ Failed to compile the OpenDSS model.")
end

## ---------------------------------------------------
## Testing Count loads, get transformer for load, and get transformer for node functions
## ---------------------------------------------------

# Create the network graph using OpenDSSDirect-based functions
graph, network = create_network_graph()
println("✅ Network graph created successfully.")

## Count loads under each transformer
println("\n⏳ Counting loads under each transformer...")
# Call the function, which prints the table if show_table is set to true
transformer_stats = count_loads_under_transformers(graph, network, true)
println("✅ Transformer load count computed and table printed successfully.")

# Find the upstream transformer for a given load
load_name = "Load_LV_05"  # Example load name for ID 001
println("\n⏳ Searching the upstream transformer for load $load_name")
transformer_name = get_transformer_for_load(graph, network, load_name)
println("✅  The upstream transformer is: $transformer_name")

# Find the upstream transformer for a specific node
node_name = "bt_07"  # Example node name for ID 001.
println("\n⏳ Searching the upstream transformer for node $node_name")
transformer_name = get_transformer_for_node(graph, network, node_name)
println("✅  The upstream transformer is: $transformer_name")