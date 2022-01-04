---
title: "Portfolio Optimization"
date: 2021-12-07T20:15:51+09:00
summary: "非線形最適化を用いてポートフォリオ最適化問題を解くチュートリアルです"
draft: true
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: true
categories: [""]
tags: [""]
---

# Portfolio Optimzation
Originally Contributed by: Arpit Bhatia

最適化モデルは、金融上の意思決定において驚くほど重要な役割を果たします。
最新の最適化技術を用いて、多くの計算機上のファイナンスにおける問題を効率的に解くことができます。

このチュートリアルでは、 Markowitz Portfolio Optimization問題を解きます。
データの出典は[Shabir Ahmedによる学習コースのレクチャーノート](https://www2.isye.gatech.edu/~sahmed/isye6669/)です。

チュートリアルでは以下のパッケージを使用します。

```julia
using JuMP
import Ipopt
import Statistics
```

１ヶ月間、100ドルを3種の無配当株であるIBM(IBM), Walmart(WMT), Southern Electric(SEHI)に投資することを考えます。

初期投資額を用いて3種の株を現在の価格で購入し、月末に取得株をその時の価格で売却します。
合理的な投資家であれば、この投資にいくらかの利益を得ることを望むはずです。
例えば、月末の収支がプラスになっていることなどが想像できるでしょう。

月初の購入額を{{< katex >}}p{{< /katex >}}、月末の売却額を{{< katex >}}s{{< /katex >}}とすると、
株保有によるある月の利益は{{< katex >}}\frac{s-p}{p}{{< /katex >}}ということになります。

株価は極めて不確かなものなので、月末の収支はどうなっているかもわかりません。
月末の期待利益として50ドル（出資額の5%）をゴールとします。
また、臨んだ利益を得られない「リスク」を最小限に止めることも重要視します。

この問題を解く上で、3つの仮定をおきます。

1. 株価はどのような値でも取引できる
2. 空売りは不可能
3. 取引コストはかからない


それでは、定式化に移ります。

決定変数として {{< katex >}}x_i, i = \{1, 2, 3\}{{< /katex >}} を用います。それぞれの株に充てる金額を表します。

{{< katex >}}\tilde{r}_{i}{{< /katex >}}は、株{{<katex>}}i{{</katex>}}の月ごとの利益を表す乱数です。

したがって、株{{<katex>}}i{{</katex>}}に{{<katex>}}x_{i}{{</katex>}}だけ投資した場合の利益は
{{<katex>}}\tilde{r}_{i} x_{i}{{</katex>}}となり、合計の利益は{{<katex>}}\sum^{3}_{i=1} \tilde{r}_{i} x_{i}{{</katex>}}となります。

{{<katex>}}\tilde{r}_{i}{{</katex>}}は乱数であるため、期待値{{<katex>}}\bar{r}_{i}{{</katex>}}を考えます。

{{<katex display>}}
\mathbb{E} \Biggl[ \sum^{3}_{i=1} \tilde{r}_{i} x_{i} \Biggr] = \sum^{3}_{i=1} \bar{r}_{i} x_{i}
{{</katex>}}

続いて、この投資に対する「リスク」を定量化します。
Markowitzによる研究では、リスクの最小化を即ち収益の分散の最小化として捉えています。

分散を次のように定義します。
{{<katex display>}}
\mathrm{Var} \Biggl[ \sum^{3}_{i=1} \tilde{r}_{i} x_{i} \Biggr] = \sum^{3}_{i=1}\sum^{3}_{j=1} x_{i} x_{j} \sigma_{ij}
{{</katex>}}


ここで、{{<katex>}}\sigma_{ij}{{</katex>}}は株{{<katex>}}i{{</katex>}}と株{{<katex>}}j{{</katex>}}の利益の共分散です。
利益ベクトル{{< katex >}}\tilde{r}{{< /katex >}}の分散共分散行列{{<katex>}}\bm{Q}{{</katex>}}を用いて分散を{{<katex>}}x^{T}\bm{Q}x{{</katex>}}と表すこともできます。

これらのデータを用いて定式化すると、

{{<katex display>}}
\begin{aligned}
    \mathrm{Min} x^{T}\bm{Q}x \\
    \mathrm{s.t.} \sum^{3}_{i=1} x_{i} \ge 1000.00 \\
    \bar{r}^{T}_{x} \le 50.00 \\
    x \le 0
\end{aligned}
{{</katex>}}


ここから実装に移ります。実際にJuMPを用いポートフォリオ最適化問題を解いてみましょう。

各株価の変動は以下の通りです。


| Month        |  IBM     |  WMT    |  SEHI  |
|--------------|----------|---------|--------|
| November-00  |  93.043  |  51.826 |  1.063 |
| December-00  |  84.585  |  52.823 |  0.938 |
| January-01   |  111.453 |  56.477 |  1.000 |
| February-01  |  99.525  |  49.805 |  0.938 |
| March-01     |  95.819  |  50.287 |  1.438 |
| April-01     |  114.708 |  51.521 |  1.700 |
| May-01       |  111.515 |  51.531 |  2.540 |
| June-01      |  113.211 |  48.664 |  2.390 |
| July-01      |  104.942 |  55.744 |  3.120 |
| August-01    |  99.827  |  47.916 |  2.980 |
| September-01 |  91.607  |  49.438 |  1.900 |
| October-01   |  107.937 |  51.336 |  1.750 |
| November-01  |  115.590 |  55.081 |  1.800 |

これを配列として持った `stock_data`と、利益ベクトル `stock_returns`とその共分散行列 `Q`を定義します。

```Julia
stock_data = [
    93.043 51.826 1.063
    84.585 52.823 0.938
    111.453 56.477 1.000
    99.525 49.805 0.938
    95.819 50.287 1.438
    114.708 51.521 1.700
    111.515 51.531 2.540
    113.211 48.664 2.390
    104.942 55.744 3.120
    99.827 47.916 2.980
    91.607 49.438 1.900
    107.937 51.336 1.750
    115.590 55.081 1.800
]

stock_returns = Array{Float64}(undef, 12, 3)
for i in 1:12
    stock_returns[i, :] =
        (stock_data[i+1, :] .- stock_data[i, :]) ./ stock_data[i, :]
end

r = Statistics.mean(stock_returns, dims = 1)
Q = Statistics.cov(stock_returns)
```

先ほどの定式化に沿ってモデルを宣言し、求解を行います。

目的関数で積をとるため、非線形な目的関数に対応したオプティマイザであるIpoptを使用します。

```Julia
portfolio = Model(Ipopt.Optimizer)
set_silent(portfolio)
@variable(portfolio, x[1:3] >= 0)
@objective(portfolio, Min, x' * Q * x)
@constraint(portfolio, sum(x) <= 1000)
@constraint(portfolio, sum(r[i] * x[i] for i in 1:3) >= 50)
optimize!(portfolio)

objective_value(portfolio)
```
```22634.41784988414```

収益の分散はおよそ22,634.4であることがわかります。

このとき、どの株をいくら購入すれば良いかは、変数 `x` を確認すれば良いです。

```Julia
value.(x)
```
```
3-element Vector{Float64}:
 497.04552984986407
   0.0
 502.9544801594808
```