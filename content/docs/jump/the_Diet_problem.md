---
title: "The Diet Problem"
date: 2021-08-10
summary: "線形最適化によって、栄養基準を満たす食事を求めるチュートリアルです。"
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
本記事は、JuMPのチュートリアル[The diet problem](https://jump.dev/JuMP.jl/stable/tutorials/linear/diet/)を解説したものです。  
オリジナルのチュートリアルには解説がないため、解説は当サイトが加えたものとなります。


# The Diet Problem
古典的な「栄養問題（diet problem; Stigler diet）」を解きます。
栄養問題は、全米研究評議会の定める食事摂取量基準を満たしつつ、最小限のコストとなる食事の組み合わせを求めるという、線形最適化問題の代表例です。

この問題の詳細や歴史的背景については[Wikipedia](https://en.wikipedia.org/wiki/Stigler_diet)に詳しい記載があります。
このチュートリアルで用いるデータ・解法は[Gurobiでの例](https://www.gurobi.com/documentation/9.0/examples/diet_cpp_cpp.html)をベースとしています。
コードの全容は[こちら(GitHub)](https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl)にあります。以降、コードを適宜抜粋しながら解説します。


まず、栄養基準を `category_data` に用意します。摂取すべき4つの栄養（カロリー、タンパク質、脂質、塩分）の上限値・下限値を定めています。  
例えば、タンパク質の摂取下限は91.0、塩分の摂取上限は1779.0です。  
値の確認に`Test`パッケージを使っていますが、説明は省略します。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=19:32&amp;footer=minimal"></script>

ここで利用している`Containers.DenseAxisArray`は、JuMPで利用できるデータ配列です。  
Julia標準の配列や`DataFrames`のデータフレームを用いることもできますが、チュートリアルに従い`Containers`を利用します。  
`DenseAxisArray`の引数には、順にデータ、第1軸（行）の軸ラベル、第2軸（列）の軸ラベルを与えており、データの呼び出しを容易にしています。


続いて、9種の食品の価格と栄養成分を用意します。 `cost`に費用を、`food_data`に栄養素を定義しています。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=34:59&amp;footer=minimal"></script>

必要なデータが用意できたところで、モデルの構築に移ります。

サンプルコードの通り、`@variables`マクロを用いることで複数の変数を同時に定義できます。
決定変数として、栄養の下限・上限を満たす値が入る`nutrition`と、どの食事を購入するかの`buy`を用意します。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=60:67&amp;footer=minimal"></script>

コストの最小化が目的となるため、それに合致した目的関数を定義します。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=69:70&amp;footer=minimal"></script>

それぞれの栄養素が基準値の範囲内かどうかという制約を加えます。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=71:74&amp;footer=minimal"></script>

複数のカテゴリに対する制約を一度に定義しています。  
第2引数にカテゴリ（`= c`）のリスト、第3引数にそのカテゴリ内での栄養素の合計がnutritionと同じになるというように表現しています。  

```category_data[c, "min"] <= sum(food_data[f, c] * buy[f] for f in foods) <= category_data[c, "max"]```
と同等の制約になります。


モデルの定義は以上です。モデルを求解するには`optimize`関数を利用します。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=79:82&amp;footer=minimal"></script>

モデルが解を得られたかどうかは、モデルのステータスから確認できます。  
ステータスは`termination_status`関数で確認することができ、解を得られている場合はスクリプトで別に定義している`print_solution`関数で表示できます。

ステータスの判定に`MOI`を利用しています。これはJuMPに含まれている`MathOptInterface`パッケージのオブジェクトです。
`MathOptInterface`は、数学的最適化ソルバーのための標準化されたAPIを提供します。JuMPのステータスもこれに従っているため、解が得られた（`MOI.OPTIMAL`）かどうかを判定することができます。

```
原題を求解中...
結果:
  hamburger = 0.6045138888888888
  chicken = 0.0
  hot dog = 0.0
  fries = 0.0
  macaroni = 0.0
  pizza = 0.0
  salad = 0.0
  milk = 6.9701388888888935
  ice cream = 2.591319444444441
```


それぞれのカテゴリについて、摂取量が表示されています。  
ほとんど牛乳から栄養を摂取すべき、という結果が得られていることがわかるかと思います。  
そこで、乳製品（牛乳・アイスクリーム）の摂取量に制約を加えて再度求解してみましょう。

<script src="https://gist-it.appspot.com/https://github.com/pallahaxi/calender_deriven_development/blob/master/content/docs/jump/static/Diet_Problem/src.jl?slice=89:99&amp;footer=minimal"></script>

```
乳製品の制約を加えた問題を求解中...
結果:
ソルバーは最適解を見つけられませんでした。
```

こちらは解を見つけられませんでした。用意された食事では、栄養のほとんどを牛乳で賄う必要があるようですね。
