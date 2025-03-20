"""
Computes the prorated minimum demand (daytime and nighttime) for each secondary transformer (from MV to LV)
based on the overall feeder minimum demand and each transformer's nominal capacity retrieved via OpenDSS.Direct.

Arguments:
  - feeder_dmin_day :: Float64: Overall feeder daytime minimum demand (kW)
  - feeder_dmin_night :: Float64: Overall feeder nighttime minimum demand (kW)

Returns:
  - Dict{String, Tuple{Float64, Float64}}: A dictionary mapping transformer names to a tuple (dmin_day, dmin_night)
"""
function compute_all_transformers_dmin(feeder_dmin_day::Float64, feeder_dmin_night::Float64)::Dict{String, Tuple{Float64, Float64}}
    trfo_nominal_capacity = get_transformer_nominal_capacities()
    total_capacity = sum(values(trfo_nominal_capacity))
    transformer_dmin = Dict{String, Tuple{Float64, Float64}}()
    for (trf_name, capacity) in trfo_nominal_capacity
        dmin_day = feeder_dmin_day * (capacity / total_capacity)
        dmin_night = feeder_dmin_night * (capacity / total_capacity)
        transformer_dmin[trf_name] = (dmin_day, dmin_night)
    end
    return transformer_dmin
end
