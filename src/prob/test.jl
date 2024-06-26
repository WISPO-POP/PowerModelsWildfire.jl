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

""
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
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.0 as a default")
                comp["power_risk"] = 0.0
            end
            if ~haskey(comp, "base_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a base_risk value, using 0.0 as a default")
                comp["base_risk"] = 0.0
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
""
function _run_threshold_ops(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_threshold_ops;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


""
function _build_threshold_ops(pm::_PM.AbstractPowerModel)

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

    constraint_load_served(pm)

    # Add Objective
    # ------------------------------------
    # Maximize power delivery while minimizing wildfire risk
    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    z_gen = _PM.var(pm, nw_id_default, :z_gen)
    z_branch = _PM.var(pm, nw_id_default, :z_branch)
    z_bus = _PM.var(pm, nw_id_default, :z_bus)

    for comp_type in [:gen, :load, :bus, :branch]
        for (id,comp) in  _PM.ref(pm, comp_type)
            if ~haskey(comp, "power_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.1 as a default")
                comp["power_risk"] = 0.0
            end
            if ~haskey(comp, "base_risk")
                Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a base_risk value, using 0.1 as a default")
                comp["base_risk"] = 0.0
            end
        end
    end

    JuMP.@objective(pm.model, Min,
            sum(z_gen[i]*gen["power_risk"]+gen["base_risk"] for (i,gen) in _PM.ref(pm, :gen))
            + sum(z_bus[i]*bus["power_risk"]+bus["base_risk"] for (i,bus) in _PM.ref(pm, :bus))
            + sum(z_branch[i]*branch["power_risk"]+branch["base_risk"] for (i,branch) in _PM.ref(pm, :branch))
            + sum(z_demand[i]*load["power_risk"]+load["base_risk"] for (i,load) in _PM.ref(pm,:load))

    )
end

# SCOPS problem
""
function _run_scops(file, model_constructor::Type, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_scops;
        multinetwork=true, ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end

""
function _build_scops(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)

        variable_bus_active_indicator(pm, nw=n)
        variable_bus_voltage_on_off(pm, nw=n)

        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power_on_off(pm, nw=n)

        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)
        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_generation_active(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_voltage_on_off(pm, i, nw=n)
            _PMR.constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            constraint_branch_active(pm, i, nw=n)
            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :load, nw=n)
            constraint_load_active(pm, i, nw=n)
        end
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))
    n_1 = network_ids[1]

    constraint_system_load_threshold(pm, nw=n_1)


    for n_2 in network_ids[2:end]
        constraint_contingency_load_shed(pm, n_1, n_2)

        for i in _PM.ids(pm, :gen, nw=n_2)
            constraint_gen_contingency(pm, i, n_1, n_2)
            constraint_gen_flexibility(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :bus, nw=n_2)
            constraint_bus_contingency(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_branch_contingency(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :load, nw=n_2)
            constraint_load_deenergized(pm, i, n_1, n_2)
        end
    end

    # Add Objective Function
    # ----------------------
    # Minimize wildfire risk
    for comp_type in [:gen, :load, :bus, :branch]
        for (id,comp) in  _PM.ref(pm, n_1, comp_type)
            if ~haskey(comp, "power_risk")
                @warn "$(comp_type) $(id) does not have a power_risk value, using 0.0 as a default"
                comp["power_risk"] = 0.0
            end
        end
    end

    z_demand = _PM.var(pm, n_1, :z_demand)
    z_gen = _PM.var(pm, n_1, :z_gen)
    z_branch = _PM.var(pm, n_1, :z_branch)
    z_bus = _PM.var(pm, n_1, :z_bus)

    JuMP.@objective(pm.model, Min,
        (     sum(z_gen[i]*gen["power_risk"] for (i,gen) in _PM.ref(pm, n_1, :gen))
            + sum(z_bus[i]*bus["power_risk"] for (i,bus) in _PM.ref(pm, n_1, :bus))
            + sum(z_branch[i]*branch["power_risk"] for (i,branch) in _PM.ref(pm, n_1, :branch))
            + sum(z_demand[i]*load["power_risk"] for (i,load) in _PM.ref(pm, n_1, :load))
        )
    )

end

# Contingency Evaluator Problem
""
function _run_contingency_evaluator(file, model_constructor::Type, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_contingency_evaluator;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end

""
function _build_contingency_evaluator(pm::_PM.AbstractPowerModel)

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

    for i in _PM.ids(pm, :gen)
        constraint_gen_contingency(pm, i) # if gen in contingency
        # constraint_gen_flexibility(pm, i) # permiited gen flexibility (ALL CONTINGENCIES)
    end
    for i in _PM.ids(pm, :bus)
        constraint_bus_contingency(pm, i) # if bus in contingency
    end
    for i in _PM.ids(pm, :branch)
        constraint_branch_contingency(pm, i) # if branch in contingency
    end
    for i in _PM.ids(pm, :load)
        constraint_load_deenergized(pm, i) # load cannot increase
    end


    # Add Objective Function
    # ----------------------
    # Maximise load served
    z_demand = _PM.var(pm, :z_demand)

    JuMP.@objective(pm.model, Max, sum(z_demand[i]*load["pd"] for (i,load) in _PM.ref(pm, :load)))

end


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
""
function _run_strg_mops(file, model_constructor::Type, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_mn_strg_ops;
        multinetwork=true, ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function _build_mn_strg_ops(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)

        variable_bus_active_indicator(pm, nw=n)
        variable_bus_voltage_on_off(pm, nw=n)

        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power_on_off(pm, nw=n)

        _PM.variable_storage_indicator(pm, nw=n)
        _PM.variable_storage_power_mi_on_off(pm, nw=n)

        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)
        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_generation_active(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_voltage_on_off(pm, i, nw=n)
            _PMR.constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            constraint_storage_active(pm, i, nw=n)
            _PM.constraint_storage_state(pm, i, nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PM.constraint_storage_on_off(pm,i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            constraint_branch_active(pm, i, nw=n)
            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :load, nw=n)
            constraint_load_active(pm, i, nw=n)
        end
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :gen, nw=n_2)
            constraint_gen_deenergized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :bus, nw=n_2)
            constraint_bus_deenergized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :storage, nw=n_2)
            constraint_storage_deenergized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_branch_deenergized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :load, nw=n_2)
            constraint_load_deenergized(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    # Add Objective Function
    # ----------------------
    # Maximize power delivery while minimizing wildfire risk
    n_1 = network_ids[1]
    if haskey(_PM.ref(pm, n_1), :risk_weight)
        alpha = _PM.ref(pm, n_1, :risk_weight)
    else
        Memento.warn(_PM._LOGGER, "network data should specify risk_weight, using 0.5 as a default")
        alpha = 0.5
    end

    for comp_type in [:gen, :load, :bus, :branch]
        for nwid in _PM.nw_ids(pm)
            for (id,comp) in  _PM.ref(pm, nwid, comp_type)
                if ~haskey(comp, "power_risk")
                    Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.0 as a default")
                    comp["power_risk"] = 0.0
                end
            end
        end
    end

    load_weight = Dict(nwid =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, nwid, :load))
    for nwid in _PM.nw_ids(pm))

    z_demand = Dict(nwid => _PM.var(pm, nwid, :z_demand) for nwid in _PM.nw_ids(pm))
    z_storage = Dict(nwid => _PM.var(pm, nwid, :z_storage) for nwid in _PM.nw_ids(pm))
    z_branch = Dict(nwid => _PM.var(pm, nwid, :z_branch) for nwid in _PM.nw_ids(pm))
    z_bus = Dict(nwid => _PM.var(pm, nwid, :z_bus) for nwid in _PM.nw_ids(pm))
    z_gen = Dict(nwid => _PM.var(pm, nwid, :z_gen) for nwid in _PM.nw_ids(pm))

    JuMP.@objective(pm.model, Max,
        sum(
            (1-alpha)*(
                sum(load["pd"]*load_weight[nwid][i]*z_demand[nwid][i] for (i,load) in _PM.ref(pm, nwid, :load))
            )
            -alpha*(
                sum(z_branch[nwid][i]*branch["power_risk"] for (i,branch) in _PM.ref(pm, nwid, :branch))+
                sum(z_bus[nwid][i]*bus["power_risk"] for (i,bus) in _PM.ref(pm, nwid, :bus))+
                sum(z_gen[nwid][i]*gen["power_risk"] for (i,gen) in _PM.ref(pm, nwid, :gen))+
                sum(z_demand[nwid][i]*load["power_risk"] for (i,load) in _PM.ref(pm, nwid, :load))+
                sum(z_storage[nwid][i]*storage["power_risk"] for (i,storage) in _PM.ref(pm, nwid, :storage))
            )
        for nwid in _PM.nw_ids(pm))
    )
