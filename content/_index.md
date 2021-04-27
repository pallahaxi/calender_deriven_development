---
title: Test
type: docs
---

# Section 1

{{< columns >}}
## Subsection 1

第1節

<--->

## Subsection 2

第2節
{{< /columns >}}


## Subsection 3

第3節

コードブロック

    var panel = ram_design;
    if (backup + system) {
        file.readPoint = network_native;
        sidebar_engine_device(cell_tftp_raster,
                dual_login_paper.adf_vci.application_reader_design(
                graphicsNvramCdma, lpi_footer_snmp, integer_model));
    }

## Subsection 4

第4節

```julia:opt_graph.jl
using LightGraphs, SimpleWeightedGraphs, GraphPlot, Cairo, GraphRecipes, Compose, Colors


function ordered_edges(graph::LightGraphs.AbstractGraph)
    edge_dict = Dict{Tuple{Int,Real}, Any}()
    for e in edges(graph)
        edge_dict[(src(e), dst(e))] = e
    end
    return values(sort(edge_dict))
end


function generate_grid(node_num_array::Union{Tuple{Int,Real},Array{Int,1}},
                       random_range::Union{UnitRange{<:Real}, Array{<:Real,1}}=1:10,
                       plot_flag::Bool=false,
                       file_name::String="grid.png")
    @assert length(node_num_array) == 2

    grid_graph = grid(node_num_array) # gridでエッジを構築
    g = SimpleWeightedGraph(nv(grid_graph)) # 重み付きエッジのグラフをgrid_graphのノードの個数構築
    edge_weight = rand(random_range, grid_graph.ne) # 予め乱数でエッジの重みを作成
    for (num, e) in enumerate(edges(grid_graph))
        add_edge!(g, e.src, e.dst, edge_weight[num])
    end
    locs_x = Array{Float64, 1}(
        vcat([i for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    locs_y = Array{Float64, 1}(
        vcat([j for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    if plot_flag
        draw(
            PNG(file_name, 10cm, 10cm),
            gplot(SimpleGraph(g), # weightgraphは直接gplotに渡せない
                  locs_x, locs_y,
                  nodelabel=1:nv(g),
                  # collect(edges(g))の順序とplotの順序は対応していないので注意
                  # edgeのlabel orderはlexicographic orderingに従うhttps://github.com/JuliaGraphs/GraphPlot.jl/issues/70
                  edgelabel=[e.weight for e in ordered_edges(g)])
        )
    end
    return g
end

function grid_yen_shortest_path(graph::LightGraphs.AbstractGraph,
                                node_num_array::Union{Tuple{Int,Real},Array{Int,1}},
                                source::Int,
                                target::Int,
                                plot_flag::Bool=false,
                                file_name::String="grid_shortest_path.png")
    @assert length(node_num_array) == 2

    shortest_path = yen_k_shortest_paths(graph, source, target)
    dists = shortest_path.dists[1];  # 複数ある可能性があるが、一旦1番目のものだけ
    paths = shortest_path.paths[1];  # 複数ある可能性があるが、一旦1番目のものだけ
    locs_x = Array{Float64, 1}(
        vcat([i for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    locs_y = Array{Float64, 1}(
        vcat([j for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    colors = [colorant"lightgray" for i in 1:ne(graph)];
    node_piar = Vector{Tuple}(undef, length(paths) - 1);
    for (num, (i, j)) in enumerate(zip(paths[begin:end-1], paths[begin+1:end]))
        node_piar[num] = (i, j)
    end

    for (num, e) in enumerate(ordered_edges(graph))
        if (src(e), dst(e)) in node_piar
            colors[num] = colorant"orange"
        end
    end
    if plot_flag
        draw(
            PNG(file_name, 10cm, 10cm),
            gplot(SimpleGraph(graph), locs_x, locs_y,
                  nodelabel=1:prod(node_num_array),
                  edgestrokec=colors,
                  edgelabel=[e.weight for e in ordered_edges(graph)])
        )
    end
end


const node_num_array = [7, 7]

g = generate_grid(node_num_array, 1:10, true);
grid_yen_shortest_path(g, node_num_array, 1, nv(g), true)

"""
最短経路を探索する関数はあるものの、下記に対応する全pathを列挙する関数はなさそう?
GraphSet.set_universe(G.edges())
paths = GraphSet.paths(terminal1=(0,0), terminal2=(n-1,n-1))
len(paths) #パスの総数

count =0
for p in paths.min_iter(weight):
    count+=1
    if count>=10:
        break
    print(p)

plt.figure()
nx.draw(G, pos=pos,with_labels=False, node_size=100)
nx.draw(G, pos=pos,with_labels=False, node_size=100,
        edgelist=p,edge_color="red",width=10,alpha=0.3)
nx.draw_networkx_edge_labels(G,pos,edge_labels=weight)
plt.show()
参考
https://juliagraphs.org/LightGraphs.jl/latest/pathing/#Path-discovery-/-enumeration
all_simple_pathsが実装されれば対応する処理ができると思われる。
https://github.com/JuliaGraphs/LightGraphs.jl/pull/1540
function all_paths_count(g::AbstractGraph, source::Int)
    c = 0
    for i in 1:nv(g)
        if source == i
            continue
        end
        c += length(all_simple_paths(g, source, i))
    end
    return c / 2
end
的な
最長経路も同様
"""

function generate_random_complete_graph(n::Int,
                                        plot_flag::Bool=false,
                                        file_name::String="random_complete_graph.png")
    x = Dict(i => 100*rand(Float64) for i in 1:n)
    y = Dict(i => 100*rand(Float64) for i in 1:n)
    G = SimpleWeightedGraph(n)
    for i in 1:n
        p₁ = Point(x[i], y[i])
        for j in 1:n
            p₂ = Point(x[j], y[j])
            if j > i
                d = distance(p₁, p₂)
                add_edge!(G, i, j, d)
            end
        end
    end

    locs_x = collect(values(x))
    locs_y = collect(values(y))
    if plot_flag
        draw(
            PNG(file_name, 10cm, 10cm),
            gplot(SimpleGraph(G), # weightgraphは直接gplotに渡せない
                  locs_x, locs_y,
                  nodelabel=1:nv(G))
        )
    end
    return G, locs_x, locs_y
end

struct Point
    x::Float64
    y::Float64
end

function distance(p₁::Point, p₂::Point)
    sqrt((p₁.x - p₂.x)^2 + (p₁.y - p₂.y)^2)
end

G, locs_x, locs_y = generate_random_complete_graph(10, true)

function detect_cycle(g::AbstractGraph,
                      source::Int,
                      len::Int)
    [i for i in simplecycles_limited_length(g, len) if length(i) > len-1 && i[1] == source]
end


function cycle_plot(G::AbstractGraph,
                    source::Int,
                    len::Int,
                    locs_x::Vector,
                    locs_y::Vector,
                    file_name::String="cycle_plot.png")
    paths = detect_cycle(G, source, len)
    path = paths[rand(1:length(paths))] # 1つサンプル
    node_piar = Vector{Tuple}(undef, length(path));
    for (num, (i, j)) in enumerate(zip(path[begin:end-1], path[begin+1:end]))
        node_piar[num] = Tuple(sort([i, j]))
    end
    node_piar[end] = (path[begin], path[end])

    colors = [colorant"lightgray" for i in 1:ne(G)];
    for (num, e) in enumerate(ordered_edges(G))
        if (src(e), dst(e)) in node_piar
            colors[num] = colorant"orange"
        end
    end
    draw(
        PNG(file_name, 10cm, 10cm),
        gplot(SimpleGraph(G), # weightgraphは直接gplotに渡せない
              locs_x, locs_y,
              edgestrokec=colors,
              nodelabel=1:nv(G))
    )
end

cycle_plot(G, 1, 4, locs_x, locs_y)

"""
Hamilton閉路もないっす。
"""
```


