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

# 6) Run the simulation
println("\n⏳ Running simulation...")
if run_simulation(9)
    println("✅ Simulation ran successfully.")
else
    println("❌ Error: Failed to run the simulation.")
end

# 7) create the network graph
graph, network = create_network_graph()
println("✅ Network graph created successfully.")

# 8) Compute the hosting capacity for one node
node_name = "bt_09"  # Example load name for ID
println("\n⏳ Calculating hosting capacity for node $node_name")
hosting_capacity = get_hosting_capacity(graph, network, node_name, folder_path_model)
println("✅ Hosting capacity: $hosting_capacity kVA")