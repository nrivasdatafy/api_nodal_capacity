"""
Plots the network graph as a rooted tree, including node labels.

# Arguments
- `graph::SimpleGraph{Int}`: The undirected input graph.
- `network::NetworkData`: The network structure containing node mappings.

# Returns
- `Nothing`: Display the network graph plot to the specified file.
"""
function plot_network_graph(
    rooted_tree::SimpleDiGraph{Int},
    network::NetworkData
)

    # Step 1: Extract node labels from the network structure
    node_to_index = network.node_to_index
    index_to_node = Dict(v => k for (k, v) in node_to_index)
    node_labels = [string(index_to_node[i], ":", i) for i in 1:nv(rooted_tree)]

    # Step 2: Compute node positions using the Buchheim layout
    node_pos = buchheim(rooted_tree.fadjlist)
    xn, yn = getindex.(node_pos, 1), getindex.(node_pos, 2)

    # Step 3: Plot the network graph
    p=gplot(
        rooted_tree,
        xn,
        -yn;  # Flip the y-axis for better visualization
        nodelabel=node_labels,
        NODELABELSIZE=2,
        nodesize=0.5,
        title="Network Graph",
        plot_size = (30cm, 20cm)
    )
    display(p)
end