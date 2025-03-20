"""
Adds an energy meter at the feeder head (first transformer in the model).

# Returns
- `Bool`: Returns `true` if the meter was added successfully, or `false` otherwise.
"""
function add_feeder_meter()::Bool
    try
        # Get the first transformer
        first_trf = OpenDSSDirect.Transformers.First()
        if first_trf == 0
            println("Error: No transformers found in the model.")
            return false
        end

        # Get the transformer name (Assuming that the first transformer is the feeder head)
        tfr_name = OpenDSSDirect.Transformers.Name()

        # Add the energy meter
        OpenDSSDirect.Text.Command("New energymeter.meter element=Transformer.$tfr_name terminal=1")
        println("Energy meter added at feeder head (Transformer: $tfr_name).")
        return true
    catch e
        # Handle errors gracefully
        println("Error adding feeder meter: ", e)
        return false
    end
end
