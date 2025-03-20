using Printf

"""
Creates a medium-voltage-only model folder named 'MT_model' inside `folder_name_model`.

Selection of MT lines:
1) If the line name (e.g. `New Line.mt1234`) contains 'mt' (case-insensitive), or
2) If both bus1 and bus2 start with 'mt'.

All transformers are copied. Buses are filtered to those used by lines/transformers.
For each transformer (except the first), we:
- Create a new bus for the load (bus2 + "_ld"),
- Add a short LV line from bus2 to bus2_ld,
- Place a load on bus2_ld with kW = 80% of the transformer's secondary kVA.

# Arguments
- `folder_name_model::String`: Path to the original model folder (e.g. "inputs/304_jorge").

Example:
    create_mt_model("inputs/304_jorge")
"""
function create_mt_model(folder_name_model::String)::Bool
    try
        # 0) Prepare paths
        original_lines_file        = joinpath(folder_name_model, "Lines.txt")
        original_transformers_file = joinpath(folder_name_model, "Transformers.txt")
        original_buses_file        = joinpath(folder_name_model, "Buses.txt")
        original_loads_file        = joinpath(folder_name_model, "Loads.txt")  # if needed for reference

        # Output folder: "folder_name_model/MT_model"
        output_folder = joinpath(folder_name_model, "MT_model")
        if !isdir(output_folder)
            mkpath(output_folder)  # create if not exists
        end

        # -------------------------
        # 1) Create Lines.txt for MT only
        #    Condition:
        #    (A) line name has "mt" in it
        #    (B) or both bus1 and bus2 start with "mt"
        # -------------------------
        mt_buses_set = Set{String}()  # store all bus names used by lines or transformers
        lines_out_file = joinpath(output_folder, "Lines.txt")

        open(lines_out_file, "w") do outf
            if isfile(original_lines_file)
                for line in eachline(original_lines_file)
                    local lower_line = lowercase(line)

                    # 1A) Check if line name has "mt"
                    line_name_match = match(r"(?i)new\s+line\.([^.\s]+)", line)
                    line_has_mt = false
                    if line_name_match !== nothing
                        local ln_name = lowercase(line_name_match.captures[1])
                        if occursin("mt", ln_name)
                            line_has_mt = true
                        end
                    end

                    # 1B) parse bus1=..., bus2=...
                    bus1_match = match(r"(?i)bus1=([^.\s]+)", line)
                    bus2_match = match(r"(?i)bus2=([^.\s]+)", line)
                    local bus_condition = false
                    if bus1_match !== nothing && bus2_match !== nothing
                        local bus1_str = lowercase(bus1_match.captures[1])
                        local bus2_str = lowercase(bus2_match.captures[1])
                        if startswith(bus1_str, "mt") && startswith(bus2_str, "mt")
                            bus_condition = true
                        end
                    end

                    # Keep the line if line_has_mt or bus_condition
                    if line_has_mt || bus_condition
                        println(outf, line)

                        # record bus names if we found them
                        if bus1_match !== nothing
                            push!(mt_buses_set, lowercase(bus1_match.captures[1]))
                        end
                        if bus2_match !== nothing
                            push!(mt_buses_set, lowercase(bus2_match.captures[1]))
                        end
                    end
                end
            else
                @warn "Original Lines.txt not found at $original_lines_file"
            end
        end

        # We'll reopen lines_out_file in "append" mode later when we add the short LV lines.

        # -------------------------
        # 2) Copy Transformers.txt (all), parse bus names
        # -------------------------
        transformers_out_file = joinpath(output_folder, "Transformers.txt")
        transformers_list = String[]  # store each transformer's line for building loads

        open(transformers_out_file, "w") do outf
            if isfile(original_transformers_file)
                for line in eachline(original_transformers_file)
                    println(outf, line)
                    push!(transformers_list, line)

                    local lower_line = lowercase(line)
                    local matches = match(r"buses=\[([^.\s]+)\s+([^.\s]+)\]", lower_line)
                    if matches !== nothing
                        local bus1 = matches.captures[1]
                        local bus2 = matches.captures[2]
                        push!(mt_buses_set, bus1)
                        push!(mt_buses_set, bus2)
                    end
                end
            else
                @warn "Original Transformers.txt not found at $original_transformers_file"
            end
        end

        # -------------------------
        # 3) Parse original Buses.txt, keep only those in mt_buses_set
        # -------------------------
        # We'll also store the coordinates in a dict so we can place the new load bus "off to the side"
        bus_coords_dict = Dict{String, Tuple{Float64, Float64}}()
        existing_buses_in_file = Set{String}()

        local buses_out_file = joinpath(output_folder, "Buses.txt")
        open(buses_out_file, "w") do outf
            if isfile(original_buses_file)
                for line in eachline(original_buses_file)
                    local parts = split(line)
                    # e.g. "bus_mt1234  650000.0  5450000.0"
                    if length(parts) >= 3
                        local bus_name = lowercase(parts[1])
                        local x_str = parts[2]
                        local y_str = parts[3]
                        local x_val = tryparse(Float64, x_str)
                        local y_val = tryparse(Float64, y_str)
                        if bus_name in mt_buses_set && x_val !== nothing && y_val !== nothing
                            # keep this bus line
                            println(outf, line)
                            push!(existing_buses_in_file, bus_name)
                            bus_coords_dict[bus_name] = (x_val, y_val)
                        end
                    end
                end
            else
                @warn "Original Buses.txt not found at $original_buses_file"
            end
        end

        # Warn if any bus from lines/transformers not found
        for b in mt_buses_set
            if !(b in existing_buses_in_file)
                @warn "Bus '$b' is referenced by Lines/Transformers but not found in original Buses.txt"
            end
        end

        # -------------------------
        # 4) Create Loads.txt and short LV lines
        #    - skip the FIRST transformer
        #    - for each subsequent transformer, parse bus2 => create new bus2_ld, a short LV line, and the load
        # -------------------------
        local loads_out_file = joinpath(output_folder, "Loads.txt")

        # We'll append new lines to Lines.txt for the short LV segments
        open(lines_out_file, "a") do lines_outf
            open(loads_out_file, "w") do outf_loads
                if !isempty(transformers_list)
                    for (i, tline) in enumerate(transformers_list)
                        if i == 1
                            # skip the first transformer
                            continue
                        end

                        # e.g.
                        # New Transformer.2975 buses=[bus_mt70050 bus_bt70051] ...
                        local trans_name_match = match(r"(?i)new\s+transformer\.([^.\s]+)", tline)
                        local buses_match      = match(r"buses=\[([^.\s]+)\s+([^.\s]+)\]", lowercase(tline))
                        local kvs_match        = match(r"kvs=\[([^\s]+)\s+([^\s\]]+)\]", lowercase(tline))
                        local kvas_match       = match(r"kvas=\[([^\s]+)\s+([^\s\]]+)\]", lowercase(tline))

                        if trans_name_match === nothing || buses_match === nothing ||
                        kvs_match === nothing || kvas_match === nothing
                            continue
                        end

                        local trans_name = trans_name_match.captures[1]
                        local bus1_mt    = buses_match.captures[1]  # not used for load
                        local bus2_lv    = buses_match.captures[2]
                        local kv_prim    = kvs_match.captures[1]    # not used for load
                        local kv_sec     = kvs_match.captures[2]
                        local kva_prim   = kvas_match.captures[1]   # not used for load
                        local kva_sec    = kvas_match.captures[2]

                        local kva_sec_float = parse(Float64, kva_sec)
                        local kv_sec_float  = parse(Float64, kv_sec)
                        local load_kW = 0.8 * kva_sec_float
                        local load_name = "load_" * trans_name

                        # We'll create a new bus: bus2_lv_ld
                        local new_bus = bus2_lv * "_ld"
                        push!(mt_buses_set, new_bus)  # so we can add it to Buses.txt

                        # We'll offset the existing bus coords by +5 in x
                        local x_val, y_val = 0.0, 0.0
                        if haskey(bus_coords_dict, bus2_lv)
                            (x_val, y_val) = bus_coords_dict[bus2_lv]
                        end
                        local new_bus_x = x_val + 5.0
                        local new_bus_y = y_val

                        # We'll store this new bus in bus_coords_dict so we can write it to Buses.txt
                        bus_coords_dict[new_bus] = (new_bus_x, new_bus_y)

                        # (A) Add the short LV line from bus2_lv to new_bus
                        # e.g. "New Line.bt_<trans_name> bus1=bus2_lv bus2=bus2_lv_ld phases=3 length=0.05 units=km r1=0.4 x1=0.1"
                        local short_line_name = "bt_" * trans_name
                        println(lines_outf, 
                            "New Line.$short_line_name bus1=$bus2_lv bus2=$new_bus phases=3 length=0.05 units=km r1=0.4 x1=0.1"
                        )

                        # (B) Create the load on the new bus
                        @printf(outf_loads,
                            "New Load.%s bus1=%s phases=3 kV=%.3f kW=%.3f pf=0.95\n",
                            load_name, new_bus, kv_sec_float, load_kW
                        )
                    end
                end
            end
        end

        # Finally, we must **append** the new bus coordinates to Buses.txt
        local appended_buses = 0
        open(buses_out_file, "a") do outf_buses
            for (b, (xx, yy)) in bus_coords_dict
                # If 'b' wasn't originally in existing_buses_in_file but is in mt_buses_set => new bus
                if !(b in existing_buses_in_file) && (b in mt_buses_set)
                    println(outf_buses, "$b  $xx  $yy")
                    push!(existing_buses_in_file, b)
                    appended_buses += 1
                end
            end
        end

        println("MT model creation complete at: $output_folder")
        println("Appended $appended_buses new bus(es) for loads.")

        return true
    catch e
        println("Error creating MT model: ", e)
        return false
    end
end
