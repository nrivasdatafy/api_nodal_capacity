"""
Get the general results of an OpenDSS simulation, including:
- Total power supplied by the sources.
- Total power demanded by the loads.
- Total system losses.

# Returns
- `Dict`: A dictionary containing the following keys and their respective values:
  - `total_power_p_kw`: Total real power supplied by sources (kW, positive).
  - `total_power_q_kvar`: Total reactive power supplied by sources (kvar, positive).
  - `total_losses_p_kw`: Total real power losses (kW).
  - `total_losses_q_kvar`: Total reactive power losses (kvar).
  - `total_load_p_kw`: Total real power demanded by loads (kW).
  - `total_load_q_kvar`: Total reactive power demanded by loads (kvar).
"""
function get_general_simulation_results(show_table::Bool = true)::Dict
    try
        # --- Global Data ---
        # Total power supplied by sources
        total_power = OpenDSSDirect.Circuit.TotalPower()
        total_power_p_kw = abs(real(total_power[1]))   # Real part of complex power (positive)
        total_power_q_kvar = abs(imag(total_power[1])) # Imaginary part of complex power (positive)

        # Total system losses
        total_losses = OpenDSSDirect.Circuit.Losses()
        total_losses_p_kw = real(total_losses[1]) / 1000.0  # Convert W to kW
        total_losses_q_kvar = imag(total_losses[1]) / 1000.0 # Convert var to kvar

        # Total power demanded by loads
        total_load_p_kw = 0.0
        total_load_q_kvar = 0.0

        l = OpenDSSDirect.Loads.First()
        while l > 0
            total_load_p_kw += OpenDSSDirect.Loads.kW()
            total_load_q_kvar += OpenDSSDirect.Loads.kvar()
            l = OpenDSSDirect.Loads.Next()
        end

        # Return results as a dictionary
        general_results =  Dict(
            "total_power_p_kw" => total_power_p_kw,
            "total_power_q_kvar" => total_power_q_kvar,
            "total_losses_p_kw" => total_losses_p_kw,
            "total_losses_q_kvar" => total_losses_q_kvar,
            "total_load_p_kw" => total_load_p_kw,
            "total_load_q_kvar" => total_load_q_kvar
        )

        if show_table
            df = DataFrame(
                "Variable"  =>  ["Total Power Supplied by Source", 
                                "Total Power Demanded by Loads", 
                                "Total System Losses"],
                "P (kW)"    =>  [round(general_results["total_power_p_kw"], digits=2),
                                round(general_results["total_load_p_kw"], digits=2),
                                round(general_results["total_losses_p_kw"], digits=2)],
                "Q (kvar)"  =>  [round(general_results["total_power_q_kvar"], digits=2),
                                round(general_results["total_load_q_kvar"], digits=2),
                                round(general_results["total_losses_q_kvar"], digits=2)]
            )
            pretty_table(df,formatters = ft_printf("%5.2f"), crop = :none, display_size = (100, 100))
        end

        return general_results
    catch e
        println("Error during general simulation result extraction: ", e)
        return Dict("error" => "An error occurred during general simulation result extraction.")
    end
end
