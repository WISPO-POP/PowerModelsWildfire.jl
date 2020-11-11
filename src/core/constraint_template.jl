""
function constraint_model_voltage_active(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    constraint_model_voltage_active(pm, nw, cnd)
end


""
function constraint_generation_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    gen = _PM.ref(pm, nw, :gen, i)

    _PM.constraint_gen_power_on_off(pm, nw, i, gen["pmin"], gen["pmax"], gen["qmin"], gen["qmax"])
    _PMR.constraint_gen_bus_connection(pm, nw, i, gen["gen_bus"])

end


""
function constraint_load_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    load = _PM.ref(pm, nw, :load, i)
    _PMR.constraint_load_bus_connection(pm, nw, i, load["load_bus"])
end


""
function constraint_shunt_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    shunt = _PM.ref(pm, nw, :shunt, i)
    _PMR.constraint_shunt_bus_connection(pm, nw, i, shunt["shunt_bus"])
end


""
function constraint_branch_active(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :branch, i)

    bus_fr = haskey(_PM.ref(pm, nw, :bus), branch["f_bus"])
    bus_to = haskey(_PM.ref(pm, nw, :bus), branch["t_bus"])

    _PMR.constraint_branch_bus_connection(pm, nw, i, branch["f_bus"])
    _PMR.constraint_branch_bus_connection(pm, nw, i, branch["t_bus"])
end

