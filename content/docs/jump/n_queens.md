---
title: "N-Queens"
date: 2021-10-12T20:40:39+09:00
summary: "Nクイーン問題を最適化問題としてときます"
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
# Nクイーン問題
Originally Contributed by: Matthew Helm

Nクイーン問題とは、{{< katex >}}N \times N{{< /katex >}} マスのチェス盤にN個のクイーンをお互いに取ることがでないよう配置する問題です。
例えば以下の図のような配置は4クイーン問題の解になります。
{{< figure src="https://jump.dev/JuMP.jl/stable/assets/n_queens4.png" title="JuMPチュートリアルより転載" >}}

チェスのクイーンは縦方向、横方向、斜め方向にどこまでも進むことが可能です。
そのため、この問題では与えられた盤面の各行、各列、各斜め列に1つのクイーンしか置くことができません。

それでは、実際のチェス盤と同様に {{< katex >}}8 \times 8 {{< /katex >}} について8クイーン問題を解いてみましょう。
{{< katex >}} 8 \times 8 {{< /katex >}} 行列を考えて、この行列の各成分をチェス盤に対応させます。
成分が1のときそのマスにはクイーンが置かれてある状態、0のときは駒がない状態を表すことで、この問題は整数計画問題となります。

```julia
using JuMP
import GLPK
import LinearAlgebra

# 8-Queens
N = 8
model = Model(GLPK.Optimizer)
```

変数を定義します。
上で述べたように変数はバイナリ値をとる {{< katex >}} 8 \times 8 {{< /katex >}} 行列 `x` です。
```julia
@variable(model, x[1:N, 1:N], Bin)
```
{{< figure src="/docs/jump/static/n_queens/variable.png" title="" >}}

制約条件を与えます。各行・各列には1つのクイーンしか置けないので、
```julia
# 各行・列でクイーンが唯一つ存在する
for i in 1:N
  @constraint(model, sum(x[i,:]) == 1)
  @constraint(model, sum(x[:,i]) == 1)
end
```

また、各斜め方向にも1つのクイーンしか置けないので、
```julia
# 任意の斜線にクイーンが唯一つ存在する
for i in -(N-1):(N-1)
  @constraint(model, sum(LinearAlgebra.diag(x,i)) <= 1)
  @constraint(model, sum(LinearAlgebra.diag(reverse(x, dims = 1), i)) <= 1)
end
```

制約条件はこれだけなので、解を求めます。
```julia
optimize!(model)
```

得られた解を見てみます。
```julia
solution = convert.(Int, value.(x))
```
{{< figure src="/docs/jump/static/n_queens/solution1.png" title="" >}}

この解をチェス盤で表示するとこれに対応します。
{{< figure src="https://jump.dev/JuMP.jl/stable/assets/n_queens.png" title="JuMPチュートリアルより転載" >}}

8クイーン問題には92種類の異なる解が存在します(らしいです)。
再び解を `optimize!` で求め直すと別の解が得られます。

{{< figure src="/docs/jump/static/n_queens/solution2.png" title="" >}}
