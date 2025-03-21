# 1) Include and use your main module (Utils)
include(joinpath("..", "src", "utils", "Utils.jl"))
using .Utils

# 2) Define input/output paths
folder_path_model   = joinpath(@__DIR__, "..", "inputs", "001")
folder_path_outputs = joinpath(@__DIR__, "..", "outputs")

# 3) Check and create folders
if check_and_create_folders(folder_path_model, folder_path_outputs)
    println("✅ Folders checked/created.")
else
    error("❌ Failed to check/create folders.")
end

# 4) Create the OpenDSS model
if create_opendss_model(folder_path_model, folder_path_outputs)
    println("✅ OpenDSS model created.")
else
    error("❌ Failed to create the OpenDSS model.")
end

# 5) Compile the OpenDSS model
if compile_opendss_model(folder_path_outputs)
    println("✅ OpenDSS model compiled.")
else
    error("❌ Failed to compile the OpenDSS model.")
end


# Read feeder minimum demands from FeedData.txt
feed_data_path = joinpath(folder_path_model, "FeederData.txt")
feed_data = Dict{String, Float64}()

# Parse the FeedData.txt file
open(feed_data_path, "r") do file
    for line in eachline(file)
        key, value = split(line, "=")
        feed_data[key] = parse(Float64, value)
    end
end

# Extract feeder minimum demands
feeder_dmin_day = feed_data["feeder_dmin_day"]
feeder_dmin_night = feed_data["feeder_dmin_night"]

# Compute the prorated minimum demand for each transformer using OpenDSS.Direct data for capacities
println("\nComputing prorated minimum demand for each transformer...")
transformer_dmin = compute_all_transformers_dmin(feeder_dmin_day, feeder_dmin_night)
println("Transformers minimum demand (day, night):")
for (trf, (dmin_day, dmin_night)) in transformer_dmin
    println("$trf -> Day: $dmin_day kW, Night: $dmin_night kW")
end