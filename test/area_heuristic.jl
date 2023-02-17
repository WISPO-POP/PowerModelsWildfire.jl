@testset "Area Heuristic" begin
    case = PowerModels.parse_file("./networks/case14_risk.m")
    result = PowerModelsWildfire.run_area_shutoff_heuristic(case, PowerModels.DCPPowerModel, milp_solver, risk_threshold=20.0);
    # @test result["termination_status"] == OPTIMAL :: result is data dict, not a solution dict
    PowerModels.update_data!(case,result)

    @test isapprox(calc_load(case), 2.59, atol=1e-4)

    ## Results from the MLD portion of the problem are degenerate, and can have different solutions on different systems.
    # @test isapprox(calc_total_risk(case), 56.2, atol=1e-4)

    # @test isapprox(case["branch"]["1"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["2"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["3"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["4"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["5"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["6"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["7"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["8"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["9"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["10"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["11"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["12"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["13"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["14"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["15"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["16"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["17"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["18"]["br_status"], 1, atol=1e-4)
    # @test isapprox(case["branch"]["19"]["br_status"], 0, atol=1e-4)
    # @test isapprox(case["branch"]["20"]["br_status"], 1, atol=1e-4)
end