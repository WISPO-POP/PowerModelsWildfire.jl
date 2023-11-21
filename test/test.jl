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


@testset "_run_redispatch" begin
    case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
    result_redispatch = PowerModelsWildfire._run_redispatch(case, PowerModels.ACPPowerModel, minlp_solver)
    @test result_redispatch["termination_status"] == LOCALLY_SOLVED
    for (id,load) in result_redispatch["solution"]["load"]
        @test isapprox(load["pd"], case["load"][id]["pd"]; atol=1e-4)
        @test isapprox(load["qd"], case["load"][id]["qd"]; atol=1e-4)
    end

    result_normalized_ops = PowerModelsWildfire._run_normalized_ops(case, PowerModels.ACPPowerModel, minlp_solver)
    PowerModelsRestoration.clean_status!(result_normalized_ops["solution"])
    PowerModelsRestoration.update_status!(case, result_normalized_ops["solution"])

    result_redispatch = PowerModelsWildfire._run_redispatch(case, PowerModels.ACPPowerModel, minlp_solver)
    @test result_redispatch["termination_status"] == LOCALLY_SOLVED

    load_served_ops = sum(load["pd"] for (id,load) in result_normalized_ops["solution"]["load"])
    load_served_redis = sum(load["pd"] for (id,load) in result_redispatch["solution"]["load"])

    @test isapprox(load_served_ops, load_served_redis; atol=1e-2)

end


