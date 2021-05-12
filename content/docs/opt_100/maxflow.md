---
title: "最大流問題"
date: 2021-05-06T21:13:59+09:00
summary: "最大流問題に対する定式化とアルゴリズム"
draft: false
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: true
categories: [""]
tags: [""]
---
# 最大流問題

```julia
using Cairo
using Colors
using Compose
using GraphPlot
using LightGraphs
using LightGraphsFlows
using SimpleWeightedGraphs

const lg = LightGraphs
```

## 最大流問題
次に考えるネットワーク上の最適化問題は、最大流問題である。  

あなたは富士山を統括する大名だ。
いま、あなたは猛暑で苦しんでいる江戸の庶民にできるだけたくさんの富士山名物の氷を送ろうと思っている。
氷を運ぶには特別な飛脚を使う必要があるので、地点間の移動可能量には限りがあり、その上限は以下のようになっている。
さて、どのように氷を運べば最も多くの氷を江戸の庶民に運ぶことができるだろうか。

```julia
function generate_digraph(plot_flag::Bool=false,
                          file_name::String="digraph.png")
    G = SimpleWeightedDiGraph(5)
    capacity = Dict((1, 2) => 5, (1, 3) => 8, (2, 5) => 8,
                    (3, 2) => 2, (3, 4) => 5, (4, 5) => 6)
    for (e, w) in capacity
        add_edge!(G, e[1], e[2], w)
    end
    pos = [0. 1.; 1. 0.; 1. 2.; 2. 2.; 2. 0.]
    locs_x = pos[:, 1]
    locs_y = pos[:, 2]
    if plot_flag
        draw(
            PNG(file_name, 13cm, 8cm),
            gplot(G,
                  locs_x, locs_y,
                  nodelabel=1:nv(G),
                  edgelabel=[e.weight for e in edges(G)])
        )
    end
    return G
end
```
```julia
G = generate_digraph(true);
```
{{< figure src="/docs/opt_100/static/maxflow/digraph.png" title="" >}}

最大流問題は、最短路問題と並んでネットワーク理論もっとも基本的な問題のひとつであり、水や車などをネットワーク上に流すという直接的な応用の他にも、スケジューリングから分子生物学にいたるまで多種多様な応用をもつ。

最短路問題の目的は、ある尺度を最適にする「パス（路）」を求めることであったが、最大流問題や最小費用流問題の目的は、ある尺度を最適にする「**フロー(流)**」を求めることである。

最大流問題を、グラフ・ネットワークの用語を使って定義しておこう。

## 最大流問題（maximum flow problem）
{{< katex >}}n{{< /katex >}} 個の点から構成される点集合 {{< katex >}}V{{< /katex >}} および {{< katex >}}m{{< /katex >}} 本の枝から構成される枝集合 {{< katex >}}E{{< /katex >}}、 {{< katex >}}V{{< /katex >}} と {{< katex >}}E{{< /katex >}} から成る有向グラフ {{< katex >}}G=(V,E){{< /katex >}}、 枝上に定義される非負の容量関数 {{< katex >}}u: E \rightarrow \mathbf{R}_+{{< /katex >}} 、 始点 {{< katex >}}s \in V{{< /katex >}} および終点 {{< katex >}}t \in V{{< /katex >}} が与えられたとき、始点 {{< katex >}}s{{< /katex >}} から終点 {{< katex >}}t{{< /katex >}} までの「フロー」で、その量が最大になるものを求めよ。

上の問題の定義を完結させるためには、「フロー」を厳密に定義する必要がある。

**フロー**（flow）とは枝上に定義された実数値関数 {{< katex >}}x: E \rightarrow \mathbf{R}{{< /katex >}} で、以下の性質を満たすものを指す。

- フロー整合条件:
{{< katex display >}}
\sum_{j: ji \in E} x_{ji} - \sum_{j: ij \in E} x_{ij} =0 \ \ \ \forall i \in V \setminus \{s,t\}
{{< /katex >}}
- 容量制約と非負制約:
{{< katex display >}}
0 \leq x_{e} \leq u_{e} \ \ \ \forall e \in E
{{< /katex >}}

各点 {{< katex >}}i \in V{{< /katex >}} に対して関数 {{< katex >}}f_x(i){{< /katex >}} を

{{< katex display >}}
f_x(i) = \sum_{j: ji \in E} x_{ji} - \sum_{j: ij \in E} x_{ij}
{{< /katex >}}

と定義する。
これはフローを表すベクトル {{< katex >}}x{{< /katex >}} によって定まる量であり、点 {{< katex >}}i{{< /katex >}} に入ってきた量 {{< katex >}}\sum_{j: ji \in E} x_{ji}{{< /katex >}} から出ていく量 {{< katex >}}\sum_{j: ij \in E} x_{ij}{{< /katex >}} を減じた値であるので、フロー {{< katex >}}x{{< /katex >}} の点 {{< katex >}}i{{< /katex >}} における**超過**(excess)とよばれる。

最大の値をもつフロー {{< katex >}}x{{< /katex >}} を求めることが最大流問題の目的である。
最大流問題を線形最適化問題として定式化すると以下のようになる。
{{< katex display >}}
\begin{array}{l l} maximize & f_x(t) \\ s.t. & f_x(i) =0 \ \ \ \forall i \in V \setminus \{s,t\} \\ & 0 \leq x_{e} \leq u_{e} \ \ \ \forall e \in E \end{array}
{{< /katex >}}

