# PowerModelsWildfire.jl

[![Build Status](https://travis-ci.com/WISPO-POP/PowerPlots.jl.svg?branch=master)](https://travis-ci.com/WISPO-POP/PowerModelsWildfire.jl)
[![Codecov](https://codecov.io/gh/WISPO-POP/PowerPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/WISPO-POP/PowerModelsWildfire.jl)

This package provides functions to identify an optimal de-energization strategy for a power system operated in a wildfire prone area.  We refer to this optimization problem as the optimal power shutoff (OPS) problem, which is a mixed-integer linear optimization problem. More information about the modeling and mathematical formulation of this problem, as well as the input data, can be found in this [publication](https://arxiv.org/abs/2004.07156).

The package is currently unregistered.  You can add the package using the command:
```
Pkg> add https://github.com/WISPO-POP/PowerModelsWildfire.jl.git
```

In addition to the code itself, this package also contains the test case data we used in our publication. This data can be downloaded [here](https://github.com/WISPO-POP/PowerModelsWildfire.jl/blob/master/test/networks/RTS_GMLC_risk.m).

We hope you will find this code and/or the test case useful! If you want to use either the code or the test case, we kindly request that you cite our [publication](https://arxiv.org/abs/2004.07156):

```
@article{rhodes2020balancing,
  title={Balancing Wildfire Risk and Power Outages through Optimized Power Shut-Offs},
  author={Rhodes, Noah and Ntaimo, Lewis and Roald, Line},
  journal={arXiv preprint arXiv:2004.07156},
  year={2020}
}
```


## Using `PowerModelsWildfire`
Below is a basic example of how to load case data, run the OPS problem and access the solutions. For more information about the modeling of the optimization problem, the definitions of the risk values for `"power_risk"` and `"base_risk"` for each component and the system-wide trade-off parameter `"risk_weight"`, we refer to the publication listed above.

```Julia
using PowerModels, PowerModelsWildfire
using Cbc

# Load case data
case = parse_file("case14_risk.m")

# See the wildfire risk values of branch number 12
println(case["branch"]["12"]["power_risk"])
println(case["branch"]["12"]["base_risk"])

# Set risk parameter which determines trade-off between serving load and mitigating wildfire risk
case["risk_weight"] = 0.15 # values between 0 and 1, smaller values emphasize load delivery

# Run OPS problem
solution = PowerModelsWildfire.run_ops(case, DCPPowerModel, Cbc.Optimizer);

# Check whether branch 12 was deenergized
println(solution["solution"]["branch"]["12"]["br_status"])  # 0.0 indicates off, 1.0 indicates on
```

Running the OPS problem requires the definition of risk values `"power_risk"` and `"base_risk"` for each component. These can be added directly to a matpower file as seen in the test networks in [PowerModelsWildfire/Test/networks](https://github.com/WISPO-POP/PowerModelsWildfire.jl/tree/master/test/networks). Alternatively, they can be added to the PowerModels dictionary by adding the key `"power_risk"` and `"base_risk"` to each component, as illustrated below.

```Julia
for comp_type in ["bus","gen","branch","load"]
  for (comp_id, comp) in case[comp_type]
    comp["power_risk"] = component_risk_value
    comp["base_risk"] = background_risk_value
  end
end
```
