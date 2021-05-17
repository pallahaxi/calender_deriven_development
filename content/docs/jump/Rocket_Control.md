---
title: "Rocket Control"
date: 2021-05-13T12:06:47+09:00
summary: "非線形最適化を用いてロケット制御問題を解くチュートリアルです"
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
# Rocket Control
Originally Contributed by: Iain Dunning

本チュートリアルでは非線形最適化を用いてロケット制御問題をどのように解くかを解説します。
この「ロケット制御問題」は[COPS3](https://www.mcs.anl.gov/~more/cops/cops3.pdf)の10章にある「Goddard Rocket」として紹介されている問題と同じパラメータを利用します。

本問題のゴールは「垂直に打ち上げられたロケットの最高高度を最大化」することです。

本チュートリアルの設定ではコントロール可能な1パラメータとして「ロケットの推進力」があり、ロケットの質量・燃料の消費量(消費率)・重力・空気抵抗などを考慮しつつ最高高度の最大化を目指します。

ロケット制御に含まれるパラメータや詳細については[CPOS3のPDF](https://www.mcs.anl.gov/~more/cops/cops3.pdf)を参照してください。

### Overview
ロケット制御のモデル化を記述するにあたり、刻々と変化する時間を固定値 {{< katex >}}n{{< /katex >}} で離散化させタイムステップとして取り扱います。

つまり離散化する固定値 {{< katex >}}n{{< /katex >}} と観測する最終時間 {{< katex >}}t_f{{< /katex >}} を用いることで、 {{< katex >}}t_f = n \cdot \Delta t{{< /katex >}} と記述します。

### State and Control
ロケットの状態を記載するため下記の3つの変数を導入します。
- {{< katex >}}v{{< /katex >}} : 速度
- {{< katex >}}h{{< /katex >}} : 高度
- {{< katex >}}m{{< /katex >}} : ロケットと残燃料を合わせた質量

また本チュートリアルでコントロール可能な1パラメータである推進力を {{< katex >}}T{{< /katex >}} とします。

さらに本問題で最大化したい高度を {{< katex >}}h(t_f){{< /katex >}} とします。

### Dynamics
ロケット制御を考える上で力学で用いる運動方程式から、下記の3方程式を得ます。
- 上昇率: {{< katex >}}h^\prime = v{{< /katex >}}
- 加速度: {{< katex >}}v^\prime = \frac{T - D(h,v)}{m} - g(h){{< /katex >}}
- 質量の変化率: {{< katex >}}m^\prime = -\frac{T}{c}{{< /katex >}}

チュートリアルでは上記について説明が少なく、不親切だと思ったので補足します。  
今回鉛直上向きの1軸しか考えず、上昇率は鉛直上向きの単位時間あたりの移動距離を指すのでロケットの速度に他なりません。  
加速度については高校物理で習う運動方程式 {{< katex >}}ma = F{{< /katex >}} から得られます。ロケットに作用する力は鉛直上向きにロケット自身の推進力 {{< katex >}}T{{< /katex >}} が存在し、鉛直下向きに質量と重力加速度 {{< katex >}}g(h){{< /katex >}} の積で得られる重力 {{< katex >}}mg(h){{< /katex >}} と空気抵抗 {{< katex >}}D(h, v){{< /katex >}} が存在します。つまり高校物理で習う運動方程式に合わせて記述すると {{< katex >}}m v^\prime = T - D(h, v) - mg(h){{< /katex >}} となります。ここで {{< katex >}}g(h){{< /katex >}} が高度 {{< katex >}}h{{< /katex >}} に依存するのは地球から離れるため重力加速度が小さくなるためです。また {{< katex >}}D(h, v){{< /katex >}} は速度 {{< katex >}}v{{< /katex >}} に依存するのは高校物理で習う通りで、高度 {{< katex >}}h{{< /katex >}} に依存するのは高所では空気が薄くなるためです。  
最後の方程式では今回 {{< katex >}}c{{< /katex >}} を定数として最適化問題を解きます。つまり質量の変化率はロケットの推進力が比例関係にあることを指しており、質量と速度が同時に変化するロケットのような系を考えると自然と得られます。  
またここで導入した空気抵抗 {{< katex >}}D(h, v){{< /katex >}} と重力加速度 {{< katex >}}g(h){{< /katex >}} は下記の式に従います。
{{< katex display >}}
\begin{aligned}
D(h,v) &= D_c v^2 \exp\left[ -h_c \left( \frac{h-h(0)}{h(0)} \right) \right],\\
g(h) &= g_0 \left( \frac{h(0)}{h} \right)^2
\end{aligned}
{{< /katex >}}

地上での重力加速度 {{< katex >}}g_0{{< /katex >}} と高度の初期値 {{< katex >}}h(0){{< /katex >}} と {{< katex >}}D_c, h_c{{< /katex >}} は定数として扱われます。

実際にコーディングに移ります。

```julia
using JuMP
import Ipopt
import Plots
```

それぞれパッケージのバージョンは
```
Ipopt v0.6.5
JuMP v0.21.8
Plots v1.14.0
```
を利用しています。

ソルバーとしてIpoptを使用し、JuMPのモデルを作成します。

```julia
rocket = Model(Ipopt.Optimizer)
set_silent(rocket)
```

## Constants
{{< katex >}}h(0) = m(0) = g_0 = 1{{< /katex >}} の単位系をとることでこれまでの定式化の物理量を全て無次元に整理することができます。
今回はそれぞれ全パラメータにCOPS3の数値を用います。

```julia
h_0 = 1    # Initial height
v_0 = 0    # Initial velocity
m_0 = 1    # Initial mass
g_0 = 1    # Gravity at the surface

T_c = 3.5  # Used for thrust
h_c = 500  # Used for drag
v_c = 620  # Used for drag
m_c = 0.6  # Fraction of initial mass left at end

c     = 0.5 * sqrt(g_0 * h_0)  # Thrust-to-fuel mass
m_f   = m_c * m_0              # Final mass
D_c   = 0.5 * v_c * m_0 / g_0  # Drag scaling
T_max = T_c * g_0 * m_0        # Maximum thrust

n = 800    # Time steps
```

## Decision variables
本問題での変数の定義域を定義します。
```julia
@variables(rocket, begin
    Δt ≥ 0, (start = 1/n) # Time step
    # State variables
    v[1:n] ≥ 0            # Velocity
    h[1:n] ≥ h_0          # Height
    m_f ≤ m[1:n] ≤ m_0    # Mass
    # Control variables
    0 ≤ T[1:n] ≤ T_max    # Thrust
end)
```

## Objective
本問題の目的変数は高度 {{< katex >}}h{{< /katex >}} の最大化であり、下記のように設定します。

```julia
@objective(rocket, Max, h[n])
```

## Initial conditions
```julia
fix(v[1], v_0; force = true)
fix(h[1], h_0; force = true)
fix(m[1], m_0; force = true)
fix(m[n], m_f; force = true)
```

## Forces
```julia
@NLexpressions(rocket, begin
    # Drag(h,v) = Dc v^2 exp( -hc * (h - h0) / h0 )
    drag[j = 1:n], D_c * (v[j]^2) * exp(-h_c * (h[j] - h_0) / h_0)
    # Grav(h)   = go * (h0 / h)^2
    grav[j = 1:n], g_0 * (h_0 / h[j])^2
    # Time of flight
    t_f, Δt * n
end)
```

## Dynamics
```julia
for j in 2:n
    # h' = v
    # Rectangular integration
    # @NLconstraint(rocket, h[j] == h[j - 1] + Δt * v[j - 1])
    # Trapezoidal integration
    @NLconstraint(rocket, h[j] == h[j - 1] + 0.5 * Δt * (v[j] + v[j - 1]))
    # v' = (T-D(h,v))/m - g(h)
    # Rectangular integration
    # @NLconstraint(
    #     rocket,
    #     v[j] == v[j - 1] + Δt *((T[j - 1] - drag[j - 1]) / m[j - 1] - grav[j - 1])
    # )
    # Trapezoidal integration
    @NLconstraint(
        rocket,
        v[j] == v[j-1] +
            0.5 * Δt * (
                (T[j    ] - drag[j    ] - m[j    ] * grav[j    ]) / m[j    ] +
                (T[j - 1] - drag[j - 1] - m[j - 1] * grav[j - 1]) / m[j - 1]
            )
    )
    # m' = -T/c
    # Rectangular integration
    # @NLconstraint(rocket, m[j] == m[j - 1] - Δt * T[j - 1] / c)
    # Trapezoidal integration
    @NLconstraint(rocket, m[j] == m[j - 1] - 0.5 * Δt * (T[j] + T[j-1]) / c)
end
```

これまでに設計したモデルが完成したので、最適解を求める。

```julia
println("Solving...")
status = optimize!(rocket)
```

## Display results
```julia
println("Max height: ", objective_value(rocket))
```
```
Max height: 1.0128340648308016
```

可視化
```julia
function my_plot(y, ylabel)
    return Plots.plot(
        (1:n) * value.(Δt),
        value.(y)[:];
        xlabel = "Time (s)",
        ylabel = ylabel,
    )
end

Plots.plot(
    my_plot(h, "Altitude"),
    my_plot(m, "Mass"),
    my_plot(v, "Velocity"),
    my_plot(T, "Thrust");
    layout = (2, 2),
    legend = false,
    margin = 1Plots.cm,
)
```
{{< figure src="/docs/jump/static/Rocket_Control/results.png" title="" >}}
