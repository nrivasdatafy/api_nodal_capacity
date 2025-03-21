# NodalCapacity

`NodalCapacity` es un proyecto desarrollado en Julia para modelar y analizar redes eléctricas de distribución, evaluando su capacidad nodal y criterios de conexión de proyectos de generación distribuida. Este conjunto de herramientas se basa en el uso de OpenDSS para simular redes y realizar cálculos detallados.

## Estructura del Proyecto

El proyecto tiene la siguiente estructura de carpetas y archivos:

```
Manifest.toml
Project.toml
README.md
inputs/
   001/
      Buses.txt
      FeederData.txt
      Linecodes.txt
      Lines.txt
      Loads.txt
      PVsystems.txt
      Transformers.txt
   002/
      Buses.txt
      Linecodes.txt
      Lines.txt
      Loads.txt
      loadsMT.txt
      ...
outputs/
   master.txt
src/
   api/
   utils/
test/
   test_basic_workflow.jl
   test_compute_all_transformers_dmin.jl
   test_compute_nodal_capacity.jl
   test_find_deepest_node.jl
   test_get_hosting_capacity.jl
   test_get_node_short_circuit_level.jl
   test_transformers_functions.jl
```

## Archivos y Funcionalidades

### Archivos principales

1. **add_feeder_meter.jl**  
   Agrega un medidor de energía al inicio del alimentador (primer transformador del modelo).

2. **check_isolated_elements.jl**  
   Verifica la existencia de ramas o cargas aisladas en un modelo compilado de OpenDSS.

3. **compile_opendss_model.jl**  
   Compila un archivo de modelo OpenDSS (`master.txt`) usando OpenDSSDirect.

4. **compute_nodal_capacity.jl**  
   Calcula la capacidad de alojamiento para todos los nodos en la red, excluyendo nodos ficticios. Genera resultados normalizados entre 0 y 1.

5. **count_loads_under_transformers.jl**  
   Cuenta el número de cargas bajo cada transformador secundario del sistema.

6. **create_opendss_model.jl**  
   Genera un archivo de modelo OpenDSS (`master.txt`) a partir de archivos de entrada.

7. **create_small_network_model.jl**  
   Crea un modelo simplificado de una red eléctrica pequeña en formato OpenDSS.

8. **evaluate_project_connection.jl**  
   Evalúa si un proyecto de generación distribuida cumple con los criterios técnicos de conexión a la red.

9. **find_load_transformer.jl**  
   Identifica el transformador aguas arriba de una carga específica en el modelo de red.

10. **generate_rooted_tree.jl**  
   Genera un árbol enraizado a partir de un grafo no dirigido y actualiza las asignaciones de `NetworkData`.

11. **get_general_simulation_results.jl**  
   Extrae resultados generales de simulaciones de OpenDSS, incluyendo potencias suministradas, demandadas y pérdidas del sistema.

12. **get_hosting_capacity.jl**  
   Calcula la capacidad de alojamiento para un nodo específico en la red.

13. **get_network_infrastructure.jl**  
   Obtiene métricas generales de la infraestructura de la red, como longitudes de líneas, número de cargas y transformadores.

14. **get_subgraph_from_transformer.jl**  
   Obtiene un subgrafo a partir de un transformador específico, incluyendo nodos y bordes aguas abajo.

15. **get_transformer_for_load.jl**  
   Encuentra el transformador aguas arriba de una carga en el árbol enraizado.

16. **get_transformer_for_node.jl**  
   Encuentra el transformador aguas arriba de un nodo específico en el árbol enraizado.

17. **plot_capacity_map.jl**  
   Genera un mapa visual de la capacidad de alojamiento en la red eléctrica.

18. **plot_network_graph.jl**  
   Dibuja el grafo de la red como un árbol enraizado con etiquetas para los nodos.

19. **plot_network_map.jl**  
   Genera un mapa de la red eléctrica utilizando los datos de entrada del modelo.

20. **plot_voltage_profile.jl**  
   Genera un perfil de voltaje para los nodos de carga a lo largo del alimentador.

21. **run_simulation.jl**  
   Ejecuta una simulación en el modelo de OpenDSS cargado.

22. **total_pv_capacity.jl**  
   Calcula la capacidad total instalada de sistemas fotovoltaicos en el modelo.

23. **validate_model_files.jl**  
   Valida que todos los archivos necesarios para el modelo existan en el directorio especificado.

### Archivos de prueba

1. **test_basic_workflow.jl**  
   Ejecuta un flujo completo que incluye validación, simulación, y visualización de resultados.

2. **test_compute_all_transformers_dmin.jl**  
   Prueba la función para calcular la distancia mínima de todos los transformadores.

3. **test_compute_nodal_capacity.jl**  
   Prueba la función para calcular la capacidad nodal.

4. **test_find_deepest_node.jl**  
   Prueba la función para encontrar el nodo más profundo en el árbol enraizado.

5. **test_get_hosting_capacity.jl**  
   Prueba la función para calcular la capacidad de alojamiento de un nodo específico.

6. **test_get_node_short_circuit_level.jl**  
   Prueba la función para obtener el nivel de cortocircuito de un nodo.

7. **test_transformers_functions.jl**  
   Prueba las funciones relacionadas con los transformadores.

## Instalación

1. Clona este repositorio:
   ```bash
   git clone https://github.com/tu_usuario/NodalCapacity.git
   cd NodalCapacity
   ```

2. Instala [Julia](https://julialang.org/downloads/) si aún no lo tienes instalado.

3. Instala las dependencias necesarias:
   ```julia
   using Pkg
   Pkg.instantiate()
   ```

## Uso

1. Crea el modelo de OpenDSS:
   ```julia
   create_opendss_model("ruta_al_modelo", "carpeta_de_salida", "master.txt")
   ```

2. Compila el modelo:
   ```julia
   compile_opendss_model("ruta_a_master.txt")
   ```

3. Calcula la capacidad nodal:
   ```julia
   compute_nodal_capacity("ruta_al_modelo", "carpeta_de_salida")
   ```

4. Evalúa criterios de conexión:
   ```julia
   evaluate_project_connection("ruta_al_modelo", "carpeta_de_salida", "nombre_proyecto", 10.0, 5.0, "Nodo_BT1", 0.95)
   ```

5. Genera un mapa de capacidad de alojamiento:
   ```julia
   plot_capacity_map("ruta_al_modelo", "carpeta_de_salida", "mapa_capacidad.png", nodal_capacity)
   ```

## Ejemplo
El proyecto incluye un ejemplo para crear un modelo pequeño y realizar simulaciones:

```julia
create_small_network_model("test_case_master.txt")
compile_opendss_model("test_case_master.txt")
compute_nodal_capacity("carpeta_modelo", "carpeta_salida")
```

## Contribuciones
¡Las contribuciones son bienvenidas! Por favor, abre un issue o envía un pull request para discutir posibles mejoras o cambios.

## Licencia
Este proyecto está licenciado bajo [MIT License](LICENSE).
