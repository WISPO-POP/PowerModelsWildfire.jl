
""
function variable_bus_voltage_on_off(pm::_PM.AbstractACPModel; kwargs...)
    _PM.variable_bus_voltage_angle(pm; kwargs...)
    _PMR.variable_bus_voltage_magnitude_on_off(pm; kwargs...)
end


""
function constraint_bus_voltage_on_off(pm::_PM.AbstractACPModel, nw::Int, i::Int; kwargs...)
        constraint_voltage_magnitude_on_off(pm, i; nw=nw)
end
