
using PowerModelsWildfire
using Test

import PowerModels
import Cbc
import JuMP
import Memento
import InfrastructureModels

Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
PowerModels.logger_config!("error")

mip_optimizer = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel"=>0)


@testset "PowerModelsWildfire" begin

    @testset "OPS" begin
        @testset "test case5_risk_sys1 consistency" begin
            # sufficient gen on all load buses -> turn off all branches
            case = PowerModels.parse_file("./networks/case5_risk_sys1.m")
            result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, mip_optimizer);
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
            result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, mip_optimizer);
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
            result = PowerModelsWildfire.run_ops(case, PowerModels.DCPPowerModel, mip_optimizer);
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
    end

    @testset "Heuristics" begin
        @testset "Voltage Heuristic" begin
            case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
            result = PowerModelsWildfire.run_voltage_shutoff_heuristic(case, PowerModels.DCPPowerModel, mip_optimizer, risk_threshold=2.0);
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
        @testset "Area Heuristic" begin
            case = PowerModels.parse_file("./networks/case14_risk.m")
            result = PowerModelsWildfire.run_area_shutoff_heuristic(case, PowerModels.DCPPowerModel, mip_optimizer, risk_threshold=20.0);
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
    end

    @testset "MOPS" begin
        @testset "constant risk" begin

            case = PowerModels.parse_file("./networks/case5_risk_mops.m")
            case_mn = PowerModels.replicate(case, 3)
            result = PowerModelsWildfire.run_mops(case_mn, PowerModels.DCPPowerModel, mip_optimizer);
            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"],-0.06; atol=1e-4)

            PowerModels.update_data!(case_mn,result["solution"])
            @test isapprox(calc_total_risk(case_mn), 120.0, atol=1e-4)
            @test isapprox(calc_load(case_mn),23.6552, atol=1e-4)

            # check results of network 1
            @test isapprox(case["branch"]["1"]["br_status"], 1, atol=1e-4)
            @test isapprox(case["branch"]["2"]["br_status"], 1, atol=1e-4)
            @test isapprox(case["branch"]["3"]["br_status"], 1, atol=1e-4)
            @test isapprox(case["branch"]["4"]["br_status"], 1, atol=1e-4)
            @test isapprox(case["branch"]["5"]["br_status"], 1, atol=1e-4)
            @test isapprox(case["branch"]["6"]["br_status"], 1, atol=1e-4)

            # risk is same in each period, each period component status should be identical
            for nwid in ["2","3"]
                for (br_id,branch) in case_mn["nw"][nwid]["branch"]
                    @test branch["br_status"]== case_mn["nw"]["1"]["branch"][br_id]["br_status"]
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

            result = PowerModelsWildfire.run_mops(case_mn, PowerModels.DCPPowerModel, mip_optimizer);
            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"],0.2418; atol=1e-4)

            PowerModels.update_data!(case_mn,result["solution"])
            @test isapprox(calc_total_risk(case_mn), 0, atol=1e-4)
            @test isapprox(calc_load(case_mn),15.5971, atol=1e-4)

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
            case["restoration_budget"]=50.0
            case["restoration_cost"] = 0.0
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

            result = PowerModelsWildfire.run_mops(case_mn, PowerModels.DCPPowerModel, mip_optimizer);
            @test result["termination_status"] == OPTIMAL

            @test isapprox(result["objective"],0.2342; atol=1e-4)

            PowerModels.update_data!(case_mn,result["solution"])
            @test isapprox(calc_total_risk(case_mn), 0, atol=1e-4)
            @test isapprox(calc_load(case_mn),15.8786, atol=1e-4)

            # all branches should be active in no risk time periods
            for nwid in ["1"]
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

            @test isapprox(case_mn["nw"]["3"]["branch"]["1"]["br_status"], 1.0; atol=1e-4)
            @test isapprox(case_mn["nw"]["3"]["branch"]["2"]["br_status"], 1.0; atol=1e-4)
            @test isapprox(case_mn["nw"]["3"]["branch"]["3"]["br_status"], 0.0; atol=1e-4)
            @test isapprox(case_mn["nw"]["3"]["branch"]["4"]["br_status"], 1.0; atol=1e-4)
            @test isapprox(case_mn["nw"]["3"]["branch"]["5"]["br_status"], 1.0; atol=1e-4)
            @test isapprox(case_mn["nw"]["3"]["branch"]["6"]["br_status"], 1.0; atol=1e-4)
        end
    end
end


