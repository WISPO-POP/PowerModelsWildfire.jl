
function calc_total_risk(data)
    risk = 0.0
    risk += calc_bus_risk(data)
    risk += calc_gen_risk(data)
    risk += calc_branch_risk(data)
    risk += calc_load_risk(data)

    return risk
end

function calc_bus_risk(data)
    calc_risk(data,"bus")
end

function calc_gen_risk(data)
    calc_risk(data,"gen")
end

function calc_branch_risk(data)
    calc_risk(data,"branch")
end

function calc_load_risk(data)
    calc_risk(data,"load")
end

function calc_risk(data, comp_type)
    risk = 0.0
    comp_status = _PM.pm_component_status[comp_type]
    for (comp_id, comp) in get(data,comp_type, Dict())
        if comp_type=="bus"
            risk += get(comp, "power_risk",0.0)* (comp[comp_status]==4 ? 0 : 1)
        else
            risk += get(comp, "power_risk",0.0)*comp[comp_status]
        end
        risk += get(comp, "base_risk", 0.0)
    end

    return risk
end

function calc_load(data)
    return sum(load["pd"]*load["status"] for (load_id, load) in data["load"])
end

"disable a bus that is disconnected from generators and branches"
function disable_isolated_buses!(network)
    connected_bus = Dict(id => false for (id,bus) in network["bus"])
    for (comp_id, comp) in network["gen"]
        comp_status = _PM.pm_component_status["gen"]
        if comp[comp_status]!= _PM.pm_component_status_inactive["gen"]
            connected_bus["$(comp["gen_bus"])"] = true
        end
    end
    for (comp_id, comp) in network["branch"]
        comp_status = _PM.pm_component_status["branch"]
        if comp[comp_status]!= _PM.pm_component_status_inactive["branch"]
            connected_bus["$(comp["f_bus"])"] = true
            connected_bus["$(comp["t_bus"])"] = true
        end
    end

    for (id, connected) in connected_bus
        if !connected
            network["bus"][id]["bus_type"]=4
        end
    end
    return network
end
