
""
function variable_bus_voltage_on_off(pm::_PM.AbstractWRModels; kwargs...)
    _PMR.variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
    _PM.variable_branch_voltage_magnitude_fr_sqr_on_off(pm; kwargs...)
    _PM.variable_branch_voltage_magnitude_to_sqr_on_off(pm; kwargs...)

    _PM.variable_branch_voltage_product_on_off(pm; kwargs...)
end


""
function constraint_bus_voltage_on_off(pm::_PM.AbstractWRModels, i::Int; nw::Int=nw_id_default, kwargs...)
    constraint_voltage_magnitude_sqr_on_off(pm, i; nw=nw)
end
