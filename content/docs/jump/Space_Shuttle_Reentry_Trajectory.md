---
title: "Space Shuttle Reentry Trajectory"
date: 2021-05-12T23:09:28+09:00
summary: "非線形計画問題としてのスペースシャトルの軌道再突入計算"
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
# Space Shuttle Reentry Trajectory
This tutorial demonstrates how to compute a reentry trajectory for the Space Shuttle, by formulating and solving a nonlinear programming problem. The problem was drawn from Chapter 6 of "Practical Methods for Optimal Control and Estimation Using Nonlinear Programming", by John T. Betts.

{{< hint info >}}
**Tips**  
This tutorial is a more-complicated version of the Rocket Control example. If you are new to solving nonlinear programs in JuMP, you may want to start there instead.
{{< /hint >}}

{{< katex display >}}
\begin{aligned}
\dot{h} & = v \sin \gamma , \\
\dot{\phi} & = \frac{v}{r} \cos \gamma \sin \psi / \cos \theta , \\
\dot{\theta} & = \frac{v}{r} \cos \gamma \cos \psi , \\
\dot{v} & = -\frac{D}{m} - g \sin \gamma , \\
\dot{\gamma} & = \frac{L}{m v} \cos(\beta) + \cos \gamma \left ( \frac{v}{r} - \frac{g}{v} \right ) , \\
\dot{\psi} & = \frac{1}{m v \cos \gamma} L \sin(\beta) + \frac{v}{r \cos \theta} \cos \gamma \sin \psi \sin \theta , \\
q & \le q_U , \\
\end{aligned}
{{< /katex >}} 

{{< katex display >}}
\begin{aligned}
     h & \quad \text{altitude (ft)},     \qquad & & \gamma \quad \text{flight path angle (rad)}, \\
  \phi & \quad \text{longitude (rad)},   \qquad & & \psi   \quad \text{azimuth (rad)},           \\
\theta & \quad \text{latitude (rad)},    \qquad & & \alpha \quad \text{angle of attack (rad)},   \\
     v & \quad \text{velocity (ft/sec)}, \qquad & & \beta  \quad \text{bank angle (rad)}.
\end{aligned}
{{< /katex >}}

{{< katex display >}}
\begin{aligned}
           D & = \frac{1}{2} c_D S \rho v^2,                  \qquad & a_0 & = -0.20704, \\
           L & = \frac{1}{2} c_L S \rho v^2,                  \qquad & a_1 & =  0.029244, \\
           g & = \mu / r^2,                                   \qquad & \mu & =  0.14076539 \times 10^{17}, \\
           r & = R_e + h,                                     \qquad & b_0 & =  0.07854, \\
        \rho & = \rho_0 \exp[-h/h_r],                         \qquad & b_1 & = -0.61592  \times 10^{-2}, \\
      \rho_0 & = 0.002378,                                    \qquad & b_2 & =  0.621408 \times 10^{-3}, \\
         h_r & = 23800,                                       \qquad & q_r & =  17700 \sqrt{\rho} (0.0001 v)^{3.07}, \\
         c_L & = a_0 + a_1 \hat{\alpha},                      \qquad & q_a & =  c_0 + c_1 \hat{\alpha} + c_2 \hat{\alpha}^2 + c_3 \hat{\alpha}^3, \\
         c_D & = b_0 + b_1 \hat{\alpha} + b_2 \hat{\alpha}^2, \qquad & c_0 & =  1.0672181, \\
\hat{\alpha} & = 180 \alpha / \pi,                            \qquad & c_1 & = -0.19213774 \times 10^{-1}, \\
         R_e & = 20902900,                                    \qquad & c_2 & =  0.21286289 \times 10^{-3}, \\
           S & = 2690,                                        \qquad & c_3 & = -0.10117249 \times 10^{-5}.
\end{aligned}
{{< /katex >}}

{{< katex display >}}
\begin{aligned}
     h & = 260000 \text{ ft},  \qquad & v      & = 25600 \text{ ft/sec}, \\
  \phi & = 0      \text{ deg}, \qquad & \gamma & = -1    \text{ deg},    \\
\theta & = 0      \text{ deg}, \qquad & \psi   & = 90    \text{ deg}.
\end{aligned}
{{< /katex >}}

{{< katex display >}}
h = 80000 \text{ ft}, \qquad v = 2500 \text{ ft/sec}, \qquad \gamma = -5 \text{ deg}.
{{< /katex >}}

## Approach

We will use a discretized model of time, with a fixed number of discretized points, nn. The decision variables at each point are going to be the state of the vehicle and the controls commanded to it. In addition, we will also make each time step size \Delta tΔt a decision variable; that way, we can either fix the time step size easily, or allow the solver to fine-tune the duration between each adjacent pair of points. Finally, in order to approximate the derivatives of the problem dynamics, we will use either rectangular or trapezoidal integration.


{{< hint info >}}
Disclaimer
Do not try to actually land a Space Shuttle using this notebook! 😛 There's no mesh refinement going on, which can lead to unrealistic trajectories having position and velocity errors with orders of magnitude 10^410 ft and 10^210 ft/sec, respectively.
{{< /hint >}}


{{< hint info >}}
**Choose a good linear solver**  
Picking a good linear solver is extremely important to maximize the performance of nonlinear solvers. For the best results, it is advised to experiment different linear solvers.

For example, the linear solver MA27 is outdated and can be quite slow. MA57 is a much better alternative, especially for highly-sparse problems (such as trajectory optimization problems).
{{< /hint >}}


## Plotting the results
