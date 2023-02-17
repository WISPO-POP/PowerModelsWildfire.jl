@testset "OPS" begin
    @testset "DCPPowerModel OPS" begin
        case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
        result_ops = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, milp_solver);
        @test result_ops["termination_status"] == OPTIMAL

        PowerModels.update_data!(case,result_ops["solution"])

        @test isapprox(calc_total_risk(case), 24.5, atol=1e-4)
        @test isapprox(calc_load(case), 7.0, atol=1e-4)


        # check MLD for identical power delivery
        PowerModelsRestoration.clean_status!(result_ops["solution"])
        PowerModelsRestoration.update_status!(case, result_ops["solution"])
        result_mld = PowerModelsRestoration.run_mld(case, PowerModels.DCPPowerModel, milp_solver)
        @test result_mld["termination_status"] == OPTIMAL # verify mld solved before comparison
        @test isapprox(calc_load(result_mld["solution"]), calc_load(case), atol=1e-4)

    end

    @testset "ACPPowerModel OPS" begin
        case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
        result_ops = PowerModelsWildfire.run_ops(case, PowerModels.ACPPowerModel, minlp_solver);
        @test result_ops["termination_status"] == LOCALLY_SOLVED

        PowerModels.update_data!(case,result_ops["solution"])

        @test isapprox(calc_total_risk(case), 24.5, atol=1e-4)
        @test isapprox(calc_load(case), 6.9998, atol=1e-4)

        # check MLD for identical power delivery
        PowerModelsRestoration.clean_status!(result_ops["solution"])
        PowerModelsRestoration.update_status!(case, result_ops["solution"])
        result_mld = PowerModelsRestoration.run_mld(case, PowerModels.ACPPowerModel, minlp_solver)
        @test result_mld["termination_status"] == LOCALLY_SOLVED # verify mld solved before comparison
        @test isapprox(calc_load(result_mld["solution"]), calc_load(case), atol=1e-4)


    end

    @testset "SOCWRPowerModel OPS" begin
        case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
        result_ops = PowerModelsWildfire.run_ops(case, PowerModels.SOCWRPowerModel, minlp_solver);
        @test result_ops["termination_status"] == LOCALLY_SOLVED

        PowerModels.update_data!(case,result_ops["solution"])

        @test isapprox(calc_total_risk(case), 24.5, atol=1e-4)
        @test isapprox(calc_load(case), 6.9998, atol=1e-4)


        # check MLD for identical power delivery
        PowerModelsRestoration.clean_status!(result_ops["solution"])
        PowerModelsRestoration.update_status!(case, result_ops["solution"])
        result_mld = PowerModelsRestoration.run_mld(case, PowerModels.SOCWRPowerModel, minlp_solver)
        @test result_mld["termination_status"] == LOCALLY_SOLVED # verify mld solved before comparison
        @test isapprox(calc_load(result_mld["solution"]), calc_load(case), atol=1e-4)

    end

    @testset "test case5_risk_sys1 consistency" begin
        # sufficient gen on all load buses -> turn off all branches
        case = PowerModels.parse_file("./networks/case5_risk_sys1.m")
        result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL

        PowerModels.update_data!(case,result["solution"])

        @test isapprox(calc_total_risk(case), 24.6, atol=1e-4)
        @test isapprox(calc_load(case), 10.0, atol=1e-4)

        @test isapprox(case["branch"]["1"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["2"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["3"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["4"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["5"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["6"]["br_status"], 0, atol=1e-4)
    end

    @testset "test case5_risk_sys2 consistency" begin
        # standard case5 network
        case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
        result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL

        PowerModels.update_data!(case,result["solution"])

        @test isapprox(calc_total_risk(case), 24.5, atol=1e-4)
        @test isapprox(calc_load(case), 7.0, atol=1e-4)

        @test isapprox(case["branch"]["1"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["2"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["3"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["4"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["5"]["br_status"], 1, atol=1e-4)
        @test isapprox(case["branch"]["6"]["br_status"], 0, atol=1e-4)
    end

    @testset "test case14 consistency" begin
        # case14
        case = PowerModels.parse_file("./networks/case14_risk.m")
        result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL

        PowerModels.update_data!(case,result["solution"])

        @test isapprox(calc_total_risk(case), 38.16263269, atol=1e-4)
        @test isapprox(calc_load(case), 0.369533, atol=1e-4)

        @test isapprox(case["branch"]["1"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["2"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["3"]["br_status"], 1, atol=1e-4)
        @test isapprox(case["branch"]["4"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["5"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["6"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["7"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["8"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["9"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["10"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["11"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["12"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["13"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["14"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["15"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["16"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["17"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["18"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["19"]["br_status"], 0, atol=1e-4)
        @test isapprox(case["branch"]["20"]["br_status"], 0, atol=1e-4)
    end
    @testset "load weights"  begin
        case = PowerModels.parse_file("./networks/case14_risk.m")
        result1 = run_ops(case,PowerModels.DCPPowerModel,milp_solver)

        for (id,load) in case["load"]
            load["weight"]=rand()
        end
        result2 = run_ops(case,PowerModels.DCPPowerModel,milp_solver)

        @test result1["objective"] != result2["objective"]
    end
end