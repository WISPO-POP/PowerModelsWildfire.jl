

""
function constraint_restoration_indicator_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    branch = _PM.ref(pm, n, :branch, i)
    z_branch = _PM.var(pm, n, :z_branch, i)
    branch_restoration = z_branch = _PM.var(pm, n, :branch_restoration, i)

    JuMP.@constraint(pm.model, branch_restoration <= (1-branch["br_status"]))
    JuMP.@constraint(pm.model, branch_restoration <= z_branch )
    JuMP.@constraint(pm.model, branch_restoration >= (1-branch["br_status"]) + z_branch  - 1 )
end

""
function constraint_restoration_indicator(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int)

    z_branch_1 = _PM.var(pm, n_1, :z_branch, i)
    z_branch_2 = _PM.var(pm, n_2, :z_branch, i)
    branch_restoration =  _PM.var(pm, n_2, :branch_restoration, i)

    JuMP.@constraint(pm.model, branch_restoration <= (1-z_branch_1))
    JuMP.@constraint(pm.model, branch_restoration <= z_branch_2 )
    JuMP.@constraint(pm.model, branch_restoration >= (1-z_branch_1) + z_branch_2  - 1 )
end

""
function constraint_restoration_budget(pm::_PM.AbstractPowerModel, n::Int, branch_restoration_cost, restoration_budget)
    branch_restoration =  _PM.var(pm, n, :branch_restoration)

    JuMP.@constraint(pm.model,
        sum(branch_restoration[id]*cost for (id,cost) in branch_restoration_cost) <= restoration_budget
    )

end