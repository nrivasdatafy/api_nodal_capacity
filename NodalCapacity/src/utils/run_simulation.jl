"""
Runs the simulation on the currently loaded OpenDSS model.

# Arguments
- `SolveMode::Int`: The solve mode to be used during the simulation. Default is `0`. Possible values are:
    - `0`: SnapShot
    - `1`: Daily
    - `2`: Yearly
    - `3`: Monte1
    - `4`: LD1
    - `5`: PeakDay
    - `6`: DutyCycle
    - `7`: Direct
    - `8`: MonteFault
    - `9`: FaultStudy
    - `10`: Monte2
    - `11`: Monte3
    - `12`: LD2
    - `13`: AutoAdd
    - `14`: Dynamic
    - `15`: Harmonic

# Returns
- `Bool`: Returns `true` if the simulation was successful (no errors), or `false` otherwise.
"""
function run_simulation(SolveMode::Int = 0)::Bool
    try
       
        # Code to verify that SolveMode is within the valid range
        if SolveMode < 0 || SolveMode > 15
            println("Invalid SolveMode: $SolveMode. Must be between 0 and 15.")
        return false
        end
        
        # Set the SolveMode
        OpenDSSDirect.Solution.Mode(SolveMode)

        # Print the current SolveMode
        println("SolveMode: ", OpenDSSDirect.Solution.Mode())

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