上記の最適化をJuliaでは `LightGraphsFlows.jl` で解く。
`LightGraphsFlows.jl` ではいくつかの最大流問題を解くためのアルゴリズムを提供しており、 `maximum_flow` 関数に渡すことで最適化を行う。
デフォルトでは [`PushRelabelAlgorithm`](https://juliagraphs.org/LightGraphsFlows.jl/latest/maxflow.html#LightGraphsFlows.push_relabel) が採用される。
さらにpythonのnetworkxが提供している `maximum_flow` 関数ではグラフオブジェクト自体がエッジの重みを持つことを前提としているため、capacityは指定しなくても良いが、 `LightGraphsFlows.jl` の `maximum_flow` 関数では明示的にcapacityを渡す仕様となっている。

```julia
value, flow = maximum_flow(DiGraph(G), 1, 5, weights(G))
println("value: $value")
println("flow: \n$flow")
```
returnされるオブジェクトの内容はnetworkxと同様のものであり、下記のように出力される。
```julia
value: 12.0
flow: 

   ⋅    5.0   7.0    ⋅    ⋅ 
 -5.0    ⋅   -2.0    ⋅   7.0
 -7.0   2.0    ⋅    5.0   ⋅ 
   ⋅     ⋅   -5.0    ⋅   5.0
   ⋅   -7.0    ⋅   -5.0   ⋅ 
```
上記、最大流問題を解いた結果を可視化すると
```julia
new_G = SimpleWeightedDiGraph(flow.*(flow .> 0))
# flow.*(flow .> 0)はedgeのダブルカウントを防ぐ処理。
pos = [0. 1.; 1. 0.; 1. 2.; 2. 2.; 2. 0.]
locs_x = pos[:, 1]
locs_y = pos[:, 2]
draw(
    PNG("maxflow_graph.png", 13cm, 8cm),
    gplot(new_G,
          locs_x, locs_y,
          nodelabel=1:nv(new_G),
          edgelabel=[e.weight for e in edges(new_G)])
)
```
{{< figure src="/docs/opt_100/static/maxflow/maxflow_graph.png" title="" >}}
となる。

# 最小カット問題
始点 {{< katex >}}s{{< /katex >}} を含み、終点 {{< katex >}}t{{< /katex >}} を含まない点の部分集合 {{< katex >}}S{{< /katex >}} を考える。
{{< katex >}}S{{< /katex >}} から出て {{< katex >}}S{{< /katex >}} 以外の点に向かう枝の集合を**カット**(cut)とよび、
{{< katex display >}}
\delta(S) = \{ (u,v)~|~(u,v) \in E, u \in S, v \not\in S \}
{{< /katex >}}
と書くことにする。カットに含まれる枝の容量の合計をカット容量とよぶ。

始点 {{< katex >}}s{{< /katex >}} から終点 {{< katex >}}t{{< /katex >}} までは、(どんなにがんばっても)カット容量より多くのフローを流すことはできないので、カット容量はフロー量の上界を与えることがわかる。

すべての可能なカットに対して、カット容量を最小にするものを求める問題は、**最小カット問題**(minimum cut problem)とよばれる。

最大流問題と最小カット問題には、以下の関係（最大フロー・最小カット定理）がある。

最大のフロー量と最小のカット容量は一致する。

`LightGraphsFlows.jl` が用意している最小カット問題を解くための関数では最大フロー問題を解くための関数とは異なり、デフォルトで採用されるアルゴリズムがない。
そのため下記のように明示的にアルゴリズムを渡す必要がある。
```julia
part₁, part₂, value = LightGraphsFlows.mincut(DiGraph(G), 1, 5, weights(G), EdmondsKarpAlgorithm())
println("part₁: $part₁")
println("part₂: $part₂")
println("value: $value")
```
出力結果としては
```julia
part₁: [1, 3]
part₂: [2, 4, 5]
value: 12.0
```
となる。
確かに本ページの最初のフロー図にて `1, 5` をそれぞれ含むノードの組み合わせ集合の中で `[1, 3]` と `[2, 4, 5]` の集合をカットするフローが最小フローとなっている。


また `LightGraphsFlows.jl` の `maximum_flow` 関数や `mincut` 関数は `AbstractFlowAlgorithm` の下部構造を引数として渡すことで最適化アルゴリズムを切り替えられる。
その最適解を得るためのアルゴリズムをいくつか用意しているものの、現在のところドキュメントに記載がない。
下記のソースコードをから読み取って切り替えを試してもらいたい。
- [`LightGraphsFlows.jl`](https://github.com/JuliaGraphs/LightGraphsFlows.jl/blob/master/src/LightGraphsFlows.jl) の最下部にてexportしている
- [`maxmun_flow.jl`](https://github.com/JuliaGraphs/LightGraphsFlows.jl/blob/master/src/maximum_flow.jl) にて `AbstractFlowAlgorithm` やその他のアルゴリズムが定義されている
- [`README.md`](https://github.com/JuliaGraphs/LightGraphsFlows.jl) 内でいくつかのアルゴリズムのスイッチ方法の例がある

現在確認できるアルゴリズムは下記の通りである。
- `EdmondsKarpAlgorithm`
- `DinicAlgorithm`
- `BoykovKolmogorovAlgorithm`
- `PushRelabelAlgorithm`
- `KishimotoAlgorithm`
- `ExtendedMultirouteFlowAlgorithm`

基本的には[Max flow algorighms](https://juliagraphs.org/LightGraphsFlows.jl/latest/maxflow.html)内で紹介されている関数と対応はしていると見られる。
