
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
        @testset "test case5_sys1 consistency" begin
            # sufficient gen on all load buses -> turn off all branches
            case = PowerModels.parse_file("./networks/case5_sys1.m")
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

        @testset "test case5_sys2 consistency" begin
            # standard case5 network
            case = PowerModels.parse_file("./networks/case5_sys2.m")
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
            case = PowerModels.parse_file("./networks/case14.m")
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
            case = PowerModels.parse_file("./networks/case5_sys2.m")
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
            case = PowerModels.parse_file("./networks/case14.m")
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
end


