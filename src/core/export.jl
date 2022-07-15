# PowerModelsWildfire exports everything except internal symbols, which are defined as
# those whose name starts with an underscore. If you don't want all of these
# symbols in your environment, then use `import PowerModelsWildfire` instead of
# `using PowerModelsWildfire`.

# Do not add PowerModelsWildfire-defined symbols to this exclude list. Instead, rename
# them with an underscore.

const _EXCLUDE_SYMBOLS = [Symbol(@__MODULE__), :eval, :include]

for sym in names(@__MODULE__, all=true)
    sym_string = string(sym)
    if sym in _EXCLUDE_SYMBOLS || startswith(sym_string, "_")
        continue
    end
    if !(Base.isidentifier(sym) || (startswith(sym_string, "@") &&
         Base.isidentifier(sym_string[2:end])))
       continue
    end
    #println("$(sym)")
    @eval export $sym
end

# the follow items are also exported for user-friendlyness when calling
# `using PowerModelsWildfire`

# so that users do not need to import JuMP to use a solver with PowerModelsWildfire
import JuMP: with_optimizer
export with_optimizer

import JuMP: TerminationStatusCode
export TerminationStatusCode

import JuMP: ResultStatusCode
export ResultStatusCode

for status_code_enum in [TerminationStatusCode, ResultStatusCode]
    for status_code in instances(status_code_enum)
        @eval import JuMP: $(Symbol(status_code))
        @eval export $(Symbol(status_code))
    end
end