@testset "MOPS" begin
    @testset "constant risk" begin

        case = PowerModels.parse_file("./networks/case5_risk_mops.m")
        case_mn = PowerModels.replicate(case, 3)
        result = PowerModelsWildfire.run_mopsar(case_mn, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"],0.0; atol=1e-4)

        PowerModels.update_data!(case_mn,result["solution"])

        # finds a solution that serves all load regardless of risk
        @test isapprox(calc_total_risk(case_mn), 150.0, atol=1e-4)
        @test isapprox(calc_load(case_mn),30.0, atol=1e-4)

        # each component is active in network 1
        @test isapprox(case_mn["nw"]["1"]["branch"]["1"]["br_status"], 1.0; atol=1e-4)
        @test isapprox(case_mn["nw"]["1"]["branch"]["2"]["br_status"], 1.0; atol=1e-4)
        @test isapprox(case_mn["nw"]["1"]["branch"]["3"]["br_status"], 1.0; atol=1e-4)
        @test isapprox(case_mn["nw"]["1"]["branch"]["4"]["br_status"], 1.0; atol=1e-4)
        @test isapprox(case_mn["nw"]["1"]["branch"]["5"]["br_status"], 1.0; atol=1e-4)

        # Each network finds same solution
        for nwid in ["2","3"]
            for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                @test isapprox(branch["br_status"], case_mn["nw"]["1"]["branch"][br_id]["br_status"]; atol=1e-4)
            end
        end
    end

    @testset "Changing risk" begin
        # set high risk in period 2, no risk in period 1 or 3, with no restoration cost
        # result should turn off all lines in 2, restore all lines in 3
        case = PowerModels.parse_file("./networks/case5_risk_mops.m")
        case["risk_weight"]= 0.5
        case["disable_cost"] = 10.0
        case["restoration_budget"]=100.0
        case["restoration_cost"] = 0.0
        case_mn = PowerModels.replicate(case, 3)

        for (id,branch) in case_mn["nw"]["1"]["branch"]
            branch["power_risk"]=0.0
            branch["restoration_cost"]=0.0
        end
        for (id,branch) in case_mn["nw"]["2"]["branch"]
            branch["power_risk"]=100.0
            branch["restoration_cost"]=0.0
        end
        for (id,branch) in case_mn["nw"]["3"]["branch"]
            branch["power_risk"]=0.0
            branch["restoration_cost"]=0.0
        end

        result = PowerModelsWildfire.run_mopsar(case_mn, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"],0.2833; atol=1e-4)

        PowerModels.update_data!(case_mn,result["solution"])
        @test isapprox(calc_total_risk(case_mn), 0, atol=1e-4)
        @test isapprox(calc_load(case_mn),20.0, atol=1e-4)

        # all branches should be active in no risk time periods
        for nwid in ["1","3"]
            for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                @test isapprox(branch["br_status"], 1.0; atol=1e-4)
            end
        end

        # all branches should be off in high risk period
        for nwid in ["2"]
            for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                @test isapprox(branch["br_status"], 0.0; atol=1e-4)
            end
        end
    end

    @testset "restoration budget" begin
        # set high risk in period 2, no risk in period 1 or 3
        # restoration cost of all lines is greater than restoration budget
        # result should turn off all lines in 2, and restor all but 1 line in period 3
        case = PowerModels.parse_file("./networks/case5_risk_mops.m")
        case["risk_weight"]= 0.5
        case["disable_cost"] = 10.0
        case["restoration_budget"]=40.0
        case_mn = PowerModels.replicate(case, 3)

        for (id,branch) in case_mn["nw"]["1"]["branch"]
            branch["power_risk"]=0.0
            branch["restoration_cost"]=10.0
        end
        for (id,branch) in case_mn["nw"]["2"]["branch"]
            branch["power_risk"]=100.0
            branch["restoration_cost"]=10.0
        end
        for (id,branch) in case_mn["nw"]["3"]["branch"]
            branch["power_risk"]=0.0
            branch["restoration_cost"]=10.0
        end

        result = PowerModelsWildfire.run_mopsar(case_mn, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL

        @test isapprox(result["objective"],0.26; atol=1e-4)

        PowerModels.update_data!(case_mn,result["solution"])
        @test isapprox(calc_total_risk(case_mn), 100.0, atol=1e-4)
        @test isapprox(calc_load(case_mn),24.0, atol=1e-4)

        # all branches should be active in no risk time periods
        for nwid in ["1"]
            for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                @test isapprox(branch["br_status"], 1.0; atol=1e-4)
            end
        end

        # one branch kept active in high risk period
        # because of restoration budget limitations for final period
        @test isapprox(sum(branch["br_status"] for (br_id,branch) in case_mn["nw"]["2"]["branch"]), 1.0; atol=1e-4)

        # all branches restored in final period
        for nwid in ["3"]
            for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                @test isapprox(branch["br_status"], 1.0; atol=1e-4)
            end
        end


        ## Check gen/bus budget limits as well
        case = PowerModels.parse_file("./networks/case5_risk_mops.m")
        case["risk_weight"]= 0.5
        case["disable_cost"] = 10.0
        case["restoration_budget"]=40.0
        case_mn = PowerModels.replicate(case, 3)

        for comp_type in ["gen","bus"]
            for (id,comp) in case_mn["nw"]["1"][comp_type]
                comp["power_risk"]=5.0
                comp["restoration_cost"]=10.0
            end
            for (id,comp) in case_mn["nw"]["2"][comp_type]
                comp["power_risk"]=100.0
                comp["restoration_cost"]=10.0
            end
            for (id,comp) in case_mn["nw"]["3"][comp_type]
                comp["power_risk"]=5.0
                comp["restoration_cost"]=10.0
            end
        end
        for comp_type in ["branch"] #"branch",
            for (id,comp) in case_mn["nw"]["1"][comp_type]
                comp["power_risk"]=5.0
                comp["restoration_cost"]=10.0
            end
            for (id,comp) in case_mn["nw"]["2"][comp_type]
                comp["power_risk"]=5.0
                comp["restoration_cost"]=10.0
            end
            for (id,comp) in case_mn["nw"]["3"][comp_type]
                comp["power_risk"]=5.0
                comp["restoration_cost"]=10.0
            end
        end
        result = PowerModelsWildfire.run_mopsar(case_mn, PowerModels.DCPPowerModel, milp_solver);
        @test result["termination_status"] == OPTIMAL

        @test isapprox(result["objective"],0.0939; atol=1e-4)

        PowerModels.update_data!(case_mn,result["solution"])
        @test isapprox(calc_total_risk(case_mn), 855.0, atol=1e-4)
        @test isapprox(calc_load(case_mn),26.91, atol=1e-2)

        # All devices active in period 1
        @test sum(branch["br_status"] for (id,branch) in case_mn["nw"]["1"]["branch"]) == 5
        @test sum(gen["gen_status"] for (id,gen) in case_mn["nw"]["1"]["gen"]) == 5
        @test sum(bus["status"] for (id,bus) in case_mn["nw"]["1"]["bus"]) == 5

        # most devices inactive in period 2
        @test sum(branch["br_status"] for (id,branch) in case_mn["nw"]["2"]["branch"]) <= 5
        @test sum(gen["gen_status"] for (id,gen) in case_mn["nw"]["2"]["gen"]) <= 5
        @test sum(bus["status"] for (id,bus) in case_mn["nw"]["2"]["bus"]) <= 5
        @test sum(branch["br_status"] for (id,branch) in case_mn["nw"]["2"]["branch"]) +
                sum(gen["gen_status"] for (id,gen) in case_mn["nw"]["2"]["gen"]) +
                sum(bus["status"] for (id,bus) in case_mn["nw"]["2"]["bus"]) == 9


        # 4 devices repaired in period 3
        @test sum(branch["br_status"] for (id,branch) in case_mn["nw"]["3"]["branch"]) +
                sum(gen["gen_status"] for (id,gen) in case_mn["nw"]["3"]["gen"]) +
                sum(bus["status"] for (id,bus) in case_mn["nw"]["3"]["bus"]) == 13


    end
    @testset "load weights"  begin
        case = PowerModels.parse_file("./networks/case5_risk_mops.m")
        case_mn = PowerModels.replicate(case, 3)

        result1 = run_mopsar(case_mn,PowerModels.DCPPowerModel,milp_solver)

        for (nwid,nw) in case_mn["nw"]
            for (id,load) in nw["load"]
                load["weight"]=rand()
            end
        end
        result2 = run_mopsar(case_mn,PowerModels.DCPPowerModel,milp_solver)

        @test result1["objective"] != result2["objective"]
    end
end