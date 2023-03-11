# Basic tests for prob/test.jl problems
# Verify for code errors, not correctnesss

@testset "run_strg_ops" begin
    case = PowerModels.parse_file("./networks/case5_strg.m")
    result_strg_ops = PowerModelsWildfire._run_strg_ops(case, PowerModels.DCPPowerModel, milp_solver)
    @test result_strg_ops["termination_status"] == OPTIMAL

    result_strg_ops = PowerModelsWildfire._run_strg_ops(case, PowerModels.SOCWRPowerModel, minlp_solver)
    @test result_strg_ops["termination_status"] == LOCALLY_SOLVED

    result_strg_ops = PowerModelsWildfire._run_strg_ops(case, PowerModels.ACPPowerModel, minlp_solver)
    @test result_strg_ops["termination_status"] == LOCALLY_SOLVED
end

@testset "run_strg_mops" begin
    case = PowerModels.parse_file("./networks/case5_strg.m")
    n = 3
    case["risk_weight"]=0.3
    case_mn = PowerModels.replicate(case, n)

    result_strg_mops = PowerModelsWildfire._run_strg_mops(case_mn, PowerModels.DCPPowerModel, milp_solver)
    @test result_strg_mops["termination_status"] == OPTIMAL

    result_strg_mops = PowerModelsWildfire._run_strg_mops(case_mn, PowerModels.SOCWRPowerModel, minlp_solver)
    @test result_strg_mops["termination_status"] == LOCALLY_SOLVED

    result_strg_mops = PowerModelsWildfire._run_strg_mops(case_mn, PowerModels.ACPPowerModel, minlp_solver)
    @test result_strg_mops["termination_status"] == LOCALLY_SOLVED
end

@testset "_run_normalized_ops" begin
    case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
    result_normalized_ops = PowerModelsWildfire._run_normalized_ops(case, PowerModels.DCPPowerModel, milp_solver)
    @test result_normalized_ops["termination_status"] == OPTIMAL

    result_normalized_ops = PowerModelsWildfire._run_normalized_ops(case, PowerModels.SOCWRPowerModel, minlp_solver)
    @test result_normalized_ops["termination_status"] == LOCALLY_SOLVED

    result_normalized_ops = PowerModelsWildfire._run_normalized_ops(case, PowerModels.ACPPowerModel, minlp_solver)
    @test result_normalized_ops["termination_status"] == LOCALLY_SOLVED
end

@testset "_run_threshold_ops" begin
    case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
    case["threshold"]=0.9
    result_thresh_ops = PowerModelsWildfire._run_threshold_ops(case, PowerModels.DCPPowerModel, milp_solver)
    @test result_thresh_ops["termination_status"] == OPTIMAL

    result_thresh_ops = PowerModelsWildfire._run_threshold_ops(case, PowerModels.SOCWRPowerModel, minlp_solver)
    @test result_thresh_ops["termination_status"] == LOCALLY_SOLVED

    result_thresh_ops = PowerModelsWildfire._run_threshold_ops(case, PowerModels.ACPPowerModel, minlp_solver)
    @test result_thresh_ops["termination_status"] == LOCALLY_SOLVED
end

