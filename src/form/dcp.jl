function constraint_model_voltage_active(pm::_PM.AbstractDCPModel, n::Int, c::Int)
end

""
function variable_voltage_active(pm::_PM.AbstractDCPModel; kwargs...)
    _PM.variable_voltage_angle(pm; kwargs...)
end

"no vm values to turn off"
function constraint_bus_active(pm::_PM.AbstractDCPModel, i::Int; nw::Int=pm.cnw, kwargs...)
end