"""
find_deepest_node(
    subtree::SimpleDiGraph{Int},
    subnetwork::NetworkData,
    network::NetworkData
)

Finds the deepest node (i.e. the one with the greatest accumulated distance) in a subtree.

This function traverses the subtree (assumed to be a directed graph with node 1 as the root)
using DFS and accumulates distances along each branch. The distance between two nodes is 
determined by checking if a line exists between the corresponding nodes in subnetwork.line_to_nodes_idx
and, if available, using its recorded length from subnetwork.line_to_length. If no line length is found,
a default value of 1.0 is used.

Additionally, if the farthest node is a fictitious load node (its name starts with "e_"), this function
returns the parent node instead (the node "just before" the load node).

Returns a tuple:
  - farthest_node::Int: The index (in the subtree) of the deepest non-"e_" node.
  - farthest_bus::String: The original bus name corresponding to that node.
  - total_distance::Float64: The total accumulated distance from the root (node 1) to the returned node.
"""
function find_deepest_node(
    subtree::SimpleDiGraph{Int},
    subnetwork::NetworkData,
    network::NetworkData
)
    max_distance = Ref(0.0)
    farthest_node = Ref(1)

    # We'll store the distance to each node so we can adjust if we skip "e_" nodes at the end.
    node_distance = Dict{Int, Float64}()

    # Build a reverse mapping from new node indices to original bus names in subnetwork.
    index_to_node = Dict{Int, String}()
    for (bus, idx) in subnetwork.node_to_index
        index_to_node[idx] = bus
    end

    # Helper function to calculate distance between two nodes in the subtree.
    # We look up subnetwork.line_to_nodes_idx and subnetwork.line_to_length for a matching line.
    # If not found, we return 1.0.
    function get_distance(parent_idx::Int, child_idx::Int)
        for (line_name, (s, d)) in subnetwork.line_to_nodes_idx
            if s == parent_idx && d == child_idx
                if haskey(subnetwork.line_to_length, line_name)
                    return subnetwork.line_to_length[line_name]
                else
                    break
                end
            end
        end
        return 1.0
    end

    # DFS to track the distance to each node from node 1
    function dfs(node::Int, accumulated::Float64)
        node_distance[node] = accumulated
        if accumulated > max_distance[]
            max_distance[] = accumulated
            farthest_node[] = node
        end
        for neighbor in outneighbors(subtree, node)
            dfs(neighbor, accumulated + get_distance(node, neighbor))
        end
    end

    # Start DFS from node 1
    dfs(1, 0.0)

    # Retrieve the deepest node found by the DFS
    final_node = farthest_node[]
    final_bus = index_to_node[final_node]
    final_distance = node_distance[final_node]

    # If the deepest node is a load node (e.g., starts with "e_"), return its parent instead.
    # This ensures we get the node "just before" the load node.
    if startswith(final_bus, "e_")
        parents = inneighbors(subtree, final_node)
        if !isempty(parents)
            # If multiple parents exist, we take the first. Adjust as needed.
            parent_node = first(parents)
            final_node = parent_node
            final_bus = index_to_node[parent_node]
            final_distance = node_distance[parent_node]
        end
    end

    return (final_node, final_bus, final_distance)
end
