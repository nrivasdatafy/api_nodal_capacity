"""
Runs the simulation on the currently loaded OpenDSS model.

# Returns
- `Bool`: Returns `true` if the simulation was successful (no errors), or `false` otherwise.
"""
function run_simulation()::Bool
    try
        # Solve the OpenDSS model
        OpenDSSDirect.Solution.Solve()

        # Check for errors after solving
        error_description = OpenDSSDirect.Error.Description()
        if error_description == ""
            println("Simulation completed successfully.")
            return true
        else
            println("Simulation failed with error: $error_description")
            return false
        end
    catch e
        # Handle unexpected errors
        println("Error during simulation: ", e)
        return false
    end
end
