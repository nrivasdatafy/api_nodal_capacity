"""
Creates an OpenDSS model file (`master.txt`) based on the specified folder containing the model files.

# Arguments
- `folder_name_model::String`: Path to the folder containing the model files (e.g., Lines.txt, Transformers.txt, etc.).
- `output_folder::String`: Path to the folder where the OpenDSS file will be created.

# Returns
- `Bool`: Returns `true` if the file was successfully created, or `false` otherwise.
"""
function create_opendss_model(folder_name_model::String, output_folder::String)::Bool
    try
        # Define the default output filename
        output_filename = "master.txt"

        # Ensure the output folder exists
        if !isdir(output_folder)
            println("Creating output folder: $output_folder")
            mkdir(output_folder)
        end

        # Ensure the model folder exists
        if !isdir(folder_name_model)
            println("Model folder does not exist: $folder_name_model")
            return false
        end

        # Ensure the model files exist
        if !validate_model_files(folder_name_model)
            println("Model files are missing in $folder_name_model")
            return false
        end

        # Define the full path for the output file
        output_file_path = joinpath(output_folder, output_filename)

        # Open the file for writing
        io = open(output_file_path, "w")
        
        # Write new circuit creation commands
        println(io, "Clear")
        println(io, "Set DefaultBaseFrequency=50")
        
        ## Read feeder parameters from FeederData.txt
        feeder_data_file = joinpath(folder_name_model, "FeederData.txt")
        if isfile(feeder_data_file)
            feeder_lines = readlines(feeder_data_file)
            feeder_params = Dict{String, String}()
            for line in feeder_lines
                line = strip(line)
                # Ignore empty lines and comments
                if !isempty(line) && !startswith(line, "#")
                    parts = split(line, "=")
                    if length(parts) == 2
                        key = strip(parts[1])
                        value = strip(parts[2])
                        feeder_params[key] = value
                    end
                end
            end
            isc1 = get(feeder_params, "Isc1", "10e8")
            isc3 = get(feeder_params, "Isc3", "10e8")
        else
            println("FeederData.txt not found in $folder_name_model")
            isc1 = "10e8"
            isc3 = "10e8"
        end

        ## Define the circuit based on short circuit values (modeling an infinite bus)
        println(io, "New Circuit.Alimentador basekv=66 pu=1.0 angle=0 frequency=50 phases=3 Isc1=$(isc1) Isc3=$(isc3) enabled=true")

        # Add Power Delivery Elements: elements that transport power
        println(io, "Redirect $folder_name_model/Linecodes.txt")
        println(io, "Redirect $folder_name_model/Lines.txt")
        println(io, "Redirect $folder_name_model/Transformers.txt")

        # Add Loads
        println(io, "Redirect $folder_name_model/Loads.txt")
        
        # Add Distributed Energy Resources (DERs)
        println(io, "Redirect $folder_name_model/PVsystems.txt")
        # println(io, "Redirect $folder_name_model/Generators.txt")
        # println(io, "Redirect $folder_name_model/Storages.txt")
         
        # Define voltage bases for reports in per unit
        println(io, "Set voltagebases=[66, 23, 0.38, 0.22]")
        println(io, "calcvoltagebases")

        # Set maximum iterations
        println(io, "Set maxiterations=100")
        
        # Close the file
        close(io)

        # Return true to indicate success
        println("The file $output_filename was created successfully in $output_folder.")
        return true

    catch e
        # Handle any errors and return false to indicate failure
        println("Error creating $output_filename: ", e)
        return false
    end
end
