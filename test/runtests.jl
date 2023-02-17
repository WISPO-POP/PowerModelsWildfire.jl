
using PowerModelsWildfire
import PowerModels
import PowerModelsRestoration
import InfrastructureModels

import Memento


import HiGHS
import Ipopt
import Juniper

import JuMP

using Test

Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
PowerModels.logger_config!("error")


milp_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
minlp_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])

@testset "PowerModelsWildfire" begin

    include("./ops.jl")
    include("./mops.jl")
    include("./area_heuristic.jl")
    include("./voltage_heuristic.jl")

end


