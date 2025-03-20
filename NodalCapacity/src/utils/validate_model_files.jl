"""
Validates that all necessary model files exist in the specified folder.

# Arguments
- `folder_name_model::String`: Path to the folder containing the model files.

# Returns
- `Bool`: Returns `true` if all files exist, or `false` if any file is missing.
"""
function validate_model_files(folder_name_model::String)::Bool
    # List of minimum required files (add to the list other files as they needed)
    required_files = ["FeederData.txt", "Lines.txt", "Transformers.txt", "Loads.txt", "Linecodes.txt", "PVsystems.txt"]

    # Check if each file exists
    for file in required_files
        if !isfile(joinpath(folder_name_model, file))
            println("Error: Missing file $file in $folder_name_model")
            return false
        end
    end

    println("All model files exist in $folder_name_model")

    # Return true if all files exist
    return true
end
