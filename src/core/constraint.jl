

""
function constraint_branch_restoration_indicator_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    branch = _PM.ref(pm, n, :branch, i)
    z_branch = _PM.var(pm, n, :z_branch, i)
    branch_restoration = z_branch = _PM.var(pm, n, :branch_restoration, i)

    JuMP.@constraint(pm.model, branch_restoration <= (1-branch["br_status"]))
    JuMP.@constraint(pm.model, branch_restoration <= z_branch )
    JuMP.@constraint(pm.model, branch_restoration >= (1-branch["br_status"]) + z_branch  - 1 )
end


""
function constraint_branch_restoration_indicator(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int)

    z_branch_1 = _PM.var(pm, n_1, :z_branch, i)
    z_branch_2 = _PM.var(pm, n_2, :z_branch, i)
    branch_restoration =  _PM.var(pm, n_2, :branch_restoration, i)

    JuMP.@constraint(pm.model, branch_restoration <= (1-z_branch_1))
    JuMP.@constraint(pm.model, branch_restoration <= z_branch_2 )
    JuMP.@constraint(pm.model, branch_restoration >= (1-z_branch_1) + z_branch_2  - 1 )
end


""
function constraint_bus_restoration_indicator_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    bus = _PM.ref(pm, n, :bus, i)
    z_bus = _PM.var(pm, n, :z_bus, i)
    bus_restoration = z_bus = _PM.var(pm, n, :bus_restoration, i)

    intitial_bus_state = bus["bus_type"] != 4 ? 1 : 0

    JuMP.@constraint(pm.model, bus_restoration <= (1-intitial_bus_state))
    JuMP.@constraint(pm.model, bus_restoration <= z_bus )
    JuMP.@constraint(pm.model, bus_restoration >= (1-intitial_bus_state) + z_bus  - 1 )
end


""
function constraint_bus_restoration_indicator(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int)

    z_bus_1 = _PM.var(pm, n_1, :z_bus, i)
    z_bus_2 = _PM.var(pm, n_2, :z_bus, i)
    bus_restoration =  _PM.var(pm, n_2, :bus_restoration, i)

    JuMP.@constraint(pm.model, bus_restoration <= (1-z_bus_1))
    JuMP.@constraint(pm.model, bus_restoration <= z_bus_2 )
    JuMP.@constraint(pm.model, bus_restoration >= (1-z_bus_1) + z_bus_2  - 1 )
end


""
function constraint_gen_restoration_indicator_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    gen = _PM.ref(pm, n, :gen, i)
    z_gen = _PM.var(pm, n, :z_gen, i)
    gen_restoration = z_gen = _PM.var(pm, n, :gen_restoration, i)

    JuMP.@constraint(pm.model, gen_restoration <= (1-gen["gen_status"]))
    JuMP.@constraint(pm.model, gen_restoration <= z_gen )
    JuMP.@constraint(pm.model, gen_restoration >= (1-gen["gen_status"]) + z_gen  - 1 )
end


""
function constraint_gen_restoration_indicator(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int)

    z_gen_1 = _PM.var(pm, n_1, :z_gen, i)
    z_gen_2 = _PM.var(pm, n_2, :z_gen, i)
    gen_restoration =  _PM.var(pm, n_2, :gen_restoration, i)

    JuMP.@constraint(pm.model, gen_restoration <= (1-z_gen_1))
    JuMP.@constraint(pm.model, gen_restoration <= z_gen_2 )
    JuMP.@constraint(pm.model, gen_restoration >= (1-z_gen_1) + z_gen_2  - 1 )
end


""
function constraint_restoration_budget(pm::_PM.AbstractPowerModel, n::Int, branch_restoration_cost, bus_restoration_cost, gen_restoration_cost, restoration_budget)
    branch_restoration =  _PM.var(pm, n, :branch_restoration)
    gen_restoration =  _PM.var(pm, n, :gen_restoration)
    bus_restoration =  _PM.var(pm, n, :bus_restoration)

    JuMP.@constraint(pm.model,
        sum(branch_restoration[id]*cost for (id,cost) in branch_restoration_cost) +
        sum(bus_restoration[id]*cost for (id,cost) in bus_restoration_cost) +
        sum(gen_restoration[id]*cost for (id,cost) in gen_restoration_cost) <= restoration_budget
    )
end

function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)
    vm = _PM.var(pm, n, :vm, i)
    z_bus = _PM.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, vm <= vmax*z_bus)
    JuMP.@constraint(pm.model, vm >= vmin*z_bus)
end

function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)
    w = _PM.var(pm, n, :w, i)
    z_bus = _PM.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, w <= vmax^2*z_bus)
    JuMP.@constraint(pm.model, w >= vmin^2*z_bus)
end

function constraint_load_served(pm::_PM.AbstractPowerModel)
    nw1 = first(_PM.nw_ids(pm))
    threshold= _PM.ref(pm, nw1, :threshold)
    total_demand = sum(sum(load["pd"] for (id,load) in  _PM.ref(pm, nwid, :load)) for nwid in _PM.nw_ids(pm))
    z_demand = Dict(nwid => _PM.var(pm, nwid, :z_demand) for nwid in _PM.nw_ids(pm))

    JuMP.@constraint(pm.model,
        sum(
            sum(load["pd"]*z_demand[nwid][i] for (i,load) in _PM.ref(pm, nwid, :load))
            for nwid in _PM.nw_ids(pm)
        ) >= threshold*total_demand
    )
end

function consistent_shutoff_variables(pm::_PM.AbstractPowerModel)
    nw1 = first(_PM.nw_ids(pm))
    for nwid in _PM.nw_ids(pm)
        for i in _PM.ids(pm, nwid, :branch)
            z_branch_1 = _PM.var(pm, nw1, :z_branch, i)
            z_branch_nwid = _PM.var(pm, nwid, :z_branch, i)
            JuMP.@constraint(pm.model, z_branch_1 == z_branch_nwid)
        end
        for i in _PM.ids(pm, nwid, :gen)
            z_gen_1 = _PM.var(pm, nw1, :z_gen, i)
            z_gen_nwid = _PM.var(pm, nwid, :z_gen, i)
            JuMP.@constraint(pm.model, z_gen_1 == z_gen_nwid)
        end
        for i in _PM.ids(pm, nwid, :bus)
            z_bus_1 = _PM.var(pm, nw1, :z_bus, i)
            z_bus_nwid = _PM.var(pm, nwid, :z_bus, i)
            JuMP.@constraint(pm.model, z_bus_1 == z_bus_nwid)
        end
    end
end

