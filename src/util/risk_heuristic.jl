
function run_voltage_shutoff_heuristic(case, model_constructor, optimizer; risk_threshold = 0.0, kwargs...)
    network = deepcopy(case)

    for (id, branch) in network["branch"]
        if branch["power_risk"]+branch["base_risk"] >= risk_threshold ||
           branch["power_risk"]+branch["base_risk"] >= risk_threshold
           branch["br_status"] = 0
        end
    end
    _PM.propagate_topology_status!(network)


    network["risk_weight"]=0.0
    ops_solution = run_ops(network,model_constructor,optimizer; kwargs...)
    _PM.update_data!(network, ops_solution["solution"])

    disable_isolated_buses!(network)
    _PM.propagate_topology_status!(network)

    return network
end

function run_area_shutoff_heuristic(case, model_constructor, optimizer; risk_threshold = 0.0, kwargs...)
    network = deepcopy(case)

    region_risk = Dict()
    for (id, bus) in network["bus"]
        if ~haskey(region_risk, "$(bus["area"])")
            region_risk["$(bus["area"])"] = bus["power_risk"]+bus["base_risk"]
        else
            region_risk["$(bus["area"])"] += bus["power_risk"]+bus["base_risk"]
        end
    end

    for (area, risk) in region_risk
        if risk >= risk_threshold
            for (id, bus) in network["bus"]
                if "$(bus["area"])" == area
                    bus["bus_type"] = 4
                end
            end
        end
    end

    _PM.propagate_topology_status!(network)

    network["risk_weight"]=0.0
    ops_solution = run_ops(network,model_constructor, optimizer; kwargs...)
    _PM.update_data!(network, ops_solution["solution"])

    disable_isolated_buses!(network)
    _PM.propagate_topology_status!(network)

    return network
end
