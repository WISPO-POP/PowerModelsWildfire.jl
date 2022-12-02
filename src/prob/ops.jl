
""
function run_ops(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, build_ops;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function build_ops(pm::_PM.AbstractPowerModel)

    variable_bus_active_indicator(pm)
    _PMR.variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_storage_indicator(pm)
    _PM.variable_storage_power_mi_on_off(pm)

    _PM.variable_branch_indicator(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    _PMR.constraint_model_voltage_damage(pm)
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        constraint_generation_active(pm, i)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_bus_active(pm, i)
        _PMR.constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :storage)
        constraint_storage_active(pm, i)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        _PM.constraint_storage_on_off(pm,i)
        _PM.constraint_storage_loss(pm, i)
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

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i) #not active decision variables
    end

    # Add Objective
    # ------------------------------------
    # Maximize power delivery while minimizing wildfire risk
    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    # z_storage = _PM.var(pm, nw_id_default, :z_storage)
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
            # + sum(z_storage[i]*storage["power_risk"]+storage["base_risk"] for (i,storage) in _PM.ref(pm, :storage))
        )
    )

end

""
function run_mops(file, model_constructor, optimizer, kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, build_mn_ops;
        multinetwork=true, ref_extensions=[_PM.ref_add_on_off_va_bounds!], kwargs...)
end


function build_mn_ops(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        variable_bus_active_indicator(pm, nw=n)
        variable_branch_restoration_indicator(pm, nw=n)
        variable_gen_restoration_indicator(pm, nw=n)
        variable_bus_restoration_indicator(pm, nw=n)
        variable_load_restoration_indicator(pm, nw=n)

        _PMR.variable_bus_voltage_on_off(pm, nw=n)

        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power_on_off(pm, nw=n)

        _PM.variable_storage_indicator(pm, nw=n)
        _PM.variable_storage_power_mi_on_off(pm, nw=n)

        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_dcline_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PMR.constraint_model_voltage_damage(pm, nw=n)
        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_generation_active(pm, i, nw=n)
            _PM.constraint_gen_power_on_off(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_active(pm, i, nw=n)
            _PMR.constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            constraint_storage_active(pm, i, nw=n)
            _PM.constraint_storage_state(pm, i, nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PM.constraint_storage_on_off(pm,i, nw=n)
            _PM.constraint_storage_loss(pm, i, nw=n)
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

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n) #not active decision variables
        end

        constraint_restoration_budget(pm, nw=n)
    end

    network_ids = sort(collect(_PM.nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :branch, nw=n_1)
        constraint_branch_restoration_indicator_initial(pm, n_1, i)
    end
    for i in _PM.ids(pm, :gen, nw=n_1)
        constraint_gen_restoration_indicator_initial(pm, n_1, i)
    end
    for i in _PM.ids(pm, :bus, nw=n_1)
        constraint_bus_restoration_indicator_initial(pm, n_1, i)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_branch_restoration_indicator(pm, n_1, n_2, i)
        end
        for i in _PM.ids(pm, :gen, nw=n_2)
            constraint_gen_restoration_indicator(pm, n_1, n_2, i)
        end
        for i in _PM.ids(pm, :bus, nw=n_2)
            constraint_bus_restoration_indicator(pm, n_1, n_2, i)
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

    if haskey(_PM.ref(pm, n_1), :disable_cost)
        disable_cost = _PM.ref(pm, n_1, :disable_cost)
    else
        Memento.warn(_PM._LOGGER, "network data should specify disable_cost, using 10.0 as a default")
        disable_cost = 10.0
    end



    for comp_type in [:gen, :load, :bus, :branch]
        for nwid in _PM.nw_ids(pm)
            for (id,comp) in  _PM.ref(pm, nwid, comp_type)
                if ~haskey(comp, "power_risk")
                    @warn "$(comp_type) $(id) does not have a power_risk value, using 0.0 as a default"
                    comp["power_risk"] = 0.0
                end
            end
        end
    end

    load_weight = Dict(nwid =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, nwid, :load))
    for nwid in _PM.nw_ids(pm))

    # scale based on total load demand and risk
    total_load = sum(sum(load["pd"] for (load_id,load) in nw[:load]) for (nwid,nw) in  _PM.nws(pm))
    total_risk =
    sum(sum(sum(get(comp,"power_risk",0)
                for (compid,comp) in  _PM.ref(pm, nwid, comp_type))
            for nwid in  _PM.nw_ids(pm))
        for comp_type in [:branch,:gen,:bus,:load]
    )

    z_demand = Dict(nwid => _PM.var(pm, nwid, :z_demand) for nwid in _PM.nw_ids(pm))
    z_branch = Dict(nwid => _PM.var(pm, nwid, :z_branch) for nwid in _PM.nw_ids(pm))
    z_bus = Dict(nwid => _PM.var(pm, nwid, :z_bus) for nwid in _PM.nw_ids(pm))
    z_gen = Dict(nwid => _PM.var(pm, nwid, :z_gen) for nwid in _PM.nw_ids(pm))

    JuMP.@objective(pm.model, Max,
        sum(
            (1-alpha)*(
                sum(load["pd"]*load_weight[nwid][i]*z_demand[nwid][i]/total_load for (i,load) in _PM.ref(pm, nwid, :load))
            )
            -alpha*(
                sum(z_branch[nwid][i]*branch["power_risk"]/total_risk for (i,branch) in _PM.ref(pm, nwid, :branch))+
                sum((1-z_branch[nwid][i])*disable_cost/total_risk for (i,branch) in _PM.ref(pm, nwid, :branch))+
                sum(z_bus[nwid][i]*bus["power_risk"]/total_risk for (i,bus) in _PM.ref(pm, nwid, :bus))+
                sum((1-z_bus[nwid][i])*disable_cost/total_risk for (i,bus) in _PM.ref(pm, nwid, :bus))+
                sum(z_gen[nwid][i]*gen["power_risk"]/total_risk for (i,gen) in _PM.ref(pm, nwid, :gen))+
                sum((1-z_gen[nwid][i])*disable_cost/total_risk for (i,gen) in _PM.ref(pm, nwid, :gen))
            )
        for nwid in _PM.nw_ids(pm))
    )
end
