"""
Get the general infrastructure of the network, including line lengths, load counts, transformer counts,
feeder short-circuit levels, primary transformer capacity, total secondary transformer capacity,
and PV systems power, disaggregated by medium voltage (MV) and low voltage (LV) connection,
as well as the total PV systems power.

# Arguments
- `umbral_kv::Float64`: Voltage threshold to distinguish between low voltage (BT) and medium voltage (MT). Default is 1.0 kV.
- `show_table::Bool`: Whether to display the results in a table.

# Returns
- `Dict`: A dictionary containing the following keys:
  - `bt_line_length_km`: Total length of low-voltage (BT) lines in km.
  - `mt_line_length_km`: Total length of medium-voltage (MT) lines in km.
  - `total_line_length_km`: Total length of all lines in km.
  - `bt_load_count`: Number of loads in low-voltage (BT).
  - `mt_load_count`: Number of loads in medium-voltage (MT).
  - `total_load_count`: Total number of loads in the network.
  - `transformer_count`: Total number of transformers.
  - `feeder_isc1`: Feeder short-circuit parameter Isc1.
  - `feeder_isc3`: Feeder short-circuit parameter Isc3.
  - `primary_transformer_capacity`: Capacity of the primary transformer (kVs = [66.0, 23.0]).
  - `total_secondary_transformer_capacity`: Sum of capacities of all secondary transformers (kVs = [23.0, 0.4]).
  - `total_PV_medium_voltage_power`: Sum of rated power (Pmpp) of all PV systems connected at medium voltage (kV ≥ umbral_kv).
  - `total_PV_low_voltage_power`: Sum of rated power (Pmpp) of all PV systems connected at low voltage (kV < umbral_kv).
  - `total_PV_total_power`: Total PV systems power (the sum of the above two values).
"""
function get_network_infrastructure(umbral_kv::Float64 = 1.0, show_table::Bool = true)::Dict
    try
        # Initialize metrics
        bt_line_length_km = 0.0
        mt_line_length_km = 0.0
        total_line_length_km = 0.0
        bt_load_count = 0
        mt_load_count = 0
        transformer_count = 0

        # Process lines
        line_idx = OpenDSSDirect.Lines.First()
        while line_idx > 0
            line_name = OpenDSSDirect.Lines.Name()
            OpenDSSDirect.Circuit.SetActiveElement("Line." * line_name)

            # Get line base voltage from the reference bus
            ref_bus = OpenDSSDirect.CktElement.BusNames()[1]
            OpenDSSDirect.Circuit.SetActiveBus(ref_bus)
            kv_base = OpenDSSDirect.Bus.kVBase()

            # Get line length (in meters)
            length_meters = OpenDSSDirect.Lines.Length()
            length_km = length_meters / 1000.0  # Convert meters to km

            # Categorize by voltage level
            if kv_base < umbral_kv
                bt_line_length_km += length_km
            else
                mt_line_length_km += length_km
            end

            total_line_length_km += length_km
            line_idx = OpenDSSDirect.Lines.Next()
        end

        # Process loads
        load_idx = OpenDSSDirect.Loads.First()
        while load_idx > 0
            load_name = OpenDSSDirect.Loads.Name()
            OpenDSSDirect.Circuit.SetActiveElement("Load." * load_name)

            load_kv = OpenDSSDirect.Loads.kV()
            phases = OpenDSSDirect.Loads.Phases()
            bus_name = OpenDSSDirect.CktElement.BusNames()[1]  # e.g., "BT38361061.1.2.3"

            if load_kv < umbral_kv && phases == 1
                bt_load_count += 1
            elseif phases == 3 || contains(bus_name, ".1.2.3")
                mt_load_count += 1
            else
                bt_load_count += 1  # Default to BT if no criteria for MT are met
            end

            load_idx = OpenDSSDirect.Loads.Next()
        end
        total_load_count = bt_load_count + mt_load_count

        # Process transformers for counting
        tx_idx = OpenDSSDirect.Transformers.First()
        while tx_idx > 0
            transformer_count += 1
            tx_idx = OpenDSSDirect.Transformers.Next()
        end

        # --- Additional Information from the OpenDSS model ---

        # 1. Feeder short-circuit parameters (Isc1 and Isc3)
        # Set the active bus to the source bus and obtain the short-circuit currents from that bus.
        # "sourcebus" should be the name of the bus representing the feeder's source.
        OpenDSSDirect.Circuit.SetActiveBus("sourcebus")
        isc_array = OpenDSSDirect.Bus.Isc()  # Returns a Complex Array with short-circuit currents
        # Extract the magnitudes for Isc1 and Isc3 (assuming index 1 and 3 respectively)
        feeder_isc1 = abs(isc_array[1])
        feeder_isc3 = abs(isc_array[3])

        # 2. Process transformers to obtain:
        #    - Primary transformer capacity (kVs = [66.0, 23.0])
        #    - Total secondary transformer capacity (kVs = [23.0, 0.4])
        primary_transformer_capacity = 0.0
        total_secondary_transformer_capacity = 0.0
        tx_idx = OpenDSSDirect.Transformers.First()
        while tx_idx > 0
            trf_name = OpenDSSDirect.Transformers.Name()
            # Set winding 1 for high voltage and winding 2 for low voltage
            OpenDSSDirect.Transformers.Wdg(1.0)
            hv = OpenDSSDirect.Transformers.kV()
            OpenDSSDirect.Transformers.Wdg(2.0)
            lv = OpenDSSDirect.Transformers.kV()
            capacity = OpenDSSDirect.Transformers.kVA()  # Nominal capacity (kVA, assumed equal to kW)
            if hv == 66.0 && lv == 23.0
                primary_transformer_capacity = capacity
            elseif hv == 23.0 && lv == 0.4
                total_secondary_transformer_capacity += capacity
            end
            tx_idx = OpenDSSDirect.Transformers.Next()
        end

        # 3. Process PVsystems: Disaggregate PV power based on connection voltage
        total_PV_medium_voltage_power = 0.0
        total_PV_low_voltage_power = 0.0
        total_PV_total_power = 0.0
        pv_idx = OpenDSSDirect.PVsystems.First()
        while pv_idx > 0
            pv_name = OpenDSSDirect.PVsystems.Name()
            OpenDSSDirect.Circuit.SetActiveElement("PVsystem." * pv_name)
            bus = OpenDSSDirect.CktElement.BusNames()[1]
            OpenDSSDirect.Circuit.SetActiveBus(bus)
            kv_base = OpenDSSDirect.Bus.kVBase()
            pv_power = OpenDSSDirect.PVsystems.Pmpp()  # Rated power (Pmpp) of the PV system
            if kv_base >= umbral_kv
                total_PV_medium_voltage_power += pv_power
            else
                total_PV_low_voltage_power += pv_power
            end
            total_PV_total_power += pv_power
            pv_idx = OpenDSSDirect.PVsystems.Next()
        end

        # Build the results dictionary
        network_description = Dict(
            "bt_line_length_km" => bt_line_length_km,
            "mt_line_length_km" => mt_line_length_km,
            "total_line_length_km" => total_line_length_km,
            "bt_load_count" => bt_load_count,
            "mt_load_count" => mt_load_count,
            "total_load_count" => total_load_count,
            "transformer_count" => transformer_count,
            "feeder_isc1" => feeder_isc1,
            "feeder_isc3" => feeder_isc3,
            "primary_transformer_capacity" => primary_transformer_capacity,
            "total_secondary_transformer_capacity" => total_secondary_transformer_capacity,
            "total_PV_medium_voltage_power" => total_PV_medium_voltage_power,
            "total_PV_low_voltage_power" => total_PV_low_voltage_power,
            "total_PV_total_power" => total_PV_total_power
        )

        if show_table
            df_network = DataFrame(
                "Parameter" => [
                    "BT Line Length (km)",
                    "MT Line Length (km)",
                    "Total Line Length (km)",
                    "BT Load Count",
                    "MT Load Count",
                    "Total Load Count",
                    "Transformer Count",
                    "Feeder Isc1",
                    "Feeder Isc3",
                    "Primary Transformer Capacity (kVA)",
                    "Total Secondary Transformer Capacity (kVA)",
                    "PV Medium Voltage Power (kW)",
                    "PV Low Voltage Power (kW)",
                    "Total PV Power (kW)"
                ],
                "Value" => [
                    round(network_description["bt_line_length_km"], digits=2),
                    round(network_description["mt_line_length_km"], digits=2),
                    round(network_description["total_line_length_km"], digits=2),
                    network_description["bt_load_count"],
                    network_description["mt_load_count"],
                    network_description["total_load_count"],
                    network_description["transformer_count"],
                    network_description["feeder_isc1"],
                    network_description["feeder_isc3"],
                    network_description["primary_transformer_capacity"],
                    network_description["total_secondary_transformer_capacity"],
                    network_description["total_PV_medium_voltage_power"],
                    network_description["total_PV_low_voltage_power"],
                    network_description["total_PV_total_power"]
                ]
            )
            pretty_table(df_network; formatters = ft_printf("%5.2f"), crop = :none, display_size = (100, 100))
        end

        return network_description

    catch e
        println("Error describing network infrastructure: ", e)
        return Dict("error" => "An error occurred during network infrastructure description.")
    end
end
