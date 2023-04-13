""
function constraint_model_voltage_active(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, cnd::Int=pm.ccnd)
    constraint_model_voltage_active(pm, nw, cnd)
end


""
function constraint_generation_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    gen = _PM.ref(pm, nw, :gen, i)

    _PM.constraint_gen_power_on_off(pm, nw, i, gen["pmin"], gen["pmax"], gen["qmin"], gen["qmax"])
    _PMR.constraint_gen_bus_connection(pm, nw, i, gen["gen_bus"])

end


""
function constraint_load_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    load = _PM.ref(pm, nw, :load, i)
    _PMR.constraint_load_bus_connection(pm, nw, i, load["load_bus"])
end


""
function constraint_storage_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    storage = _PM.ref(pm, nw, :storage, i)
    _PMR.constraint_storage_bus_connection(pm, nw, i, storage["storage_bus"])
end


""
function constraint_shunt_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    shunt = _PM.ref(pm, nw, :shunt, i)
    _PMR.constraint_shunt_bus_connection(pm, nw, i, shunt["shunt_bus"])
end


""
function constraint_branch_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)

    bus_fr = haskey(_PM.ref(pm, nw, :bus), branch["f_bus"])
    bus_to = haskey(_PM.ref(pm, nw, :bus), branch["t_bus"])

    _PMR.constraint_branch_bus_connection(pm, nw, i, branch["f_bus"])
    _PMR.constraint_branch_bus_connection(pm, nw, i, branch["t_bus"])
end


""
function constraint_restoration_budget(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
    if haskey(_PM.ref(pm, nw), :restoration_budget)
        restoration_budget = _PM.ref(pm, nw, :restoration_budget)
    else
        Memento.warn(_PM._LOGGER, "network data should specify restoration_budget, using 10.0 as a default")
        restoration_budget=10.0
    end
    for (id,branch) in _PM.ref(pm, nw, :branch)
        if !haskey(branch, "restoration_cost")
            Memento.warn(_PM._LOGGER, "branch data should specify `restoration_cost``, using 10.0 as a default")
            branch["restoration_cost"]=10.0
        end
    end
    for (id,bus) in _PM.ref(pm, nw, :bus)
        if !haskey(bus, "restoration_cost")
            Memento.warn(_PM._LOGGER, "bus data should specify `restoration_cost``, using 10.0 as a default")
            bus["restoration_cost"]=10.0
        end
    end
    for (id,gen) in _PM.ref(pm, nw, :gen)
        if !haskey(gen, "restoration_cost")
            Memento.warn(_PM._LOGGER, "gen data should specify `restoration_cost``, using 10.0 as a default")
            gen["restoration_cost"]=10.0
        end
    end

    branch_restoration_cost = Dict(branch["index"] => branch["restoration_cost"] for (id,branch) in _PM.ref(pm, nw, :branch))
    bus_restoration_cost = Dict(bus["index"] => bus["restoration_cost"] for (id,bus) in _PM.ref(pm, nw, :bus))
    gen_restoration_cost = Dict(gen["index"] => gen["restoration_cost"] for (id,gen) in _PM.ref(pm, nw, :gen))
    constraint_restoration_budget(pm, nw, branch_restoration_cost, bus_restoration_cost, gen_restoration_cost, restoration_budget)
end


""
constraint_bus_voltage_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default, kwargs...) = constraint_bus_voltage_on_off(pm, nw, i; kwargs...)


""
function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end


""
function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_sqr_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end


