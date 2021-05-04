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
using MetaGraphs
using SimpleWeightedGraphs
```

## 第k最短路
`LightGraphs.jl` にYenの第 {{< katex >}}k{{< /katex >}} 最短路のアルゴリズムが含まれている。これは、最短路を短い（費用の小さい）順に列挙してくれる。

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
と、最短ルートを1つ出力します。第{{< katex >}}k{{< /katex >}}最短経路を出力するには
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
同様のバグ([リンク](https://github.com/JuliaGraphs/LightGraphs.jl/issues/1505))が報告されている。同じ費用の経路がある場合に2度同じ経路が出力されてしまうというバグである。これらは `LightGraphs.jl` のサブモジュールである `SimpleWeightedGraphs.jl` の `rem_edge!` のバグ([リンク](https://github.com/JuliaGraphs/SimpleWeightedGraphs.jl/issues/66))に起因する。  
今回の原因となっている `SimpleWeightedgraphs` を避けて対応すれば良いので、以下のように実行する。
```julia
k = 5;
yen_state = yen_k_shortest_paths(SimpleGraph(g), 1, 25, weights(g), k);
for (p, d) in zip(yen_state.paths, yen_state.dists)
    println("path: $p, dists: $d")
end
```
下記のように期待する出力が得られる。
```julia
path: [1, 2, 7, 12, 17, 18, 19, 20, 25], dists: 33.0
path: [1, 2, 3, 4, 9, 14, 19, 20, 25], dists: 35.0
path: [1, 2, 7, 12, 13, 18, 19, 20, 25], dists: 35.0
path: [1, 2, 7, 12, 17, 18, 23, 24, 25], dists: 36.0
path: [1, 2, 7, 12, 17, 18, 19, 24, 25], dists: 37.0
```
同様に有効グラフの場合にも `SimpleDiGraph` でキャストして実行すれば良い。型に応じて多重ディスパッチで対応すれば `yen_k_shortest_paths` 関数のバグは修正できるはずである。
可視化と最短経路を同時に得るため、下記の関数を定義する。
```julia
function grid_yen_shortest_path(graph::SimpleWeightedGraph,
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
    node_piar = Set{Set}()
    for (num, (i, j)) in enumerate(zip(paths[k_path][begin:end-1],
                                       paths[k_path][begin+1:end]))
        push!(node_piar, Set([i, j]))
    end

    if plot_flag
        for (num, e) in enumerate(ordered_edges(graph))
            if Set([src(e), dst(e)]) in node_piar
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
現在のところGraphillionのようにパスの列挙をする関数は用意されていないようである。
一方、 `networkx` の `all_simple_paths` に対応する関数のプルリクが挙がっている。  
https://github.com/JuliaGraphs/LightGraphs.jl/pull/1540

もし `all_simple_paths` が実装されれば対応する処理ができると思われる。
```julia
# !!実装されていない関数であり、下記の関数は動きません!!
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
```
同様に、最長経路に関する関数も現在のところ用意されていない。

## 閉路の列挙
閉路の列挙には `simplecycles_limited_length` 関数を用いる。
まず閉路の列挙のため、新規でグラフを生成する。

```julia
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
```

```julia
G, locs_x, locs_y = generate_random_complete_graph(10, true);
```
{{< figure src="/docs/opt_100/static/short_path_enum/random_complete_graph.png" title="" class="center" >}}


`simplecycles_limited_length` 関数は下記のように利用する。
```julia
simplecycles_limited_length(G, 3)
```
{{< expand "出力結果" >}}
```julia
285-element Vector{Vector{Int64}}:
 [1, 2]
 [1, 2, 3]
 [1, 2, 4]
 [1, 2, 5]
 [1, 2, 6]
 [1, 2, 7]
 [1, 2, 8]
 [1, 2, 9]
 [1, 2, 10]
 [1, 3]
 [1, 3, 2]
 [1, 3, 4]
 [1, 3, 5]
 [1, 3, 6]
 [1, 3, 7]
 [1, 3, 8]
 [1, 3, 9]
 [1, 3, 10]
 [1, 4]
 [1, 4, 2]
 [1, 4, 3]
 [1, 4, 5]
 [1, 4, 6]
 [1, 4, 7]
 [1, 4, 8]
 [1, 4, 9]
 ⋮
 [6, 8, 7]
 [6, 8, 9]
 [6, 8, 10]
 [6, 9]
 [6, 9, 7]
 [6, 9, 8]
 [6, 9, 10]
 [6, 10]
 [6, 10, 7]
 [6, 10, 8]
 [6, 10, 9]
 [7, 8]
 [7, 8, 9]
 [7, 8, 10]
 [7, 9]
 [7, 9, 8]
 [7, 9, 10]
 [7, 10]
 [7, 10, 8]
 [7, 10, 9]
 [8, 9]
 [8, 9, 10]
 [8, 10]
 [8, 10, 9]
 [9, 10]
```
{{< /expand >}}
となる。第二引数以下で閉路が形成されるパスが列挙される。今回の場合、2または3ステップの閉路が列挙された。
完全グラフであるため、
{{< katex display >}}
{}_{10}C_{3} + {}_{10}C_{2} = 285
{{< /katex >}}

```julia
function detect_cycle(g::AbstractGraph,
                      source::Int,
                      len::Int)
    [i for i in simplecycles_limited_length(g, len) if length(i) > len-1 && i[1] == source]
end
```


```julia
function cycle_plot(G::AbstractGraph,
                    source::Int,
                    len::Int,
                    locs_x::Vector,
                    locs_y::Vector,
                    file_name::String="cycle_plot.png")
    paths = detect_cycle(G, source, len)
    path = paths[rand(1:length(paths))] # 1つサンプル
    node_piar = Set{Set}()
    for (num, (i, j)) in enumerate(zip(path[begin:end-1], path[begin+1:end]))
        push!(node_piar, Set([i, j]))
    end
    node_piar[end] = (path[begin], path[end])

    colors = [colorant"lightgray" for i in 1:ne(G)]
    for (num, e) in enumerate(ordered_edges(G))
        if Set([src(e), dst(e)]) in node_piar
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
```

```julia
cycle_plot(G, 1, 4, locs_x, locs_y)
```
{{< figure src="/docs/opt_100/static/short_path_enum/cycle_plot.png" title="" class="center" >}}

## Hamilton閉路
現在のところHamilton閉路を見つけるパッケージは作られていない。

# 多目的最短路問題
費用と時間の2つの重みをもつグラフに対して、意思決定者にとって便利な複数のパスを示す問題を考える。 これは、多目的最適化問題になる。

まず、多目的最適化の基礎と用語について述べる。

以下に定義される {{< katex >}}m{{< /katex >}} 個の目的をもつ多目的最適化問題を対象とする。

解の集合 {{< katex >}}X{{< /katex >}} ならびに {{< katex >}}X{{< /katex >}} から {{< katex >}}m{{< /katex >}} 次元の実数ベクトル全体への写像 {{< katex >}}f: X \rightarrow \mathbf{R}^m{{< /katex >}}が与えられている。
ベクトル {{< katex >}}f{{< /katex >}} を目的関数ベクトルとよび、その第 {{< katex >}}i{{< /katex >}} 要素を {{< katex >}}f_i{{< /katex >}} と書く。
ここでは、ベクトル {{< katex >}}f{{< /katex >}} を「何らかの意味」で最小にする解（の集合）を求めることを目的とする。

2つの目的関数ベクトル {{< katex >}}f,g\in \mathbf{R}^m{{< /katex >}} に対して、 {{< katex >}}f{{< /katex >}} と {{< katex >}}g{{< /katex >}} が同じでなく、かつベクトルのすべての要素に対して {{< katex >}}f{{< /katex >}} の要素が {{< katex >}}g{{< /katex >}} の要素以下であるとき、ベクトル {{< katex >}}f{{< /katex >}} がベクトル {{< katex >}}g{{< /katex >}} に優越しているとよび、 {{< katex >}}f \prec g{{< /katex >}} と記す。

すなわち、順序 {{< katex >}}\prec{{< /katex >}} を以下のように定義する。
{{< katex display >}}
f \prec g \Leftrightarrow f \neq g, f_i \leq g_i \ \ \ \forall i
{{< /katex >}}
たとえば、2つのベクトル {{< katex >}}f=(2,5,4)f=(2,5,4){{< /katex >}} と {{< katex >}}g=(2,6,8)g=(2,6,8){{< /katex >}} に対しては、第1要素は同じであるが、第2,3要素に対しては {{< katex >}}g{{< /katex >}} の方が大きいので {{< katex >}}f \prec g{{< /katex >}} である。

2つの解 {{< katex >}}x,y{{< /katex >}} に対して、{{< katex >}}f(x) \prec f(y){{< /katex >}} のとき、解 {{< katex >}}x{{< /katex >}} は解 {{< katex >}}y{{< /katex >}} に優越していると呼ぶ。
以下の条件を満たすとき、 {{< katex >}}x{{< /katex >}} は **非劣解** (nondominated solution) もしくは **Pareto最適解** (Pareto optimal solution)と呼ばれる。
{{< katex display >}}
f(y) \prec f(x) を満たす解 y \in X は存在しない
{{< /katex >}}
多目的最適化問題の目的は、すべての非劣解(Pareto最適解)の集合を求めることである。
非劣解の集合から構成される境界は、 金融工学における株の構成比を決める問題（ポートフォリオ理論）では有効フロンティア(efficient frontier)と呼ばれる。
ポートフォリオ理論のように目的関数が凸関数である場合には、有効フロンティアは凸関数になるが、一般には非劣解を繋いだものは凸になるとは限らない。

非劣解の総数は非常に大きくなる可能性がある。 そのため、実際にはすべての非劣解を列挙するのではなく、 意思決定者の好みにあった少数の非劣解を選択して示すことが重要になる。

最も単純なスカラー化は複数の目的関数を適当な比率を乗じて 足し合わせることである。

{{< katex >}}m{{< /katex >}} 次元の目的関数ベクトルは、 {{< katex >}}m{{< /katex >}} 次元ベクトル {{< katex >}}\alpha{{< /katex >}} を用いてスカラー化できる。
通常、パラメータ {{< katex >}}\alpha{{< /katex >}} は
{{< katex display >}}
\sum_{i=1}^m \alpha_i =1
{{< /katex >}}
を満たすように正規化しておく。

この {{< katex >}}\alpha{{< /katex >}} を用いて重み付きの和をとることにより、 以下のような単一の（スカラー化された）目的関数 {{< katex >}}f_{\alpha}{{< /katex >}} に変換できる。
{{< katex display >}}
f_{\alpha}(x)= \sum_{i=1}^m \alpha_i f_i(x)
{{< /katex >}}
これを2目的の最短路問題に適用してみよう。格子グラフの枝に２つの重み（costとtime）を定義して、スカラー化を用いて、有効フロンティアを描画する。


まずは元サイトと同様のプロセスで格子状のグラフを作成する。各エッジに `:cost` と `:time` の属性を付与する。
```julia
const m, n = 100, 100;
const lb, ub = 1, 100;
mg = MetaGraph(grid([m, n]));
for e in edges(mg)
    set_prop!(mg, e, :cost, rand(lb:ub))
    set_prop!(mg, e, :time, 100/get_prop(mg, e, :cost))
end
```

最短経路を解くようにする
```julia
x, y = Vector{Int}(), Vector{Float64}()
for k in 0:99
    α = 0.01 * k
    for e in edges(mg)
        set_prop!(mg, e, :weight,
                  α * get_prop(mg, e, :cost) + (1 - α) * get_prop(mg, e, :time))
    end
    dijk = dijkstra_shortest_paths(mg, 1, weights(mg))
    cost, time = 0, 0.0
    j = 1
    for i in enumerate_paths(dijk, m * n)[begin+1:end]
        cost += get_prop(mg, Edge(j, i), :cost)
        time += get_prop(mg, Edge(j, i), :time)
        j = i
    end
    push!(x, cost)
    push!(y, time)
end
```
可視化
```julia
savefig(plot(x, y, line=(3, 0.6, :green), marker=(:circle, 5, 0.8, Plots.stroke(0), :green), legend=false),
        "efficient_frontier.png")
```
{{< figure src="/docs/opt_100/static/short_path_enum/efficient_frontier.png" title="" >}}

時間を測定するため関数化する。
```julia
using BenchmarkTools

function ef(input_graph::MetaGraph)
    x, y = Vector{Int}(), Vector{Float64}()
    for k in 0:99
        α = 0.01 * k
        for e in edges(input_graph)
            set_prop!(input_graph, e, :weight,
                      α * get_prop(input_graph, e, :cost) + (1 - α) * get_prop(input_graph, e, :time))
        end
        dijk = dijkstra_shortest_paths(input_graph, 1, weights(input_graph))
        cost::Int = 0
        time::Float64 = 0.0
        j = 1
        for i in enumerate_paths(dijk, m * n)[begin+1:end]
            cost += get_prop(input_graph, Edge(j, i), :cost)
            time += get_prop(input_graph, Edge(j, i), :time)
            j = i
        end
        push!(x, cost)
        push!(y, time)
    end
    return x, y
end

@benchmark ef(mg)
```
計測結果は
```bash
BenchmarkTools.Trial: 
  memory estimate:  3.69 GiB
  allocs estimate:  37869799
  --------------
  minimum time:     4.847 s (12.67% GC)
  median time:      4.921 s (13.22% GC)
  mean time:        4.921 s (13.22% GC)
  maximum time:     4.994 s (13.76% GC)
  --------------
  samples:          2
  evals/sample:     1
```

pythonでの時間の測定コードは下記となる。
```python
from time import time as t

start = t()
x, y =[],[]
for k in range(100):
    alpha = 0.01* k
    for (i,j) in G.edges():
        G[i][j]["weight"] = alpha*G[i][j]["cost"]+ (1-alpha)*G[i][j]["time"]

    pred, distance = nx.dijkstra_predecessor_and_distance(G, source=(0,0))
    #print("minimum cost=", distance[m-1,n-1])
    j = (m-1,n-1)
    cost = time = 0
    while i != (0,0):
        i = pred[j][0]
        cost += G[i][j]["cost"]
        time += G[i][j]["time"]
        j = i
    #print(cost,time)
    x.append(cost)
    y.append(time)
process_time = t() - start
print(process_time)
```
測定結果は
```bash
28.481345653533936
```
となった。およそ5倍と非常にJuliaのdijkstraアルゴリズムが高速であることがわかった。

## すべての単純パスを列挙するアルゴリズム
[上記]({{< ref "/docs/opt_100/short_path_enum.md#無向パス（閉路，森など）の列挙" >}})にもあるように、現在のところ `LightGraphs.jl` では `all_simple_paths` に対応する関数のプルリクが挙がっている。
