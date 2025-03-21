"""
Compiles a given OpenDSS model file (`master.txt`) using OpenDSSDirect.

# Arguments
- `folder_path_outputs::String`: The path to the folder containing the OpenDSS model file.
- `output_filename::String`: The name of the OpenDSS file to compile (e.g., `master.txt`).

# Returns
- `Bool`: Returns `true` if the compilation was successful, or `false` otherwise.
"""
function compile_opendss_model(folder_path_outputs::String)::Bool
    try
        # Define the default output filename
        output_filename = "master.txt"

        # Clear the current OpenDSS session
        OpenDSSDirect.Text.Command("clear")
            
        # Attempt to compile the provided file
        filename = joinpath(folder_path_outputs, output_filename)
        OpenDSSDirect.Text.Command("compile $filename")
        
        # Verify if the compilation was successful
        if OpenDSSDirect.Error.Description() == ""
            println("Compilation successful.")
        else
            println("Compilation failed: ", OpenDSSDirect.Error.Description())
            return false
        end

        # Add feeder meter
        add_feeder_meter()
        
        return true
    catch e
        # Handle any unexpected errors
        println("Error during compilation: ", e)
        return false
    end
end
