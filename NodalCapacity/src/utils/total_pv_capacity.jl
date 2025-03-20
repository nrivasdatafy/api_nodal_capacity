"""
Calculate the total installed capacity of photovoltaic systems.

# Arguments
- `pv_dict::Dict{String, Int64}`: A dictionary where keys are the names of PV systems and values are their indices.

# Returns
- `Float64`: The total installed capacity of the photovoltaic systems (kW).
"""
function total_pv_capacity(pv_dict::Dict{String, Int64})
    total_capacity = 0.0

    for pv_name in keys(pv_dict)
        # Set the active PVSystem in OpenDSS
        OpenDSSDirect.PVsystems.Name(pv_name)
        capacity = OpenDSSDirect.PVsystems.kVARated()
        total_capacity += capacity
    end

    return total_capacity
end