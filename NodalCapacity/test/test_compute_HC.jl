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

# 6) Compute the hosting capacity for all nodes
nodal_capacity = compute_nodal_capacity(folder_path_model, folder_path_outputs)
println("✅ Nodal hosting capacity computed successfully.")
println(nodal_capacity)

# 7) Plot the results
plot_capacity_map(folder_path_model, folder_path_outputs, "NodalCapacityPlot.html", nodal_capacity)
println("✅ Nodal hosting capacity plot generated successfully.")