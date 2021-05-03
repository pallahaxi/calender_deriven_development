---
title: "最短路の列挙"
date: 2021-05-02T18:00:30+09:00
summary: "第k最短路と `LightGraph.jl` による無向グラフの列挙と多目的最短路"
draft: false
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: true
---

# 最短経路の列挙

```julia
using Cairo
using Colors
using Compose
using GraphPlot
using GraphRecipes
using LightGraphs
using SimpleWeightedGraphs
```

## 第k最短路
`LightGraphs.jl` にYenの第 $k$ 最短路のアルゴリズムが含まれている。これは、最短路を短い（費用の小さい）順に列挙してくれる。

Jin Y. Yen, “Finding the K Shortest Loopless Paths in a Network”, Management Science, Vol. 17, No. 11, Theory Series (Jul., 1971), pp. 712-716.

まずは2次元格子状のネットワークを構築する。
```julia
function generate_grid(node_num_array::Union{Tuple{Int,Real},Array{Int,1}},
                       random_range::Union{UnitRange{<:Real}, Array{<:Real,1}}=1:10,
                       plot_flag::Bool=false,
                       file_name::String="grid.png")
    @assert length(node_num_array) == 2

    grid_graph = grid(node_num_array) # gridで格子状のエッジを構築
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
            gplot(SimpleGraph(g), # weightgraphは直接gplotに渡せないためSimpleGraph型にキャストする
                  locs_x, locs_y,
                  nodelabel=1:nv(g),
                  edgelabel=[e.weight for e in ordered_edges(g)])
        )
    end
    return g
end

# edgeの並びを整理する関数
function ordered_edges(graph::LightGraphs.AbstractGraph)
    edge_dict = Dict{Tuple{Int,Real}, Any}()
    for e in edges(graph)
        edge_dict[(src(e), dst(e))] = e
    end
    return values(sort(edge_dict))
end

const node_num_array = [5, 5]

const g = generate_grid(node_num_array, 1:10, true);
```
{{< figure src="/docs/opt_100/static/short_path_enum/grid.png" title="" class="center" >}}


ここで `LightGraph.jl` が用意している `edges` 関数が返す順序とグラフ可視化のための `gplot` 関数の `edgelabel` に渡す順序が一致しないことに注意する。
`edgelabel` ではlexicographic orderingに従う (https://github.com/JuliaGraphs/GraphPlot.jl/issues/70)。
そのため、ここではラベルの順序を一時的に整理する `orderd_edges` 関数を用意した。

Yenのアルゴリズムは下記のように呼び出す。
```julia
yen_k_shortest_paths(g, 1, 25)
```
出力としては
```julia
LightGraphs.YenState{Float64, Int64}([33.0], [[1, 2, 7, 12, 17, 18, 19, 20, 25]])
```
と、最短ルートを1つ出力します。第k最短経路を出力するには
```julia
k = 5;
yen_state = yen_k_shortest_paths(g, 1, 25, weights(g), k);
for (p, d) in zip(yen_state.paths, yen_state.dists)
    println("path: $p, dists: $d")
end
```
のように実行する。しかし、現在のところ何点か `yen_k_shortest_paths` 関数にはバグが存在する。実際、上記の実行結果では同じエッジがk回出力されてしまう。
```julia
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
```
これは `LightGraphs.jl` のサブモジュールである `SimpleWeightedGraphs.jl` の `rem_edge!` のバグ([リンク](https://github.com/JuliaGraphs/SimpleWeightedGraphs.jl/issues/66))に起因する。  
他にも同じ費用の経路がある場合、出力されないバグ([リンク](https://github.com/JuliaGraphs/LightGraphs.jl/issues/1505))などもあるようである。これは `yen_k_shortest_paths` 関数の[ソースコード](https://github.com/JuliaGraphs/LightGraphs.jl/blob/2a644c2b15b444e7f32f73021ec276aa9fc8ba30/src/shortestpaths/yen.jl)で使われている `dijkstra_shortest_paths` 関数で `allpaths=true` にせずエッジを全列挙し `.predecessors` から同じ重みのエッジを探索していない実装であることに起因する。  
今回、上記で例示した同じ経路がk回出力されてしまう問題だけに対応するため、以下のように実行する。
```julia
k = 5;
yen_state = yen_k_shortest_paths(SimpleGraph(g), 1, 25, weights(g), k);
for (p, d) in zip(yen_state.paths, yen_state.dists)
    println("path: $p, dists: $d")
end
```
下記の出力が得られる。
```julia
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 3, 4, 9, 14, 19, 20, 25], dists: 35.0
path: [1, 2, 7, 12, 13, 18, 19, 20, 25], dists: 35.0
path: [1, 2, 7, 12, 17, 18, 23, 24, 25], dists: 36.0
path: [1, 2, 7, 12, 17, 18, 19, 24, 25], dists: 37.0
```
可視化と最短経路を同時に得るため、下記の関数を定義する。
```julia
function grid_yen_shortest_path(graph::LightGraphs.AbstractGraph,
                                node_num_array::Union{Tuple{Int,Real},Array{Int,1}},
                                source::Int,
                                target::Int;
                                k_path::Int=1,
                                plot_flag::Bool=false,
                                file_name::String="grid_shortest_path.png")
    @assert length(node_num_array) == 2

    shortest_path = yen_k_shortest_paths(SimpleGraph(graph), source, target,
                                         weights(graph), k_path)
    dists = shortest_path.dists;
    paths = shortest_path.paths;
    @assert length(paths) >= k_path

    locs_x = Array{Float64, 1}(
        vcat([i for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    locs_y = Array{Float64, 1}(
        vcat([j for i in 1:node_num_array[1], j in 1:node_num_array[2]]...))
    colors = [colorant"lightgray" for i in 1:ne(graph)];
    node_piar = Vector{Tuple}(undef, length(paths[k_path]) - 1);
    for (num, (i, j)) in enumerate(zip(paths[k_path][begin:end-1],
                                       paths[k_path][begin+1:end]))
        node_piar[num] = (i, j)
    end

    if plot_flag
        for (num, e) in enumerate(ordered_edges(graph))
            if (src(e), dst(e)) in node_piar
                colors[num] = colorant"orange"
            end
        end

        draw(
            PNG(file_name, 10cm, 10cm),
            gplot(SimpleGraph(graph), locs_x, locs_y,
                  nodelabel=1:prod(node_num_array),
                  edgestrokec=colors,
                  edgelabel=[e.weight for e in ordered_edges(graph)])
        )
    end
    return dists, paths
end
```
```julia
d, p = grid_yen_shortest_path(g, node_num_array, 1, nv(g), k_path=1, plot_flag=true)
```
{{< figure src="/docs/opt_100/static/short_path_enum/grid_shortest_path.png" title="" class="center" >}}

この際の距離 `d` は `33.0` であった。さらに、第2最短経路の場合には下記のように実行する。
```julia
d, p = grid_yen_shortest_path(g, node_num_array, 1, nv(g), k_path=2, plot_flag=true, file_name="grid_shortest_path_second.png")
```
{{< figure src="/docs/opt_100/static/short_path_enum/grid_shortest_path_second.png" title="" class="center" >}}

この際の距離 `d[end]` は `35.0` であった。


## 無向パス（閉路，森など）の列挙

```julia
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
