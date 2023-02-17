@testset "Voltage Heuristic" begin
    case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
    result = PowerModelsWildfire.run_voltage_shutoff_heuristic(case, PowerModels.DCPPowerModel, milp_solver, risk_threshold=2.0);
    # @test result["termination_status"] == OPTIMAL  :: result is data dict, not a solution dict
    PowerModels.update_data!(case,result)

    @test isapprox(calc_total_risk(case), 20.45, atol=1e-4)
    @test isapprox(calc_load(case), 4.0, atol=1e-4)

    @test isapprox(case["branch"]["1"]["br_status"], 0, atol=1e-4)
    @test isapprox(case["branch"]["2"]["br_status"], 0, atol=1e-4)
    @test isapprox(case["branch"]["3"]["br_status"], 0, atol=1e-4)
    @test isapprox(case["branch"]["4"]["br_status"], 0, atol=1e-4)
    @test isapprox(case["branch"]["5"]["br_status"], 0, atol=1e-4)
    @test isapprox(case["branch"]["6"]["br_status"], 0, atol=1e-4)
end