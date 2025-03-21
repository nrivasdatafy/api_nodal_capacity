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

## ---------------------------------------------------
## Compute minimum demand for transformers
## ---------------------------------------------------

# Read feeder minimum demands from FeedData.txt
feed_data_path = joinpath(folder_path_model, "FeederData.txt")
feed_data = Dict{String, Float64}()

# Parse the FeedData.txt file
open(feed_data_path, "r") do file
    for line in eachline(file)
        key, value = split(line, "=")
        feed_data[key] = parse(Float64, value)
    end
end

# Extract feeder minimum demands
feeder_dmin_day = feed_data["feeder_dmin_day"]
feeder_dmin_night = feed_data["feeder_dmin_night"]

# Compute the prorated minimum demand for each transformer using OpenDSS.Direct data for capacities
println("\nComputing prorated minimum demand for each transformer...")
transformer_dmin = compute_all_transformers_dmin(feeder_dmin_day, feeder_dmin_night)
println("Transformers minimum demand (day, night):")
for (trf, (dmin_day, dmin_night)) in transformer_dmin
    println("$trf -> Day: $dmin_day kW, Night: $dmin_night kW")
end

## ---------------------------------------------------
## Network Graph fucntions
## ---------------------------------------------------

# Create the graph and generate the rooted tree
println("\nCreating network graph...")
graph, network, root = create_network_graph()
graph, network = generate_rooted_tree(graph, network, root)

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
node_name = "bt_09"  # Example node name for ID 001.
println("\n⏳ Searching the upstream transformer for node $node_name")
transformer_name = get_transformer_for_node(graph, network, node_name)
println("✅  The upstream transformer is: $transformer_name")

# Get short-circuit level at a specific node
node_name = "bt_09"
println("\n⏳ Calculating short-circuit level...")
sc_level = get_node_short_circuit_level(node_name)
println("✅ Short-circuit level at Bus1: ", sc_level, " kVA")

# Get hosting capacity
println("\n⏳ Calculating hosting capacity...")
node_name = "bt_09"  # Example load name for ID
println("Calculating hosting capacity for node $node_name")
hosting_capacity = get_hosting_capacity(graph, network, node_name)
println("Hosting capacity: $hosting_capacity kVA")

# Compute the nodal capacity
nodal_capacity = compute_nodal_capacity(folder_path_model, folder_path_outputs);

# Plot the capacity map
plt_cap = plot_capacity_map(folder_path_model, folder_path_outputs, "capacity_map.png", nodal_capacity);
