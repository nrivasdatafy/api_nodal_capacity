"""
Checks if the model folder exists and ensures the output folder exists.
If the output folder already exists, it deletes it and then recreates it.

# Arguments
- `model_folder_path::String`: Path to the model folder.
- `output_folder_path::String`: Path to the output folder. By default, it is defined as `joinpath(@__DIR__, "..", "outputs")`.

# Returns
- `Bool`: `true` if the model folder exists and the output folder was successfully ensured; `false` otherwise.
"""
function check_and_create_folders(model_folder_path::String, output_folder_path::String=joinpath(@__DIR__, "..", "outputs"))
    if !isdir(model_folder_path)
        println("❌ Error: The folder $model_folder_path does not exist.")
        return false
    end
    println("The folder $model_folder_path exists.")
    
    # If the output folder exists, delete it before recreating it.
    if isdir(output_folder_path)
        println("Output folder $output_folder_path already exists. Deleting it...")
        try
            rm(output_folder_path; recursive=true)
            println("Output folder deleted successfully.")
        catch e
            println("Error: Failed to delete the output folder. Error details: ", e)
            return false
        end
    end
    
    println("Creating output folder at $output_folder_path...")
    try
        mkpath(output_folder_path)
        println("Output folder created successfully.")
    catch e
        println("Error: Failed to create the output folder. Error details: ", e)
        return false
    end
    return true
end
