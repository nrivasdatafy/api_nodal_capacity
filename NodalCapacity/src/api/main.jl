module Main

# Import required packages
using JSON

# Include the files from the src folder
include(joinpath(@__DIR__, "api_compute_nodal_capacity.jl"))

# Export the functions for use outside the module
export  api_compute_nodal_capacity
end


if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 1
        println("Debe especificar una función para ejecutar.")
    else
        func_name = ARGS[1]
        args = ARGS[2:end]    
        try
            func = getfield(Main, Symbol(func_name))
            if length(args) > 0
                result = func(args...)
            else
                result = func()
            end
            println(result)
        catch e
            println("Error al ejecutar la función: ", e)
        end
    end
end