@testset "_run_scops" begin
    @testset "DCPPowerModel" begin
        case = PowerModels.parse_file("./networks/case5_risk_sys2.m")
        case["alpha"]=0.9
        case["beta"]=0.2
        total_load = sum(load["pd"] for (id,load) in case["load"])
        for (id,gen) in case["gen"]
            gen["flexibility"]=0.05
        end

        mn_case = PowerModels.replicate(case, length(keys(case["branch"]))+1)

        keyset = collect(keys(case["branch"]))
        mn_case["nw"]["1"]["contingencies"]=Dict()
        for idx in 1:length(keyset)
            mn_case["nw"]["$(1+idx)"]["contingencies"]=Dict("branch"=>[keyset[idx]])
        end

        # requires MINLP solver because of a quadratic constraint
        result_scops = PowerModelsWildfire._run_scops(mn_case, PowerModels.DCPPowerModel, minlp_solver)
        @test result_scops["termination_status"] == LOCALLY_SOLVED

        # total load = 10.0
        # period 1 load: (should be 9)
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]), digits=2) >= 9.0

        # period 2-6 load: (should be more than 8)
        min_load = sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]) -
                     case["beta"]*sum(load["pd"] for (id,load) in case["load"])

        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["2"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["3"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["4"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["5"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["6"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["7"]["load"]), digits=2) >= min_load

        # test branch energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,branch) in nw["branch"]
                get(mn_case["nw"][nwid]["contingencies"],"branch",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"branch",[])
                    @test isapprox(branch["br_status"], 0.0; atol=1e-2)
                else
                    @test isapprox(branch["br_status"], result_scops["solution"]["nw"]["1"]["branch"][id]["br_status"]; atol=1e-2)
                end
            end
        end

        # test gen energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,gen) in nw["gen"]
                get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                    @test isapprox(gen["gen_status"], 0.0; atol=1e-2)
                else
                    @test round(gen["gen_status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["gen"][id]["gen_status"], digits=2)
                end
            end
        end

        # test load energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,load) in nw["load"]
                get(mn_case["nw"][nwid]["contingencies"],"load",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"load",[])
                    @test isapprox(load["status"], 0.0; atol=1e-2)
                else
                    @test round(load["status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["load"][id]["status"], digits=2)
                end
            end
        end

        # test bus de-energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,bus) in nw["bus"]
                get(mn_case["nw"][nwid]["contingencies"],"bus",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"bus",[])
                    @test isapprox(bus["status"], 0.0; atol=1e-2)
                else
                    @test isapprox(bus["status"], result_scops["solution"]["nw"]["1"]["bus"][id]["status"]; atol=1e-2)
                end
            end
        end

        # test gen power output
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,gen) in nw["gen"]
                get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                if isapprox(gen["gen_status"], 0.0; atol=1e-2)
                    @test isapprox(gen["pg"], 0.0; atol=1e-2)
                else
                    flex = mn_case["nw"][nwid]["gen"][id]["flexibility"]*mn_case["nw"][nwid]["gen"][id]["pmax"]
                    base_output = result_scops["solution"]["nw"]["1"]["gen"][id]["pg"]
                    @test gen["pg"] <= base_output + flex
                    @test gen["pg"] >= base_output - flex
                end
            end
        end
    end

    # Juniper fails to find feasible solution.  Commercial solver Gurobi can find feasible solution.
    # @testset "SOCWRPowerModel" begin
    #     case = PowerModels.parse_file("./networks/case3.m")
    #     case["alpha"]=0.9
    #     case["beta"]=0.2
    #     total_load = sum(load["pd"] for (id,load) in case["load"])
    #     for (id,gen) in case["gen"]
    #         gen["flexibility"]=0.05
    #     end

    #     mn_case = PowerModels.replicate(case, length(keys(case["branch"]))+1)

    #     keyset = collect(keys(case["branch"]))
    #     mn_case["nw"]["1"]["contingencies"]=Dict()
    #     for idx in 1:length(keyset)
    #         mn_case["nw"]["$(1+idx)"]["contingencies"]=Dict("branch"=>[keyset[idx]])
    #     end

    #     # requires MINLP solver because of a quadratic constraint
    #     result_scops = PowerModelsWildfire._run_scops(mn_case, PowerModels.SOCWRPowerModel, minlp_solver)
    #     @test result_scops["termination_status"] == LOCALLY_SOLVED


    #     # total load = 3.15
    #     total_load = sum(load["pd"] for (id,load) in case["load"])
    #     # period 1 load: (should be more than 90% of total load)
    #     @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]), digits=2) >= 0.9*total_load

    #     # period 2-6 load: (should be more than 8)
    #     min_load = sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]) -
    #                 case["beta"]*sum(load["pd"] for (id,load) in case["load"])

    #     @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["2"]["load"]), digits=2) >= min_load
    #     @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["3"]["load"]), digits=2) >= min_load
    #     @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["4"]["load"]), digits=2) >= min_load

    #     # test branch energization status
    #     for (nwid,nw) in result_scops["solution"]["nw"]
    #         for (id,branch) in nw["branch"]
    #             get(mn_case["nw"][nwid]["contingencies"],"branch",[])
    #             if id in get(mn_case["nw"][nwid]["contingencies"],"branch",[])
    #                 @test isapprox(branch["br_status"], 0.0; atol=1e-2)
    #             else
    #                 @test isapprox(branch["br_status"], result_scops["solution"]["nw"]["1"]["branch"][id]["br_status"]; atol=1e-2)
    #             end
    #         end
    #     end

    #     # test gen energization status
    #     for (nwid,nw) in result_scops["solution"]["nw"]
    #         for (id,gen) in nw["gen"]
    #             get(mn_case["nw"][nwid]["contingencies"],"gen",[])
    #             if id in get(mn_case["nw"][nwid]["contingencies"],"gen",[])
    #                 @test isapprox(gen["gen_status"], 0.0; atol=1e-2)
    #             else
    #                 @test round(gen["gen_status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["gen"][id]["gen_status"], digits=2)
    #             end
    #         end
    #     end

    #     # test load energization status
    #     for (nwid,nw) in result_scops["solution"]["nw"]
    #         for (id,load) in nw["load"]
    #             get(mn_case["nw"][nwid]["contingencies"],"load",[])
    #             if id in get(mn_case["nw"][nwid]["contingencies"],"load",[])
    #                 @test isapprox(load["status"], 0.0; atol=1e-2)
    #             else
    #                 @test round(load["status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["load"][id]["status"], digits=2)
    #             end
    #         end
    #     end

    #     # test bus de-energization status
    #     for (nwid,nw) in result_scops["solution"]["nw"]
    #         for (id,bus) in nw["bus"]
    #             get(mn_case["nw"][nwid]["contingencies"],"bus",[])
    #             if id in get(mn_case["nw"][nwid]["contingencies"],"bus",[])
    #                 @test isapprox(bus["status"], 0.0; atol=1e-2)
    #             else
    #                 @test isapprox(bus["status"], result_scops["solution"]["nw"]["1"]["bus"][id]["status"]; atol=1e-2)
    #             end
    #         end
    #     end

    #     # test gen power output
    #     for (nwid,nw) in result_scops["solution"]["nw"]
    #         for (id,gen) in nw["gen"]
    #             get(mn_case["nw"][nwid]["contingencies"],"gen",[])
    #             if isapprox(gen["gen_status"], 0.0; atol=1e-2)
    #                 @test isapprox(gen["pg"], 0.0; atol=1e-2)
    #             else
    #                 flex = mn_case["nw"][nwid]["gen"][id]["flexibility"]*mn_case["nw"][nwid]["gen"][id]["pmax"]
    #                 base_output = result_scops["solution"]["nw"]["1"]["gen"][id]["pg"]
    #                 @test gen["pg"] <= base_output + flex
    #                 @test gen["pg"] >= base_output - flex
    #             end
    #         end
    #     end
    # end

    @testset "ACPPowerModel" begin
        case = PowerModels.parse_file("./networks/case3.m")
        case["alpha"]=0.9
        case["beta"]=0.2
        total_load = sum(load["pd"] for (id,load) in case["load"])
        for (id,gen) in case["gen"]
            gen["flexibility"]=0.05
        end

        mn_case = PowerModels.replicate(case, length(keys(case["branch"]))+1)

        keyset = collect(keys(case["branch"]))
        mn_case["nw"]["1"]["contingencies"]=Dict()
        for idx in 1:length(keyset)
            mn_case["nw"]["$(1+idx)"]["contingencies"]=Dict("branch"=>[keyset[idx]])
        end

        # requires MINLP solver because of a quadratic constraint
        result_scops = PowerModelsWildfire._run_scops(mn_case, PowerModels.ACPPowerModel, minlp_solver)
        @test result_scops["termination_status"] == LOCALLY_SOLVED


        # total load = 3.15
        total_load = sum(load["pd"] for (id,load) in case["load"])
        # period 1 load: (should be more than 90% of total load)
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]), digits=2) >= 0.9*total_load

        # period 2-6 load: (should be more than 8)
        min_load = sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["1"]["load"]) -
                    case["beta"]*sum(load["pd"] for (id,load) in case["load"])

        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["2"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["3"]["load"]), digits=2) >= min_load
        @test round(sum(load["pd"] for (id,load) in result_scops["solution"]["nw"]["4"]["load"]), digits=2) >= min_load

        # test branch energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,branch) in nw["branch"]
                get(mn_case["nw"][nwid]["contingencies"],"branch",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"branch",[])
                    @test isapprox(branch["br_status"], 0.0; atol=1e-2)
                else
                    @test isapprox(branch["br_status"], result_scops["solution"]["nw"]["1"]["branch"][id]["br_status"]; atol=1e-2)
                end
            end
        end

        # test gen energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,gen) in nw["gen"]
                get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                    @test isapprox(gen["gen_status"], 0.0; atol=1e-2)
                else
                    @test round(gen["gen_status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["gen"][id]["gen_status"], digits=2)
                end
            end
        end

        # test load energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,load) in nw["load"]
                get(mn_case["nw"][nwid]["contingencies"],"load",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"load",[])
                    @test isapprox(load["status"], 0.0; atol=1e-2)
                else
                    @test round(load["status"], digits=2)  <= round(result_scops["solution"]["nw"]["1"]["load"][id]["status"], digits=2)
                end
            end
        end

        # test bus de-energization status
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,bus) in nw["bus"]
                get(mn_case["nw"][nwid]["contingencies"],"bus",[])
                if id in get(mn_case["nw"][nwid]["contingencies"],"bus",[])
                    @test isapprox(bus["status"], 0.0; atol=1e-2)
                else
                    @test isapprox(bus["status"], result_scops["solution"]["nw"]["1"]["bus"][id]["status"]; atol=1e-2)
                end
            end
        end

        # test gen power output
        for (nwid,nw) in result_scops["solution"]["nw"]
            for (id,gen) in nw["gen"]
                get(mn_case["nw"][nwid]["contingencies"],"gen",[])
                if isapprox(gen["gen_status"], 0.0; atol=1e-2)
                    @test isapprox(gen["pg"], 0.0; atol=1e-2)
                else
                    flex = mn_case["nw"][nwid]["gen"][id]["flexibility"]*mn_case["nw"][nwid]["gen"][id]["pmax"]
                    base_output = result_scops["solution"]["nw"]["1"]["gen"][id]["pg"]
                    @test gen["pg"] <= base_output + flex
                    @test gen["pg"] >= base_output - flex
                end
            end
        end
    end
end

@testset "_run_contingency_evaluator" begin

    @testset "DCPPowerModel" begin
        ## Cont Evaluator
        case = PowerModels.parse_file("./networks/case3.m")
        case["alpha"]=0.9
        case["threshold"]=case["alpha"]
        case["beta"]=0.2
        total_load = sum(load["pd"] for (id,load) in case["load"])
        for (id,gen) in case["gen"]
            gen["flexibility"]=0.05
        end


        # requires MINLP solver because of a quadratic constraint
        result_ops_dc = PowerModelsWildfire._run_threshold_ops(case, PowerModels.DCPPowerModel, milp_solver)

        PowerModelsRestoration.clean_status!(result_ops_dc["solution"])
        PowerModelsRestoration.update_status!(case, result_ops_dc["solution"])

        # line outage contingency
        case["contingencies"]=Dict("branch"=>["1"])
        result_cont_dc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.DCPPowerModel, milp_solver)

        @test result_cont_dc["termination_status"] == OPTIMAL
        @test isapprox(result_cont_dc["objective"], 2.2; atol=1e-4)
        @test isapprox(result_cont_dc["solution"]["branch"]["1"]["pf"], 0.000; atol=1e-4)

        # gen outage contingency
        case["contingencies"]=Dict("gen"=>["1"])
        result_cont_dc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.DCPPowerModel, milp_solver)

        @test result_cont_dc["termination_status"] == OPTIMAL
        @test isapprox(result_cont_dc["objective"], 1.1; atol=1e-4)
        @test isapprox(result_cont_dc["solution"]["gen"]["1"]["pg"], 0.000; atol=1e-4)

        # bus outage contingency
        case["contingencies"]=Dict("bus"=>["1"], "branch"=>["1","3"]) # bus 1 outage requires line 1 and 3 to be out
        result_cont_dc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.DCPPowerModel, milp_solver)

        @test result_cont_dc["termination_status"] == OPTIMAL
        @test isapprox(result_cont_dc["objective"], 1.1; atol=1e-4)
        @test isapprox(result_cont_dc["solution"]["bus"]["1"]["status"], 0.000; atol=1e-4)
    end

    @testset "SOCWRPowerModel" begin
        ## Cont Evaluator
        case = PowerModels.parse_file("./networks/case3.m")
        case["alpha"]=0.9
        case["threshold"]=case["alpha"]
        case["beta"]=0.2
        total_load = sum(load["pd"] for (id,load) in case["load"])
        for (id,gen) in case["gen"]
            gen["flexibility"]=0.05
        end


        # requires MINLP solver because of a quadratic constraint
        result_ops_soc = PowerModelsWildfire._run_threshold_ops(case, PowerModels.SOCWRPowerModel, minlp_solver)

        PowerModelsRestoration.clean_status!(result_ops_soc["solution"])
        PowerModelsRestoration.update_status!(case, result_ops_soc["solution"])

        # line outage contingency
        case["contingencies"]=Dict("branch"=>["1"])
        result_cont_soc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.SOCWRPowerModel, minlp_solver)

        @test result_cont_soc["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_cont_soc["objective"], 2.545; atol=1e-2)
        @test isapprox(result_cont_soc["solution"]["branch"]["1"]["pf"], 0.000; atol=1e-4)

        # gen outage contingency
        case["contingencies"]=Dict("gen"=>["1"])
        result_cont_soc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.SOCWRPowerModel, minlp_solver)

        @test result_cont_soc["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_cont_soc["objective"], 1.5075; atol=1e-2)
        @test isapprox(result_cont_soc["solution"]["gen"]["1"]["pg"], 0.000; atol=1e-4)

        # bus outage contingency
        case["contingencies"]=Dict("bus"=>["1"], "branch"=>["1","3"]) # bus 1 outage requires line 1 and 3 to be out
        result_cont_soc = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.SOCWRPowerModel, minlp_solver)

        @test result_cont_soc["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_cont_soc["objective"], 1.4938; atol=1e-2)
        @test isapprox(result_cont_soc["solution"]["bus"]["1"]["status"], 0.000; atol=1e-4)
    end

    @testset "ACPPowerModel" begin
        ## Cont Evaluator
        case = PowerModels.parse_file("./networks/case3.m")
        case["alpha"]=0.9
        case["threshold"]=case["alpha"]
        case["beta"]=0.2
        total_load = sum(load["pd"] for (id,load) in case["load"])
        for (id,gen) in case["gen"]
            gen["flexibility"]=0.05
        end


        # requires MINLP solver because of a quadratic constraint
        result_ops_ac = PowerModelsWildfire._run_threshold_ops(case, PowerModels.ACPPowerModel, minlp_solver)


        # line outage contingency
        case["contingencies"]=Dict("branch"=>["1"])
        case["gen"]["1"]["gen_status"]=result_ops_ac["solution"]["gen"]["1"]["gen_status"]
        case["gen"]["2"]["gen_status"]=result_ops_ac["solution"]["gen"]["2"]["gen_status"]
        case["gen"]["3"]["gen_status"]=result_ops_ac["solution"]["gen"]["3"]["gen_status"]
        case["branch"]["1"]["br_status"]=result_ops_ac["solution"]["branch"]["1"]["br_status"]
        case["branch"]["2"]["br_status"]=result_ops_ac["solution"]["branch"]["2"]["br_status"]
        case["branch"]["3"]["br_status"]=result_ops_ac["solution"]["branch"]["3"]["br_status"]
        case["load"]["1"]["status"]=result_ops_ac["solution"]["load"]["1"]["status"]
        case["load"]["2"]["status"]=result_ops_ac["solution"]["load"]["2"]["status"]
        case["load"]["3"]["status"]=result_ops_ac["solution"]["load"]["3"]["status"]
        case["bus"]["1"]["status"]=result_ops_ac["solution"]["bus"]["1"]["status"]
        case["bus"]["2"]["status"]=result_ops_ac["solution"]["bus"]["2"]["status"]
        case["bus"]["3"]["status"]=result_ops_ac["solution"]["bus"]["3"]["status"]
        PowerModelsRestoration.clean_status!(case)

        result_cont_ac = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.ACPPowerModel, minlp_solver)

        @test result_cont_ac["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_cont_ac["objective"], 2.4978; atol=1e-2)
        @test isapprox(result_cont_ac["solution"]["branch"]["1"]["pf"], 0.000; atol=1e-4)

        # # gen outage contingency  ### NO SOLUTION FOUND  (iteration limit on solver) ###
        # case["contingencies"]=Dict("gen"=>["1"])
        # result_cont_ac = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.ACPPowerModel, minlp_solver)

        # @test result_cont_ac["termination_status"] == LOCALLY_SOLVED
        # @test isapprox(result_cont_ac["objective"], 1.5075; atol=1e-2)
        # @test isapprox(result_cont_ac["solution"]["gen"]["1"]["pg"], 0.000; atol=1e-4)

        # bus outage contingency ### NO SOLUTION FOUND  (locally infeasible) ###
        case["contingencies"]=Dict("bus"=>["1"], "branch"=>["1","3"]) # bus 1 outage requires line 1 and 3 to be out
        result_cont_ac = PowerModelsWildfire._run_contingency_evaluator(case, PowerModels.ACPPowerModel, minlp_solver)

        @test result_cont_ac["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_cont_ac["objective"], 1.471; atol=1e-2)
        @test isapprox(result_cont_ac["solution"]["bus"]["1"]["status"], 0.000; atol=1e-4)
    end
end
