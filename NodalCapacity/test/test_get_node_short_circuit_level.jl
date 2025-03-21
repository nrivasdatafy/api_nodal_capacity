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
## Testing get_node_short_circuit_level and get_hosting_capacity functions
## ---------------------------------------------------

# Get short-circuit level at a specific node
node_name = "bt_09"
println("\n⏳ Calculating short-circuit level...")
sc_level = get_node_short_circuit_level(node_name)
println("✅ Short-circuit level at Bus1: ", sc_level, " kVA")
