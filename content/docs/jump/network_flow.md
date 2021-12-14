---
title: "Network Flow"
date: 2021-06-29T20:46:02+09:00
summary: "ネットワークのフロー問題"
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
# Network Flow
Originally Contributed by: Arpit Bhatia

グラフ理論において、フローネットワーク(輸送ネットワークとしても知られています)は各辺が容量を持つ有向グラフで表現され、各辺における各容量を超える量のフローを流さないように最適化を行う手法です。

数理最適化の文脈では
- 有効グラフ -> ネットワーク
- 頂点(vertex) -> 節点(node)
- 辺(edges) -> 弧(arc)

という言葉も使われます。

フローの考え方では、sourceと呼ばれるフローの流出だけをする頂点とsinkと呼ばれる流入だけをする頂点以外の頂点では各頂点におけるフローの流入量と流出量を一致させて最適化を行います。

このネットワークの考え方はコンピュータネットワークの通信制御や、パイプ内の流体、回路内の電流など、ネットワーク内の頂点間で何らかのやりとりがされるモデルの記述に用いられる概念です。

```julia
using JuMP
import GLPK
import LinearAlgebra
```

## The Shortest Path Problem
本問題では各弧 {{< katex >}}(i, j){{< /katex >}} にスカラー値であるコスト {{< katex >}}a_{i, j}{{< /katex >}} と呼ばれる量が与えられており、任意の2頂点を繋ぐコストの合計を経路のコストとします。

また、ここで定めた2頂点を繋ぐコストの最小値を求める問題が最短経路問題になります。

{{< katex display >}}
\begin{aligned}
\min & \sum_{\forall e(i,j) \in E} a_{i,j} \times x_{i,j}\\
\text{s.t.} &\quad b(i) = \sum_j x_{ij} - \sum_k x_{ki} =
\begin{cases}
1 &\text{if}\ i\ \text{is the starting node(source),} \\
-1 &\text{if}\ i\ \text{is the ending node(sink),} \\
0 &\text{otherwise.}
\end{cases}\\
& \quad x_{e} \in \{0, 1\} \qquad \forall e \in E
\end{aligned}
{{< /katex >}}


