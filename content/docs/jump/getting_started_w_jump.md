---
title: "Getting Started W Jump"
date: 2021-08-24T20:42:37+09:00
summary: ""
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
JuMPのチュートリアル[Getting started with JuMP](https://jump.dev/JuMP.jl/stable/tutorials/Getting%20started/getting_started_with_JuMP/)を見ながら簡単なビンパッキング問題を解いたものを紹介します。該当ページとは異なる内容となりますが、Pythonの `PuLP` と比較しながら行います。

# 線形計画問題

まず非常に簡単な線形計画問題を1つ解いてみます。次の問題を考えます。

{{< figure src="/docs/jump/static/getting_started_w_jump/lp1.png" title="" >}}



## PuLP (Python)

    import pulp as pp
    
    # モデル定義
    model = pp.LpProblem(name='reidai', sense=pp.LpMaximize)
    
    # 決定変数を定義
    x1 = pp.LpVariable(name='x1', lowBound=0,
                       upBound=None, cat='Continuous')
    x2 = pp.LpVariable(name='x2', lowBound=0,
                       upBound=None, cat='Continuous')
    
    # 目的関数を実装
    model += 3*x1 + 2*x2
    
    # 制約条件
    model += 2*x1 + 5*x2 <= 500
    model += 4*x1 + 2*x2 <= 300
    
    # 解を求める
    model.solve()
    print(f"x1={x1.value()}, x2={x2.value()}")
    print(f"売上={model.objective.value()}")

結果はこのようになります。
{{< figure src="/docs/jump/static/getting_started_w_jump/lp1_py.png" title="" >}}


## JuMP (Julia)

ここではソルバーとして `GLPK` パッケージの `GLPK.Optimizer` を使います。制約条件に名前をつけることが可能で、それぞれ `c1, c2` とします。

    using JuMP
    using GLPK
    
    # モデル定義
    model = Model(GLPK.Optimizer)
    
    # 決定変数を定義
    @variable(model, x1 >= 0)
    @variable(model, x2 >= 0)
    
    # 目的関数を実装
    @objective(model, Max, 3x1 + 2x2)
    
    # 制約条件
    @constraint(model, c1, 2x1 + 5x2 <= 500)
    @constraint(model, c2, 4x1 + 2x2 <= 300)
    
    # 解を求める
    optimize!(model)
    @show value(x1)
    @show value(x2)
    @show objective_value(model)

ちなみに、 `print(model)` でモデルとして設定した情報を見ることができます。
{{< figure src="/docs/jump/static/getting_started_w_jump/printmodel.png" title="" >}}
結果はこの通りです。
{{< figure src="/docs/jump/static/getting_started_w_jump/lp1_jl.png" title="" >}}


# ビンパッキング問題(整数計画問題)

{{< figure src="/docs/jump/static/getting_started_w_jump/lip1.png" title="" >}}

問題文：

> 重さが w\_i (i=1~10) のアイテムが10個ある。これを最大10個の箱の中に詰め込むことを考えたい。1つの箱には10kgまでしかアイテムが詰められない時、使用する箱の数を最小にするアイテムの組み合わせと、使用した箱の数を求めよ。

この時 y\_i = {0,1} がi番目の箱を使用したか否か、 x<sub>ij</sub> = {0,1} がi番目の箱にj番目のアイテムを入れたか否か、という2値変数になります。
線形計画問題の例題と異なり、決定変数が行列で表記されています。私がJuliaで好きな点として、数式で書かれているものをそのまま(とまでは言いませんが)プログラムとして記述できるという特徴があるのですが、このような問題が与えられたときに、Pythonと比較してコードの形に翻訳する努力が少なくて済みます。
逆に言えば、この辺りをすぐにコードとしてイメージできる人からすると、Juliaに違和感を感じるところなのかもしれません。

## PuLP (Python)

    model2 = pp.LpProblem(name='bin_packing', sense=pp.LpMinimize)
    N_PRODUCT = 10
    N_BOX = 10
    
    # 決定変数
    x = pp.LpVariable.dicts('x',
                            [(i,j) for i in range(N_BOX) for j in range(N_PRODUCT)],
                            cat='Binary')
    y = pp.LpVariable.dicts('y', range(N_BOX), cat='Binary')
    
    weight = [3,5,7,4,8,8,6,9,6,5]
    
    # 目的関数
    model2 += pp.lpSum(y[i] for i in range(N_BOX))
    
    # 制約条件
    for i in range(N_BOX):
        model2 += pp.lpSum(x[(i,j)]*weight[j] for j in range(N_PRODUCT)) <= 10*y[i]
    for j in range(N_PRODUCT):
        model2 += pp.lpSum(x[(i,j)] for i in range(N_BOX)) == 1
    
    model2.solve()
    
    for key in x.keys():
        if x[key].value() == 1:
            print(f"x{key}:{x[key].value()}")
    print(f"y = {[y[i].value() for i in range(N_BOX)]}")
    print(f"Objective value = {model2.objective.value()}")

{{< figure src="/docs/jump/static/getting_started_w_jump/lip1_py.png" title="" >}}
どの箱を選ぶか、というところに不定性はあると思いますが、同一の箱に詰め込むアイテムの組み合わせと7個の箱を使用する、という最小値が求まりました。

## JuMP (Julia)

    using JuMP
    using GLPK
    
    # モデル定義
    model2 = Model(GLPK.Optimizer)
    
    # 定数
    const N_PRODUCT = 10
    const N_BOX = 10
    const weight = [3,5,7,4,8,8,6,9,6,5]
    
    # 決定変数を定義
    @variable(model2, x[1:N_BOX, 1:N_PRODUCT], Bin)
    @variable(model2, y[1:N_BOX], Bin)
    
    # 目的関数を実装
    @objective(model2, Min, sum(y))
    
    # 制約条件
    @constraint(model2, x * weight .<= 10y)
    @constraint(model2, sum(x, dims=1) .== 1) # dims=1 で行列xᵢⱼ のiについて和を取る
    
    # 解を求める
    optimize!(model2)
    @show findall(value.(x) .== 1.0)
    @show value.(y)
    @show objective_value(model2)

Pythonとの大きな違いは次の2つかと思います。

-   決定変数を定義
    Pythonでは行列の変数をタプル `(i,j)` を key とした辞書として作成しましたが、Juliaでは行列を変数として扱うことができます。
-   制約条件
    Juliaでは連立不等式を行列とベクトルの積として表すことができ、数式からのコーディングを直感的に行うことができます。

結果を見てみます。行列の全成分を見るのは大変なので、 x の値が1になる成分を呼び出してみます。
{{< figure src="/docs/jump/static/getting_started_w_jump/value_x.png" title="" >}}
次に y の成分を確認します。
{{< figure src="/docs/jump/static/getting_started_w_jump/value_y.png" title="" >}}
数えてみると、使われた箱の数が7個であることがわかります。

箱の中に1つだけ入っているものはどうでもいいとして、同一の箱に入った組み合わせをPython、Juliaそれぞれで確認してみると、

-   Python
    -   箱2:(1,9)
    -   箱3:(3,8)
    -   箱4:(0,2)
-   Julia
    -   箱3:(4,9)
    -   箱4:(1,3)
    -   箱8:(2,10)

となりました。Juliaの方は番号が0からではなく1から開始することを考慮すると、きちんと一致していることがわかります。
