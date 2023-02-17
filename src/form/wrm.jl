
function constraint_bus_voltage_on_off(pm::_PM.AbstractWRMModel, i::Int; nw::Int=nw_id_default)
    constraint_voltage_magnitude_sqr_on_off(pm, i; nw=nw)
end