end


# OPS w/ dcline constraints
# non-functional decause dcline on/off no implemented in power models
""
function _run_dcline_ops(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_dcline_ops;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function _build_dcline_ops(pm::_PM.AbstractPowerModel)

    variable_bus_active_indicator(pm)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_indicator(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_dcline_indicator(pm)
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
        constraint_dcline_active(pm, i) # not implemented
        _PM.constraint_dcline_power_losses_on_off(pm, i) # not implemented
    end

    # Add Objective
    # ------------------------------------
    # Maximize power delivery while minimizing wildfire risk
    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    z_dcline = _PM.var(pm, nw_id_default, :z_dcline)
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
            + sum(z_dcline[i]*dcline["power_risk"]+dcline["base_risk"] for (i,dcline) in _PM.ref(pm, :dcline))
        )
    )

end


# Load Redispatch for OPS
"Caculate power flow for a fixed topology, allowing load shed"
function _run_redispatch(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, _build_redispatch; multinetwork=false,
    ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end

""
function _build_redispatch(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)

    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        _PMR.constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    # Objective
    z_demand = _PM.var(pm, :z_demand)
    load_weight = Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, :load))
    JuMP.@objective(pm.model, Max,
        sum(load_weight[i]*abs(load["pd"])*z_demand[i] for (i,load) in _PM.ref(pm, :load))
    )
