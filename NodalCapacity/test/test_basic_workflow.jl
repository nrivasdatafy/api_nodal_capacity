## ---------------------------------------------------
## Include the main module
## ---------------------------------------------------
include(joinpath("..", "src","utils", "Utils.jl"))
using .Utils

## ---------------------------------------------------
## Basic workflow
## ---------------------------------------------------

## Step 1) Check and create folders
folder_path_model = joinpath(@__DIR__, "..", "inputs", "001")
folder_path_outputs = joinpath(@__DIR__, "..", "outputs")
println("\n⏳ Checking and creating folders...")
if check_and_create_folders(folder_path_model, folder_path_outputs)
    println("✅ Folders checked and created successfully.")
else
    println("❌ Error: Failed to check and create folders.")
end

## Step 2) Create opendss model
println("\n⏳ Creating opendss model...")
if create_opendss_model(folder_path_model, folder_path_outputs)
    println("✅ OpenDSS model created successfully.")
else
    println("❌ Error: Failed to create the OpenDSS model.")
end

## Step 3) Compile the OpenDSS Model
println("\n⏳ Compiling the OpenDSS model...")
if compile_opendss_model(folder_path_outputs)
    println("✅ OpenDSS model compiled successfully.")
else
    println("❌ Error: Failed to compile the OpenDSS model.")
end

## Step 4) Run the simulation
println("\n⏳ Running simulation...")
if run_simulation()
    println("✅ Simulation ran successfully.")
else
    println("❌ Error: Failed to run the simulation.")
end

## ---------------------------------------------------
## Check the network
## ---------------------------------------------------

## Check for isolated elements
println("\n⏳ Checking isolated elements...")
if check_isolated_elements()
    println("✅ Isolated elements checked successfully.")
else
    println("❌ Error: Failed to check isolated elements.")
end

## Check for loops in the network
println("\n⏳ Checking loops in the network...")  
if check_loops_in_network()
    println("✅ Loops checked successfully.")
else
    println("❌ Error: Failed to check loops.")
end

## ---------------------------------------------------
## Get Results
## ---------------------------------------------------

## Get Network Infrastructure
println("\n⏳ Get Network Infrastructure...")
network_description = get_network_infrastructure()
println("✅ Network infrastructure retrieved successfully.")

## Get General Simulation Results
println("\n⏳ General Simulation Results...")
general_results = get_general_simulation_results()
println("✅ General simulation results retrieved successfully.")

## ---------------------------------------------------
## Plotting
## ---------------------------------------------------

## Plot network map
println("\n⏳ Plotting network map...")
try
    plot_network_map(
        folder_path_model, 
        folder_path_outputs, 
        "network_map.html")
    println("✅ Network map plot generated successfully.")
catch e
    println("❌ Error: ",e)
end

## Plot voltage heatmap
println("\n⏳ Plotting voltage heatmap...")
try
    plot_voltage_heatmap(
        folder_path_model,
        folder_path_outputs, 
        "voltage_heatmap.html")
    println("✅ Voltage heatmap plot generated successfully.")
catch e
    println("❌ Error: ",e)
end

## Plot voltage profile
println("\n⏳ Plotting voltage profile...")
try
    plot_voltage_profile(
        folder_path_outputs, 
        "voltage_profile.html")
    println("✅ Voltage profile plot generated successfully.")
catch e
    println("❌ Error: ",e)
end


