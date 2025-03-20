"""
Checks if the active OpenDSS circuit has loops and prints the looped branches.

# Returns
- `Bool`: A tuple containing:
    - `Bool`: True if the function ran successfully, false otherwise.
"""
function check_loops_in_network()::Bool
    try
        # Reset the topology pointer (optional but good practice)
        element = OpenDSSDirect.Topology.First()
        while element != 0
            element = OpenDSSDirect.Topology.Next()
        end

        # Get the number of loops
        num_loops = OpenDSSDirect.Topology.NumLoops()
        if num_loops == 0
            println("No loops detected in the circuit.")
            return true
        else
            println("Detected $num_loops loop(s) in the circuit.")
            looped_branches = String[]

            # Retrieve each looped branch
            for i in 1:num_loops
                branch_index = OpenDSSDirect.Topology.LoopedBranch()
                if branch_index == 0
                    # If we get 0, it means no more looped branches are found
                    break
                else
                    # Now that the pointer is set to the looped branch, 
                    # we can get its name from the active element.
                    branch_name = OpenDSSDirect.CktElement.Name()
                    push!(looped_branches, branch_name)
                end
            end

            if !isempty(looped_branches)
                println("Looped branch(es): ", join(looped_branches, ", "))
            else
                println("No looped branch names retrieved (index returned 0).")
            end

            return true
        end
    catch e
        println("Error checking loops in network: ", e)
        return false
    end
end