"Shutoff gen must stay shutoff"
function constraint_gen_deenergized(pm::_PM.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    z_gen_1 = _PM.var(pm, nw_1, :z_gen, i)
    z_gen_2 = _PM.var(pm, nw_2, :z_gen, i)

    JuMP.@constraint(pm.model, z_gen_2 <= z_gen_1)
end

"Shutoff bus must stay shutoff"
function constraint_bus_deenergized(pm::_PM.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    z_bus_1 = _PM.var(pm, nw_1, :z_bus, i)
    z_bus_2 = _PM.var(pm, nw_2, :z_bus, i)

    JuMP.@constraint(pm.model, z_bus_2 <= z_bus_1)
end


"Shutoff storage must stay shutoff"
function constraint_storage_deenergized(pm::_PM.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    z_storage_1 = _PM.var(pm, nw_1, :z_storage, i)
    z_storage_2 = _PM.var(pm, nw_2, :z_storage, i)

    JuMP.@constraint(pm.model, z_storage_2 <= z_storage_1)
end


"Shutoff branch must stay shutoff"
function constraint_branch_deenergized(pm::_PM.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    z_branch_1 = _PM.var(pm, nw_1, :z_branch, i)
    z_branch_2 = _PM.var(pm, nw_2, :z_branch, i)

    JuMP.@constraint(pm.model, z_branch_2 <= z_branch_1)
end


"Shutoff load must stay shutoff"
function constraint_load_deenergized(pm::_PM.AbstractPowerModel,  i::Int; nw::Int=nw_id_default)
    z_load_1 = _PM.ref(pm, :load, i, "status")
    z_load_2 = _PM.var(pm, nw, :z_demand, i)

    JuMP.@constraint(pm.model, z_load_2 <= z_load_1)
end


"Shutoff load must stay shutoff"
function constraint_load_deenergized(pm::_PM.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    z_load_1 = _PM.var(pm, nw_1, :z_demand, i)
    z_load_2 = _PM.var(pm, nw_2, :z_demand, i)

    JuMP.@constraint(pm.model, z_load_2 <= z_load_1)
end

"Shutoff load must stay shutoff"
function constraint_system_load_threshold(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
    alpha = _PM.ref(pm, nw, :alpha)
    z_load = _PM.var(pm, nw, :z_demand)
    total_load = sum(load["pd"] for (id,load) in _PM.ref(pm, nw, :load))

    JuMP.@constraint(pm.model,
        sum(z_load[i]*load["pd"] for (i,load) in _PM.ref(pm, nw, :load))/total_load >= alpha
    )
end

"Limit additional load shed in contingency"
function constraint_contingency_load_shed(pm::_PM.AbstractPowerModel, nw_1::Int, nw_2::Int)
    beta = _PM.ref(pm, nw_2, :beta)
    z_load_1 = _PM.var(pm, nw_1, :z_demand)
    z_load_2 = _PM.var(pm, nw_2, :z_demand)
    total_load = sum(load["pd"] for (id,load) in _PM.ref(pm, nw_2, :load))

    cont_load_shed = sum((z_load_1[i]- z_load_2[i])*load["pd"] for (i,load) in _PM.ref(pm, nw_2, :load))
    JuMP.@constraint(pm.model, cont_load_shed / total_load <=  beta)
end


"Branch energization in contingency"
function constraint_branch_contingency(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    z_branch_1 = _PM.ref(pm, :branch, i, "br_status")
    z_branch_2 = _PM.var(pm, nw, :z_branch, i)

    cont = parse.(Int, get(_PM.ref(pm, nw, :contingencies), "branch", String[]))

    if i in cont # de-energize branch if in contingency set
        JuMP.@constraint(pm.model, z_branch_2 == 0)
    else # energization state set in pre-contingency period
        JuMP.@constraint(pm.model, z_branch_2 == z_branch_1)
    end
end


"Branch energization in contingency"
function constraint_branch_contingency(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    z_branch_1 = _PM.var(pm, nw_1, :z_branch, i)
    z_branch_2 = _PM.var(pm, nw_2, :z_branch, i)

    cont = parse.(Int, get(_PM.ref(pm, nw_2, :contingencies), "branch", String[]))

    if i in cont # de-energize branch if in contingency set
        JuMP.@constraint(pm.model, z_branch_2 == 0)
    else # energization state set in pre-contingency period
        JuMP.@constraint(pm.model, z_branch_2 == z_branch_1)
    end
end


"Bus energization in contingency"
function constraint_bus_contingency(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    z_bus_1 = _PM.ref(pm, :bus, i, "bus_type")
    z_bus_2 = _PM.var(pm, nw, :z_bus, i)

    cont = parse.(Int, get(_PM.ref(pm, nw, :contingencies), "bus", String[]))

    if i in cont # de-energize bus if in contingency set
        JuMP.@constraint(pm.model, z_bus_2 == 0)
    else # energization state set in pre-contingency period
        JuMP.@constraint(pm.model, z_bus_2 == (z_bus_1==4 ? 0 : 1))
    end
end


"Bus energization in contingency"
function constraint_bus_contingency(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    z_bus_1 = _PM.var(pm, nw_1, :z_bus, i)
    z_bus_2 = _PM.var(pm, nw_2, :z_bus, i)

    cont = parse.(Int, get(_PM.ref(pm, nw_2, :contingencies), "bus", String[]))

    if i in cont # de-energize bus if in contingency set
        JuMP.@constraint(pm.model, z_bus_2 == 0)
    else # energization state set in pre-contingency period
        JuMP.@constraint(pm.model, z_bus_2 == z_bus_1)
    end
end


"Gen energization in contingency"
function constraint_gen_contingency(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    z_gen_1 = _PM.ref(pm, :gen, i, "gen_status")
    z_gen_2 = _PM.var(pm, nw, :z_gen, i)


    cont = parse.(Int, get(_PM.ref(pm, nw, :contingencies), "gen", String[]))

    if i in cont # de-energize gen if in contingency set
        JuMP.@constraint(pm.model, z_gen_2 == 0)
    else # energization state set in pre-contingency period, but can trip offline (de-energize)
        JuMP.@constraint(pm.model, z_gen_2 <= z_gen_1)
    end
end


"Gen energization in contingency"
function constraint_gen_contingency(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    z_gen_1 = _PM.var(pm, nw_1, :z_gen, i)
    z_gen_2 = _PM.var(pm, nw_2, :z_gen, i)

    cont = parse.(Int, get(_PM.ref(pm, nw_2, :contingencies), "gen", String[]))

    if i in cont # de-energize gen if in contingency set
        JuMP.@constraint(pm.model, z_gen_2 == 0)
    else # energization state set in pre-contingency period, but can trip offline (de-energize)
        JuMP.@constraint(pm.model, z_gen_2 <= z_gen_1)
    end
end


function constraint_gen_flexibility(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    p_max = _PM.ref(pm, :gen, i, "pmax")
    p_flex = _PM.ref(pm, :gen, i, "flexibility")

    p_gen_1 = _PM.ref(pm, :gen, i, "pg")
    p_gen_2 = _PM.var(pm, nw, :pg, i)
    z_gen_2 = _PM.var(pm, nw, :z_gen, i)

    JuMP.@constraint(pm.model, p_gen_2 <= z_gen_2*(p_gen_1 + p_max*p_flex))
    JuMP.@constraint(pm.model, p_gen_2 >= z_gen_2*(p_gen_1 - p_max*p_flex))
end


function constraint_gen_flexibility(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    p_max = _PM.ref(pm, nw_2, :gen, i, "pmax")
    p_flex = _PM.ref(pm, nw_2, :gen, i, "flexibility")

    p_gen_1 = _PM.var(pm, nw_1, :pg, i)
    p_gen_2 = _PM.var(pm, nw_2, :pg, i)
    z_gen_2 = _PM.var(pm, nw_2, :z_gen, i)

    JuMP.@constraint(pm.model, p_gen_2 <= z_gen_2*(p_gen_1 + p_max*p_flex))
    JuMP.@constraint(pm.model, p_gen_2 >= z_gen_2*(p_gen_1 - p_max*p_flex))
end
