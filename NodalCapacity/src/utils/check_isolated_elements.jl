"""
Checks for isolated branches and loads in the compiled OpenDSS model.

# Returns
    - `Bool`: True if the function ran successfully, false otherwise.
"""
function check_isolated_elements()::Bool
    try
        # Get the number of isolated branches
        number_isolated_branches = OpenDSSDirect.Topology.NumIsolatedBranches()
        
        # Get the number of isolated loads
        number_isolated_loads = OpenDSSDirect.Topology.NumIsolatedLoads()
        
        # Display results
        if number_isolated_branches > 0
            println("The circuit has isolated branches. Number of isolated branches: $number_isolated_branches")
        else
            println("The circuit has no isolated branches. All branches are connected.")
        end

        if number_isolated_loads > 0
            println("The circuit has isolated loads. Number of isolated loads: $number_isolated_loads")
        else
            println("The circuit has no isolated loads. All loads are connected.")
        end

        return true
    catch e
        # Handle errors gracefully
        println("Error checking isolated elements: ", e)
        return false
    end
end
