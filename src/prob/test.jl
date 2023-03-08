######
#
# These are toy problem formulations used to test advanced features
# Includes multi-period problems, storage, alternative objective functions, etc.
# These problem formulations are not subject to the same level of testings as public formulations
#
######


# Normalized objective function
""
function _run_normalized_ops(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_normalized_ops;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function _build_normalized_ops(pm::_PM.AbstractPowerModel)

    variable_bus_active_indicator(pm)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_indicator(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    _PM.constraint_model_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        constraint_generation_active(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_bus_voltage_on_off(pm, i)
        _PMR.constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        constraint_branch_active(pm, i)
        _PM.constraint_ohms_yt_from_on_off(pm, i)
        _PM.constraint_ohms_yt_to_on_off(pm, i)

        _PM.constraint_voltage_angle_difference_on_off(pm, i)

        _PM.constraint_thermal_limit_from_on_off(pm, i)
        _PM.constraint_thermal_limit_to_on_off(pm, i)
    end

    for i in _PM.ids(pm, :load)
        constraint_load_active(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i) #not active decision variables
    end

    # Add Objective
    # ------------------------------------
    # Maximize power delivery while minimizing wildfire risk
    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    z_gen = _PM.var(pm, nw_id_default, :z_gen)
    z_branch = _PM.var(pm, nw_id_default, :z_branch)
    z_bus = _PM.var(pm, nw_id_default, :z_bus)

    if haskey(_PM.ref(pm), :risk_weight)
        alpha = _PM.ref(pm, :risk_weight)
    else
        Memento.warn(_PM._LOGGER, "network data should specify risk_weight, using 0.5 as a default")
        alpha = 0.5
    end

    for comp_type in [:gen, :load, :bus, :branch]
        for (id,comp) in  _PM.ref(pm, comp_type)
            if ~haskey(comp, "power_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.1 as a default")
                comp["power_risk"] = 0.1
            end
            if ~haskey(comp, "base_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a base_risk value, using 0.1 as a default")
                comp["base_risk"] = 0.1
            end
        end
    end

    load_weight = Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, :load))

    # scale based on total load demand and risk
    total_load = sum(sum(load["pd"] for (load_id,load) in nw[:load]) for (nwid,nw) in  _PM.nws(pm))
    total_risk =
    sum(sum(sum(get(comp,"power_risk",0)
                for (compid,comp) in  _PM.ref(pm, nwid, comp_type); init=0.0)
            for nwid in  _PM.nw_ids(pm))
        for comp_type in [:branch,:gen,:bus,:load]
    )

    JuMP.@objective(pm.model, Max,
        (1-alpha)*(
                sum(z_demand[i]*load_weight[i]*load["pd"] for (i,load) in _PM.ref(pm,:load))/total_load
        )
        - alpha*(
            sum(z_gen[i]*gen["power_risk"]+gen["base_risk"] for (i,gen) in _PM.ref(pm, :gen))
            + sum(z_bus[i]*bus["power_risk"]+bus["base_risk"] for (i,bus) in _PM.ref(pm, :bus))
            + sum(z_branch[i]*branch["power_risk"]+branch["base_risk"] for (i,branch) in _PM.ref(pm, :branch))
            + sum(z_demand[i]*load["power_risk"]+load["base_risk"] for (i,load) in _PM.ref(pm,:load))
        )/total_risk
    )

end


# Threshold Risk problem

# SCOPS problem

# OPS with storage
""
function _run_strg_ops(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_strg_ops;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function _build_strg_ops(pm::_PM.AbstractPowerModel)

    variable_bus_active_indicator(pm)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_storage_indicator(pm)
    _PM.variable_storage_power_mi_on_off(pm)

    _PM.variable_branch_indicator(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    _PM.constraint_model_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        constraint_generation_active(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_bus_voltage_on_off(pm, i)
        _PMR.constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :storage)
        constraint_storage_active(pm, i)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        _PM.constraint_storage_on_off(pm,i)
        _PM.constraint_storage_losses(pm, i)
        _PM.constraint_storage_thermal_limit(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        constraint_branch_active(pm, i)
        _PM.constraint_ohms_yt_from_on_off(pm, i)
        _PM.constraint_ohms_yt_to_on_off(pm, i)

        _PM.constraint_voltage_angle_difference_on_off(pm, i)

        _PM.constraint_thermal_limit_from_on_off(pm, i)
        _PM.constraint_thermal_limit_to_on_off(pm, i)
    end

    for i in _PM.ids(pm, :load)
        constraint_load_active(pm, i)
    end

    # Add Objective
    # ------------------------------------
    # Maximize power delivery while minimizing wildfire risk
    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    z_storage = _PM.var(pm, nw_id_default, :z_storage)
    z_gen = _PM.var(pm, nw_id_default, :z_gen)
    z_branch = _PM.var(pm, nw_id_default, :z_branch)
    z_bus = _PM.var(pm, nw_id_default, :z_bus)

    if haskey(_PM.ref(pm), :risk_weight)
        alpha = _PM.ref(pm, :risk_weight)
    else
        Memento.warn(_PM._LOGGER, "network data should specify risk_weight, using 0.5 as a default")
        alpha = 0.5
    end

    for comp_type in [:gen, :load, :bus, :branch]
        for (id,comp) in  _PM.ref(pm, comp_type)
            if ~haskey(comp, "power_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.1 as a default")
                comp["power_risk"] = 0.1
            end
            if ~haskey(comp, "base_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a base_risk value, using 0.1 as a default")
                comp["base_risk"] = 0.1
            end
        end
    end

    load_weight = Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, :load))

    JuMP.@objective(pm.model, Max,
        (1-alpha)*(
                sum(z_demand[i]*load_weight[i]*load["pd"] for (i,load) in _PM.ref(pm,:load))
        )
        - alpha*(
            sum(z_gen[i]*gen["power_risk"]+gen["base_risk"] for (i,gen) in _PM.ref(pm, :gen))
            + sum(z_bus[i]*bus["power_risk"]+bus["base_risk"] for (i,bus) in _PM.ref(pm, :bus))
            + sum(z_branch[i]*branch["power_risk"]+branch["base_risk"] for (i,branch) in _PM.ref(pm, :branch))
            + sum(z_demand[i]*load["power_risk"]+load["base_risk"] for (i,load) in _PM.ref(pm,:load))
            + sum(z_storage[i]*storage["power_risk"]+storage["base_risk"] for (i,storage) in _PM.ref(pm, :storage))
        )
    )

end

# MOPS with storage problem