end

# MOPS Threshold (single shutoff variable across periods)
""
function _run_strg_mops_threshold(file, model_constructor::Type, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, _build_mn_strg_ops_threshold;
        multinetwork=true, ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function _build_mn_strg_ops_threshold(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)

        variable_bus_active_indicator(pm, nw=n)
        variable_bus_voltage_on_off(pm, nw=n)

        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power_on_off(pm, nw=n)

        _PM.variable_storage_indicator(pm, nw=n)
        _PM.variable_storage_power_mi_on_off(pm, nw=n)

        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)
        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_generation_active(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_voltage_on_off(pm, i, nw=n)
            _PMR.constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            constraint_storage_active(pm, i, nw=n)
            _PM.constraint_storage_state(pm, i, nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PM.constraint_storage_on_off(pm,i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            constraint_branch_active(pm, i, nw=n)
            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :load, nw=n)
            constraint_load_active(pm, i, nw=n)
        end
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    constraint_load_served(pm) # threshold for load served
    consistent_shutoff_variables(pm)

    # Add Objective Function
    # ----------------------
    # Maximize power delivery while minimizing wildfire risk
    n_1 = network_ids[1]
    if haskey(_PM.ref(pm, n_1), :risk_weight)
        alpha = _PM.ref(pm, n_1, :risk_weight)
    else
        Memento.warn(_PM._LOGGER, "network data should specify risk_weight, using 0.5 as a default")
        alpha = 0.5
    end

    for comp_type in [:gen, :load, :bus, :branch]
        for nwid in _PM.nw_ids(pm)
            for (id,comp) in  _PM.ref(pm, nwid, comp_type)
                if ~haskey(comp, "power_risk")
                    Memento.warn(_PM._LOGGER, "$(comp_type) $(id) does not have a power_risk value, using 0.0 as a default")
                    comp["power_risk"] = 0.0
                end
            end
        end
    end

    load_weight = Dict(nwid =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, nwid, :load))
    for nwid in _PM.nw_ids(pm))

    z_demand = Dict(nwid => _PM.var(pm, nwid, :z_demand) for nwid in _PM.nw_ids(pm))
    z_storage = Dict(nwid => _PM.var(pm, nwid, :z_storage) for nwid in _PM.nw_ids(pm))
    z_branch = Dict(nwid => _PM.var(pm, nwid, :z_branch) for nwid in _PM.nw_ids(pm))
    z_bus = Dict(nwid => _PM.var(pm, nwid, :z_bus) for nwid in _PM.nw_ids(pm))
    z_gen = Dict(nwid => _PM.var(pm, nwid, :z_gen) for nwid in _PM.nw_ids(pm))

    JuMP.@objective(pm.model, Min,
        sum(
            sum(z_branch[nwid][i]*branch["power_risk"] for (i,branch) in _PM.ref(pm, nwid, :branch))+
            sum(z_bus[nwid][i]*bus["power_risk"] for (i,bus) in _PM.ref(pm, nwid, :bus))+
            sum(z_gen[nwid][i]*gen["power_risk"] for (i,gen) in _PM.ref(pm, nwid, :gen))+
            sum(z_demand[nwid][i]*load["power_risk"] for (i,load) in _PM.ref(pm, nwid, :load))+
            sum(z_storage[nwid][i]*storage["power_risk"] for (i,storage) in _PM.ref(pm, nwid, :storage))
            for nwid in _PM.nw_ids(pm)
        )
    )
end


