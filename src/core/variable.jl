
"variable: `0 <= active_bus[l] <= 1` for `l` in `bus`es"
function variable_bus_active_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax = false,  report::Bool=true)
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

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :status, _PM.ids(pm, nw, :bus), z_bus)
end


"variable: `0 <= branch_restoration[l] <= 1` for `l` in `branch`es"
function variable_branch_restoration_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        branch_restoration = _PM.var(pm, nw)[:branch_restoration] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :branch)],
            base_name="$(nw)_branch_restoration",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "branch_restoration_state")
        )
    else
        branch_restoration = _PM.var(pm, nw)[:branch_restoration] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :branch)],
            base_name="$(nw)_branch_restoration",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "branch_restoration_state")
        )
    end
    # _PM.var(pm, nw)[:branch_restoration] = z_branch_resto

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :branch, :branch_restoration, _PM.ids(pm, nw, :branch), branch_restoration)
end

"variable: `0 <= load_restoration[l] <= 1` for `l` in `load`es"
function variable_load_restoration_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        load_restoration = _PM.var(pm, nw)[:load_restoration] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :load)],
            base_name="$(nw)_load_restoration",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, l), "load_restoration_state")
        )
    else
        load_restoration = _PM.var(pm, nw)[:load_restoration] = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :load)],
            base_name="$(nw)_load_restoration",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, l), "load_restoration_state")
        )
    end
    # _PM.var(pm, nw)[:load_restoration] = load_restoration

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :load, :load_restoration, _PM.ids(pm, nw, :load), load_restoration)
end