今回考えるネットワークを隣接行列 {{< katex >}}G{{< /katex >}} で表現します。
この {{< katex >}}G{{< /katex >}} に基づくバイナリ変数を定義します。ここでは [リンク1](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_JuMP/#Arrays) と [リンク2](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_JuMP/#Binary-variables) を組み合わせることで変数を定義します。

```julia
G = [
    0 100 30  0  0;
    0   0 20  0  0;
    0   0  0 10 60;
    0  15  0  0 50;
    0   0  0  0  0;
]

n = size(G)[1]

shortest_path = Model(GLPK.Optimizer)

@variable(shortest_path, x[1:n,1:n], Bin)
```
```
5×5 Array{VariableRef,2}:
 x[1,1]  x[1,2]  x[1,3]  x[1,4]  x[1,5]
 x[2,1]  x[2,2]  x[2,3]  x[2,4]  x[2,5]
 x[3,1]  x[3,2]  x[3,3]  x[3,4]  x[3,5]
 x[4,1]  x[4,2]  x[4,3]  x[4,4]  x[4,5]
 x[5,1]  x[5,2]  x[5,3]  x[5,4]  x[5,5]
```

さらに隣接行列 {{< katex >}}G{{< /katex >}} に従い制約式を宣言します。まず、弧が存在しないエッジ(`G == 0`)にはゼロコストを制約として課します。

```julia
@constraint(shortest_path, [i = 1:n, j = 1:n; G[i,j] == 0], x[i,j] == 0)
```
```
JuMP.Containers.SparseAxisArray{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, ScalarShape}, 2, Tuple{Int64, Int64}} with 18 entries:
  [3, 1]  =  x[3,1] = 0.0
  [2, 5]  =  x[2,5] = 0.0
  [1, 4]  =  x[1,4] = 0.0
  [5, 5]  =  x[5,5] = 0.0
  [3, 2]  =  x[3,2] = 0.0
  [3, 3]  =  x[3,3] = 0.0
  [4, 1]  =  x[4,1] = 0.0
  [2, 1]  =  x[2,1] = 0.0
  [1, 5]  =  x[1,5] = 0.0
  [5, 1]  =  x[5,1] = 0.0
  [2, 2]  =  x[2,2] = 0.0
  [4, 3]  =  x[4,3] = 0.0
  [4, 4]  =  x[4,4] = 0.0
  [2, 4]  =  x[2,4] = 0.0
  [1, 1]  =  x[1,1] = 0.0
  [5, 2]  =  x[5,2] = 0.0
  [5, 3]  =  x[5,3] = 0.0
  [5, 4]  =  x[5,4] = 0.0
```

さらに各節点に関してフローの保存則を下記のように宣言します(sourceとsinkを除く)。

```julia
@constraint(
    shortest_path,
    [i = 1:n; i != 1 && i != 2],
    sum(x[i,:]) == sum(x[:,i])
)
```
```
JuMP.Containers.SparseAxisArray{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, ScalarShape}, 1, Tuple{Int64}} with 3 entries:
  [5]  =  x[5,1] + x[5,2] + x[5,3] + x[5,4] - x[1,5] - x[2,5] - x[3,5] - x[4,5] = 0.0
  [4]  =  x[4,1] + x[4,2] + x[4,3] - x[1,4] - x[2,4] - x[3,4] - x[5,4] + x[4,5] = 0.0
  [3]  =  x[3,1] + x[3,2] - x[1,3] - x[2,3] - x[4,3] - x[5,3] + x[3,4] + x[3,5] = 0.0
```

最後にsourceとsinkに対する制限を宣言します。  
まずsourceに関する制約は下記のようになります。

```julia
@constraint(shortest_path, sum(x[1,:]) - sum(x[:,1]) == 1)
```
```
-x[2,1] - x[3,1] - x[4,1] - x[5,1] + x[1,2] + x[1,3] + x[1,4] + x[1,5] = 1.0
```

上記で宣言した制約は下記の式のような制約と対応します。
{{< katex display >}}
−x_{2,1} −x_{3,1} −x_{4,1} −x_{5,1} +x_{1,2} +x_{1,3} +x_{1,4} +x_{1,5} =1.0
{{< /katex >}}

sourceと同様にsinkに対する制約を下記のように宣言します。

```julia
@constraint(shortest_path, sum(x[2,:]) - sum(x[:,2]) == -1)
```
```
x[2,1] - x[1,2] - x[3,2] - x[4,2] - x[5,2] + x[2,3] + x[2,4] + x[2,5] = -1.0
```

制約の宣言は以上となります。  

最後に目的関数を宣言します。

```julia
@objective(shortest_path, Min, LinearAlgebra.dot(G, x))
```

ここまでのモデルを最適化します。

```julia
optimize!(shortest_path)
objective_value(shortest_path)
```

最小化問題最適化の結果、下記のような有向グラフで表現されるネットワークが得られました。

```julia
value.(x)
```
```
5×5 Matrix{Float64}:
 0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0
 0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
```

## The Assignment Problem

一対一でマッチングさせなければならない人 {{< katex >}}n{{< /katex >}} と物 {{< katex >}}n{{< /katex >}} を考えます。
人 {{< katex >}}i{{< /katex >}} と物 {{< katex >}}j{{< /katex >}} をマッチングさせることで得られる収益 {{< katex >}}a_{i,j}{{< /katex >}} があり、その収益の合計が最大になるように人と物を割り当てたいとします。

また、人 {{< katex >}}i{{< /katex >}} を物 {{< katex >}}j{{< /katex >}} に割り当てることができるのは、 {{< katex >}}(i, j){{< /katex >}} があるペアの集合 {{< katex >}}A{{< /katex >}} に属するときだけという制約があります。

数学的には、物 {{< katex >}}j_{1},\ldots,j_{n}{{< /katex >}} がすべて異なるような、人と物のペア {{< katex >}}(1, j_{1}),\ldots, (n, j_{n}){{< /katex >}} の集合を {{< katex >}}A{{< /katex >}} から見つけ、
総利益 {{< katex >}}\sum_{i=1}^{y} a_{ij_{i}}{{< /katex >}} が最大になるようにします。

{{< katex display >}}
\begin{aligned}
\max && \sum_{(i,j) \in A} a_{i,j} \times y_{i,j} \\
s.t. && \sum_{\{j|(i,j) \in A\}} y_{i,j} = 1 && \forall i = \{1,2....n\} \\
&& \sum_{\{i|(i,j) \in A\}} y_{i,j} = 1 && \forall j = \{1,2....n\} \\
&& y_{i,j} \in \{0,1\} && \forall (i,j) \in \{1,2...k\}
\end{aligned}
{{< /katex >}}


```julia
G = [
    6 4 5 0
    0 3 6 0
    5 0 4 3
    7 5 5 5
]

n = size(G)[1]

assignment = Model(GLPK.Optimizer)
@variable(assignment, y[1:n, 1:n], Bin)
```
```
4×4 Array{VariableRef,2}:
 y[1,1]  y[1,2]  y[1,3]  y[1,4]
 y[2,1]  y[2,2]  y[2,3]  y[2,4]
 y[3,1]  y[3,2]  y[3,3]  y[3,4]
 y[4,1]  y[4,2]  y[4,3]  y[4,4]
```

上記の元で一人に対し一つの物をアサインします。

```julia
@constraint(assignment, [i = 1:n], sum(y[:, i]) == 1)
```
```
4-element Array{ConstraintRef{Model,MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64},MathOptInterface.EqualTo{Float64}},ScalarShape},1}:
 y[1,1] + y[2,1] + y[3,1] + y[4,1] = 1.0
 y[1,2] + y[2,2] + y[3,2] + y[4,2] = 1.0
 y[1,3] + y[2,3] + y[3,3] + y[4,3] = 1.0
 y[1,4] + y[2,4] + y[3,4] + y[4,4] = 1.0
```

逆に一つの物に一人しかアサインできない制約を追加します。  
その上で、最大化問題を解かせます。

```julia
@constraint(assignment, [j = 1:n], sum(y[j, :]) == 1)
@objective(assignment, Max, LinearAlgebra.dot(G, y))

optimize!(assignment)
objective_value(assignment)
```
```
20.0
```
結果下記のようなネットワークが算出されました。
```julia
value.(y)
```
```
4×4 Array{Float64,2}:
 0.0  1.0  0.0  0.0
 0.0  0.0  1.0  0.0
 1.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0
```

## The Max-Flow Problem
最大流問題では本ページのはじめにある、コストの最小値を求める問題が最短経路問題と同様、source( {{< katex >}}s{{< /katex >}} )とsink( {{< katex >}}t{{< /katex >}} )が存在します。

最適化の目的関数は、容量制限を守りながら、 {{< katex >}}s{{< /katex >}} から {{< katex >}}t{{< /katex >}} にできるだけ多くのフローを流すことです。

{{< katex display >}}
\begin{aligned}
\max && \sum_{v:(s,v) \in E} f(s,v) \\
s.t. && \sum_{u:(u,v) \in E} f(u,v)  = \sum_{w:(v,w) \in E} f(v,w) && \forall v \in V - \{s,t\} \\
&& f(u,v) \leq c(u,v) && \forall (u,v) \in E \\
&& f(u,v) \geq 0 && \forall (u,v) \in E
\end{aligned}
{{< /katex >}}

```julia
G = [
    0 3 2 2 0 0 0 0
    0 0 0 0 5 1 0 0
    0 0 0 0 1 3 1 0
    0 0 0 0 0 1 0 0
    0 0 0 0 0 0 0 4
    0 0 0 0 0 0 0 2
    0 0 0 0 0 0 0 4
    0 0 0 0 0 0 0 0
]

n = size(G)[1]

max_flow = Model(GLPK.Optimizer)

@variable(max_flow, f[1:n, 1:n] >= 0)
```
```
8×8 Array{VariableRef,2}:
 f[1,1]  f[1,2]  f[1,3]  f[1,4]  f[1,5]  f[1,6]  f[1,7]  f[1,8]
 f[2,1]  f[2,2]  f[2,3]  f[2,4]  f[2,5]  f[2,6]  f[2,7]  f[2,8]
 f[3,1]  f[3,2]  f[3,3]  f[3,4]  f[3,5]  f[3,6]  f[3,7]  f[3,8]
 f[4,1]  f[4,2]  f[4,3]  f[4,4]  f[4,5]  f[4,6]  f[4,7]  f[4,8]
 f[5,1]  f[5,2]  f[5,3]  f[5,4]  f[5,5]  f[5,6]  f[5,7]  f[5,8]
 f[6,1]  f[6,2]  f[6,3]  f[6,4]  f[6,5]  f[6,6]  f[6,7]  f[6,8]
 f[7,1]  f[7,2]  f[7,3]  f[7,4]  f[7,5]  f[7,6]  f[7,7]  f[7,8]
 f[8,1]  f[8,2]  f[8,3]  f[8,4]  f[8,5]  f[8,6]  f[8,7]  f[8,8]
```

ネットワークの容量に関する制約を下記のように課します。

```julia
@constraint(max_flow, [i = 1:n, j = 1:n], f[i, j] <= G[i, j])
```
```
8×8 Array{ConstraintRef{Model,MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64},MathOptInterface.LessThan{Float64}},ScalarShape},2}:
 f[1,1] ≤ 0.0  f[1,2] ≤ 3.0  f[1,3] ≤ 2.0  f[1,4] ≤ 2.0  f[1,5] ≤ 0.0  f[1,6] ≤ 0.0  f[1,7] ≤ 0.0  f[1,8] ≤ 0.0
 f[2,1] ≤ 0.0  f[2,2] ≤ 0.0  f[2,3] ≤ 0.0  f[2,4] ≤ 0.0  f[2,5] ≤ 5.0  f[2,6] ≤ 1.0  f[2,7] ≤ 0.0  f[2,8] ≤ 0.0
 f[3,1] ≤ 0.0  f[3,2] ≤ 0.0  f[3,3] ≤ 0.0  f[3,4] ≤ 0.0  f[3,5] ≤ 1.0  f[3,6] ≤ 3.0  f[3,7] ≤ 1.0  f[3,8] ≤ 0.0
 f[4,1] ≤ 0.0  f[4,2] ≤ 0.0  f[4,3] ≤ 0.0  f[4,4] ≤ 0.0  f[4,5] ≤ 0.0  f[4,6] ≤ 1.0  f[4,7] ≤ 0.0  f[4,8] ≤ 0.0
 f[5,1] ≤ 0.0  f[5,2] ≤ 0.0  f[5,3] ≤ 0.0  f[5,4] ≤ 0.0  f[5,5] ≤ 0.0  f[5,6] ≤ 0.0  f[5,7] ≤ 0.0  f[5,8] ≤ 4.0
 f[6,1] ≤ 0.0  f[6,2] ≤ 0.0  f[6,3] ≤ 0.0  f[6,4] ≤ 0.0  f[6,5] ≤ 0.0  f[6,6] ≤ 0.0  f[6,7] ≤ 0.0  f[6,8] ≤ 2.0
 f[7,1] ≤ 0.0  f[7,2] ≤ 0.0  f[7,3] ≤ 0.0  f[7,4] ≤ 0.0  f[7,5] ≤ 0.0  f[7,6] ≤ 0.0  f[7,7] ≤ 0.0  f[7,8] ≤ 4.0
 f[8,1] ≤ 0.0  f[8,2] ≤ 0.0  f[8,3] ≤ 0.0  f[8,4] ≤ 0.0  f[8,5] ≤ 0.0  f[8,6] ≤ 0.0  f[8,7] ≤ 0.0  f[8,8] ≤ 0.0
```

次にフローの保存則を下記のように課します。  
その上で、最大化問題を解かせます。


```julia
@constraint(max_flow, [i = 1:n; i != 1 && i != 8], sum(f[i, :]) == sum(f[:, i]))
@objective(max_flow, Max, sum(f[1, :]))

optimize!(max_flow)
objective_value(max_flow)
```
```
6.0
```
結果下記のようなネットワークが算出されました。

```julia
value.(f)
```
```
8×8 Array{Float64,2}:
 0.0  3.0  2.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  3.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  4.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  2.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
```
