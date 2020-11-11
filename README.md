# PowerModelsWildfire.jl

This package provides functions to run a optimal power shutoff on a power grid.

The package is currently unregistered.  You can add the package using the command:
```
Pkg> add https://github.com/WISPO-POP/PowerModelsWildfire.jl.git
```


## Using `PowerModelsWildfire`
Below is a basic example of using  the OPS problem.
```Julia
using PowerModels, PowerModelsWildfire
using Cbc

case = parse_file(file)
case["risk_weight"] = 0.15 # weight <0.5 prefers load

solution = PowerModelsWildfire.run_risky_opf(case, DCPPowerModel, Cbc.Optimizer);
```

This requires having risk values for each component. These can be added directly to a matpower file as seen in the test networks in [PowerModelsWildfire/Test/networks](https://github.com/WISPO-POP/PowerModelsWildfire.jl/tree/master/test/networks). Alternatively, they can be added to the PowerModels dictionary by adding the key `"power_risk"` and `"base_risk"` to each component.

```Julia
for comp_type in ["bus","gen","branch","load"]
  for (comp_id, comp) in case[comp_type]
    comp["power_risk"] = component_risk_value
    comp["base_risk"] = background_risk_value
  end
end
```

