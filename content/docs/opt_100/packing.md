---
title: "パッキング問題"
date: 2021-06-08T21:09:51+09:00
summary: "パッキング問題のいくつかの例について定式化とアルゴリズムを紹介"
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
https://mikiokubo.github.io/opt100/68packing.html

# ビンパッキング問題
ビンパッキング問題(bin packing problem; 箱詰め問題)は，以下のように定義される問題である．

{{< katex >}}n{{< /katex >}} 個のアイテムから成る有限集合 {{< katex >}}N{{< /katex >}} とサイズ {{< katex >}}B{{< /katex >}} のビンが無限個準備されている． 個々のアイテム {{< katex >}}i \in\mathbb{N}{{< /katex >}} のサイズ {{< katex >}}0\leq w_i \leq B{{< /katex >}} は分かっているものとする．これら {{< katex >}}n{{< /katex >}} 個のアイテムを，サイズ {{< katex >}}B{{< /katex >}} のビンに詰めることを考えるとき， 必要なビンの数を最小にするような詰めかたを求める問題．

ビンの数の上限 {{< katex >}}U{{< /katex >}} が与えられているものとする． アイテム {{< katex >}}i{{< /katex >}} をビン {{< katex >}}j{{< /katex >}} に詰めるとき1になる変数 {{< katex >}}x_{ij}{{< /katex >}} と，ビン {{< katex >}}j{{< /katex >}} の使用の可否を表す変数 {{< katex >}}y_j{{< /katex >}} を用いることによって，ビンパッキング問題は，以下の整数最適化問題として記述できる．

{{< katex display >}}
\begin{aligned}
{\rm minimize} \hspace{10pt} & \sum^U_{j=1}y_i \\
{\rm s.t.} \hspace{10pt} & \sum^U_{j=1}x_{ij} = 1 \quad \forall i \\
& \sum^n_{i=1}w_ix_{ij} \leq By_j \quad \forall j \\
& x_{ij} \leq y_j \quad \forall i,j \\
& x_{ij} \in {0,1} \quad \forall i,j \\
& y_j \in {0,1} \quad \forall j
\end{aligned}
{{< /katex >}}

```julia
using JuMP
import Ipopt
import Plots
```
