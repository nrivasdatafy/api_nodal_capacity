## Include the main module
include(joinpath("..", "utils","Utils.jl"))
using .Utils

function api_compute_nodal_capacity(folder_name_model::String)
    
    ## Step 1) Check and create folders
    folder_path_model = joinpath(@__DIR__, "..",  "..", "inputs", folder_name_model)
    folder_path_outputs = joinpath(@__DIR__, "..",  "..", "outputs")
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

    # Call the function
    nodal_capacity = compute_nodal_capacity(folder_path_model, folder_path_outputs)

    # Print the result 
    result = [
        Dict("Node" => node_name, "Capacity" => round(capacity, digits=2))
        for (node_name, capacity) in nodal_capacity
    ]
    return JSON.json(result)
end