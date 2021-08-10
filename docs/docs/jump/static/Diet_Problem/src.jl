using JuMP
import GLPK
import Test


function print_solution(is_optimal, foods, buy)
    println("結果:")
    if is_optimal
        for food in foods
            println("  $(food) = $(value(buy[food]))")
        end
    else
        println("ソルバーは最適解を見つけられませんでした。")
    end
end


function example_diet(; verbose = true)
    # 栄養基準のガイドライン
    categories = ["calories", "protein", "fat", "sodium"]
    category_data = Containers.DenseAxisArray(
        [
         1800 2200;
         91   Inf;
         0    65;
         0    1779
        ],
        categories,
        ["min", "max"]
    )
    Test.@test category_data["protein", "min"] == 91.0
    Test.@test category_data["sodium", "max"] == 1779.0

    # 食事
    foods = [
        "hamburger", "chicken", "hot dog", "fries", "macaroni", "pizza",
        "salad", "milk", "ice cream",
    ]
    cost = Containers.DenseAxisArray(
        [2.49, 2.89, 1.50, 1.89, 2.09, 1.99, 2.49, 0.89, 1.59],
        foods
    )

    food_data = Containers.DenseAxisArray(
        [
            410 24 26 730;
            420 32 10 1190;
            560 20 32 1800;
            380  4 19 270;
            320 12 10 930;
            320 15 12 820;
            320 31 12 1230;
            100  8 2.5 125;
            330  8 10 180
        ], foods, categories
    )
    Test.@test food_data["hamburger", "calories"] == 410.0
    Test.@test food_data["milk", "fat"] == 2.5

    # モデル構築
    model = Model(GLPK.Optimizer)
    @variables(model, begin
        # 栄養素情報の変数
        category_data[c, "min"] <= nutrition[c = categories] <= category_data[c, "max"]
        # どの食事を購入するかの変数
        buy[foods] >= 0
    end)

    # 目的関数  コストの最小化
    @objective(model, Min, sum(cost[f] * buy[f] for f in foods))
    # 栄養素の制約
    @constraint(model, [c in categories],
        sum(food_data[f, c] * buy[f] for f in foods) == nutrition[c]
    )

    # 求解
    if verbose
        println("原題を求解中...")
    end
    optimize!(model)
    term_status = termination_status(model)
    is_optimal = term_status == MOI.OPTIMAL
    Test.@test primal_status(model) == MOI.FEASIBLE_POINT
    Test.@test objective_value(model) ≈ 11.8288 atol = 1e-4
    if verbose
        print_solution(is_optimal, foods, buy)
    end

    # 乳製品に制約を加える（実行不可能）
    @constraint(model, buy["milk"] + buy["ice cream"] <= 6)
    if verbose
        println("乳製品の制約を加えた問題を求解中...")
    end
    optimize!(model)
    Test.@test termination_status(model) == MOI.INFEASIBLE
    Test.@test primal_status(model) == MOI.NO_SOLUTION
    if verbose
        print_solution(false, foods, buy)
    end
    return
end

example_diet()
