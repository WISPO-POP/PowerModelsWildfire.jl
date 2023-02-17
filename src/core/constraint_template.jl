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


constraint_bus_voltage_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default, kwargs...) = constraint_bus_voltage_on_off(pm, nw, i; kwargs...)


function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end

function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_sqr_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end
