"""
Calculate the short-circuit level at a given node (bus) in the system using OpenDSSDirect.
Before performing the calculation, the function runs a simulation in fault mode (SolveMode=9).
The short-circuit level (in kVA) is computed as:
    S_sc (kVA) = sqrt(3) * V_base (kV) * I_sc (kA)
where I_sc is the magnitude of the short-circuit current obtained from OpenDSSDirect.Bus.Isc().

# Arguments
- `node::String`: The name of the bus (node) for which to calculate the short-circuit level.

# Returns
- `Float64`: The short-circuit level at the node in kVA.
"""
function get_node_short_circuit_level(node::String)::Float64
    # Run simulation in fault mode (SolveMode = 9)
    if !run_simulation(9)
        error("Fault mode simulation (SolveMode=9) failed. Cannot compute short-circuit level.")
    end

    # Set the active bus to the given node
    OpenDSSDirect.Circuit.SetActiveBus(node)
    
    # Get the base voltage of the bus (in kV)
    v_base = OpenDSSDirect.Bus.kVBase()
    
    # Retrieve the short-circuit current array at the bus (assumed in Amps)
    isc_array = OpenDSSDirect.Bus.Isc()
    
    # Take the magnitude of the first element (in Amps)
    I_sc = abs(isc_array[1])
    
    # Convert current from Amps to kA
    I_sc_kA = I_sc / 1000.0
    
    # Compute the short-circuit level (kVA) for a three-phase system:
    S_sc_kVA = sqrt(3) * v_base * I_sc_kA * 1000.0
    
    return S_sc_kVA
end
