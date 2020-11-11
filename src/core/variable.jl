
"variable: `0 <= active_bus[l] <= 1` for `l` in `bus`es"
function variable_bus_active_indicator(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, relax = false,  report::Bool=true)
    if relax == false
        z_bus = _PM.var(pm, nw)[:z_bus] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :bus)],
            base_name="$(nw)_active_bus",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, l), "bus_active_start")
        )
    else
        z_bus = _PM.var(pm, nw)[:z_bus] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :bus)],
            base_name="$(nw)_active_bus",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, l), "bus_active_start")
        )
    end

    report && _IM.sol_component_value(pm, nw, :bus, :status, _PM.ids(pm, nw, :bus), z_bus)
end
