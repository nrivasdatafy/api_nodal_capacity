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


# Step 1: Create the network graph using OpenDSSDirect-based functions
graph, network = create_network_graph()
println("✅ Network graph created successfully.")

# Step 2: Extract a subgraph from a given transformer (adjust the transformer name as needed)
transformer_name = "MT_BT3"  # Example transformer name
sub_graph, sub_network = get_subgraph_from_transformer(graph, network, transformer_name)
println("✅ Subgraph extracted for transformer $transformer_name.")

# Step 3: Call find_deepest_node on the subgraph
farthest_node, farthest_bus, total_distance = find_deepest_node(sub_graph, sub_network, network)
println("\nDeepest node in the subgraph from $transformer_name:")
println("  Node index (in subtree): $farthest_node")
println("  Bus name: $farthest_bus")
println("  Distance from root: $total_distance meters")