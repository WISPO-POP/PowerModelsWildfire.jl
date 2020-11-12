# PowerModelsWildfire.jl

This package provides functions to identify an optimal de-energization strategy for a power system operated in a wildfire prone area.  We refer to this optimization problem as the optimal power shutoff (OPS) problem, which is a mixed-integer linear optimization problem. More information about the modeling and mathematical formulation of this problem, as well as the input data, can be found in this [publication](https://arxiv.org/abs/2004.07156).

The package is currently unregistered.  You can add the package using the command:
```
Pkg> add https://github.com/WISPO-POP/PowerModelsWildfire.jl.git
```
If you find this code useful, we kindly request that you cite our [publication](https://arxiv.org/abs/2004.07156):

```
@article{rhodes2020balancing,
  title={Balancing Wildfire Risk and Power Outages through Optimized Power Shut-Offs},
  author={Rhodes, Noah and Ntaimo, Lewis and Roald, Line},
  journal={arXiv preprint arXiv:2004.07156},
  year={2020}
}
```


## Using `PowerModelsWildfire`
Below is a basic example of how to run the OPS problem.
```Julia
using PowerModels, PowerModelsWildfire
using Cbc

case = parse_file(file)
case["risk_weight"] = 0.15 # weight <0.5 prefers load

solution = PowerModelsWildfire.run_ops(case, DCPPowerModel, Cbc.Optimizer);
```

Running the OPS problem requires the definition of risk values for each component. These can be added directly to a matpower file as seen in the test networks in [PowerModelsWildfire/Test/networks](https://github.com/WISPO-POP/PowerModelsWildfire.jl/tree/master/test/networks). Alternatively, they can be added to the PowerModels dictionary by adding the key `"power_risk"` and `"base_risk"` to each component, as illustrated below.

```Julia
for comp_type in ["bus","gen","branch","load"]
  for (comp_id, comp) in case[comp_type]
    comp["power_risk"] = component_risk_value
    comp["base_risk"] = background_risk_value
  end
end
```

