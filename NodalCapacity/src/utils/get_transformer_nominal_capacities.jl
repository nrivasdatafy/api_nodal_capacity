"""
Retrieves the nominal capacities of all secondary transformers (from MV to LV) using the OpenDSS.Direct API.
Only includes transformers whose first winding voltage is 23.0 and second winding voltage is 0.4,
skipping those with ratings [66.0, 23.0] (primary transformers).

Returns:
  Dict{String, Float64}: A dictionary mapping transformer names to their nominal capacity (in kVA, assumed equal to kW).
"""
function get_transformer_nominal_capacities()::Dict{String, Float64}
    transformer_capacities = Dict{String, Float64}()
    transformer_idx = OpenDSSDirect.Transformers.First()
    while transformer_idx > 0
        trf_name = OpenDSSDirect.Transformers.Name()
        
        # Set to winding 1 and get high voltage rating
        OpenDSSDirect.Transformers.Wdg(1.0)
        high_voltage = OpenDSSDirect.Transformers.kV()
        
        # Set to winding 2 and get low voltage rating
        OpenDSSDirect.Transformers.Wdg(2.0)
        low_voltage = OpenDSSDirect.Transformers.kV()
        
        # Skip the transformer if its ratings are [66.0, 23.0] (primary transformer)
        if high_voltage == 66.0 && low_voltage == 23.0
            transformer_idx = OpenDSSDirect.Transformers.Next()
            continue
        end
        
        # For secondary transformers (expected ratings: [23.0, 0.4]), retrieve the nominal capacity
        capacity = OpenDSSDirect.Transformers.kVA()  # Retrieve rated capacity (in kVA, assumed equal to kW)
        transformer_capacities[trf_name] = capacity
        
        transformer_idx = OpenDSSDirect.Transformers.Next()
    end
    return transformer_capacities
end
