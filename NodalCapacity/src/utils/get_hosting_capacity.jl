"""
Calcular la capacidad de hosting para un nodo específico de la red utilizando múltiples criterios técnicos.

# Inputs
- `rooted_tree::SimpleDiGraph{Int}`: Grafo dirigido que representa el árbol enraizado de la red.
- `rooted_network::NetworkData`: Datos de la red con los mapeos correspondientes.
- `node_name::String`: Nombre del nodo a evaluar.

# Returns
- `Float64`: Capacidad de hosting del nodo (no normalizada), resultante de la combinación de varios criterios.
"""
function get_hosting_capacity(
    rooted_tree::SimpleDiGraph{Int},
    rooted_network::NetworkData,
    node_name::String
)::Float64
    # Verificar la existencia del nodo en la red
    if !haskey(rooted_network.node_to_index, node_name)
        error("Nodo $node_name no encontrado en la red.")
    end

    # Obtener el índice del nodo
    node_index = rooted_network.node_to_index[node_name]

    # ------------------------------------------------------------------
    # Criterio 1: Impacto de la topología descendente
    # Se considera que a mayor número de nodos descendientes, menor la capacidad.
    function criterio_topologia(node_index::Int)
        num_descendientes = length(outneighbors(rooted_tree, node_index))
        # Factor topológico decreciente en función de los descendientes
        factor_topologico = 1.0 / (1.0 + num_descendientes)
        return factor_topologico
    end

    # ------------------------------------------------------------------
    # Criterio 2: Evaluación de redundancia en la red
    # Se simula la redundancia acumulando el "peso" de cada vecino y se normaliza.
    function criterio_redundancia(node_index::Int)
        vecinos = outneighbors(rooted_tree, node_index)
        redundancia = 0.0
        for vecino in vecinos
            # Para cada vecino se toma en cuenta su número de descendientes
            redundancia += 1.0 / (1.0 + length(outneighbors(rooted_tree, vecino)))
        end
        # Se aplica una función exponencial para limitar el impacto acumulado
        factor_redundancia = 1.0 - exp(-redundancia)
        return factor_redundancia
    end

    # ------------------------------------------------------------------
    # Criterio 3: Evaluación del factor transformador
    # Basado en la nomenclatura del nodo, se asume que existen distintos niveles de tensión.
    function criterio_transformador(node_name::String)
        if occursin(r"(?i)BT", node_name)   # Baja tensión
            factor_trafico = 0.8
        elseif occursin(r"(?i)MT", node_name)  # Media tensión
            factor_trafico = 1.0
        else
            factor_trafico = 0.5  # Caso por defecto para nodos de tipo desconocido
        end
        return factor_trafico
    end

    # ------------------------------------------------------------------
    # Criterio 4: Estabilidad simulada del nodo
    # Se utiliza una función periódica para simular la estabilidad del nodo.
    function criterio_estabilidad(node_index::Int)
        # Se genera un valor entre 0 y 1 en base al seno del índice
        estabilidad = 0.5 + 0.5 * sin(node_index)
        return clamp(estabilidad, 0.0, 1.0)
    end

    # ------------------------------------------------------------------
    # Evaluación de cada criterio
    factor_topologia = criterio_topologia(node_index)
    factor_redundancia = criterio_redundancia(node_index)
    factor_transformador = criterio_transformador(node_name)
    factor_estabilidad = criterio_estabilidad(node_index)

    # Combinación de los factores con exponentes que ponderan la contribución de cada criterio
    capacidad = (factor_topologia^0.5) *
                (factor_redundancia^0.3) *
                (factor_transformador^0.1) *
                (factor_estabilidad^0.1)

    # Ajuste final: se incrementa ligeramente la capacidad en función del número de nodos descendientes
    capacidad_final = capacidad * (1.0 + 0.1 * length(outneighbors(rooted_tree, node_index)))

    return capacidad_final
end
