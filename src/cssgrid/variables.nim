import std/tables
import constraints

type
  CssVariables* = ref object of RootObj
    variables*: Table[CssVarId, ConstraintSize]
    names*: Table[string, CssVarId]

proc csVar*(idx: CssVarId): Constraint =
  ## Creates a constraint for a CSS variable by index
  csValue(ConstraintSize(kind: UiVariable, varIdx: idx))

# CSS Variable functions
proc newCssVariables*(): CssVariables =
  ## Creates a new CSS variables container
  new(result)
  result.variables = initTable[CssVarId, ConstraintSize]()
  result.names = initTable[string, CssVarId]()

proc registerVariable*(vars: CssVariables, name: string, value: ConstraintSize): Constraint =
  ## Registers a new CSS variable with the given name and value
  ## Returns the variable index
  if name in vars.names:
    let idx = vars.names[name]
    vars.variables[idx] = value
    return csVar(idx)
  else:
    let idx = CssVarId(vars.variables.len + 1)
    vars.variables[idx] = value
    vars.names[name] = idx
    return csVar(idx)

proc registerVariable*(vars: CssVariables, name: string, value: Constraint): Constraint =
  ## Registers a new CSS variable with the given name and constraint value
  ## Returns the variable index
  if value.kind == UiValue:
    return vars.registerVariable(name, value.value)
  else:
    # For complex constraints, we can't directly store them
    # We'd need an expanded CssVariables type to handle this
    raise newException(ValueError, "Can only register simple constraint values as variables")

proc lookupVariable*(vars: CssVariables, name: string, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by name
  ## Returns Some(value) if found, None otherwise
  if name in vars.names:
    let idx = vars.names[name]
    if idx in vars.variables:
      size = vars.variables[idx]
      return true
  return false

proc lookupVariable*(vars: CssVariables, idx: CssVarId, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by index
  ## Returns Some(value) if found, None otherwise
  if idx in vars.variables:
    size = vars.variables[idx]
    return true
  return false

proc variableName*(vars: CssVariables, cs: ConstraintSize): string =
  ## Returns the name of a CSS variable by index
  if cs.kind == UiVariable:
    for name, idx in vars.names:
      if idx == cs.varIdx:
        return name

proc resolveVariable*(vars: CssVariables, varIdx: CssVarId, val: var ConstraintSize): bool =
  ## Resolves a constraint size, looking up variables if needed
  ## Returns the resolved constraint size
  if vars != nil and varIdx in vars.variables:
    var res = vars.variables[varIdx]
    # Handle recursive variable resolution (up to a limit to prevent cycles)
    var resolveCount = 0
    while res.kind == UiVariable and resolveCount < 10:
      if res.varIdx in vars.variables:
        res = vars.variables[res.varIdx]
        inc resolveCount
      else:
        break
    if res.kind == UiVariable:
      # Prevent infinite recursion, return a default value
      val = ConstraintSize(kind: UiAuto)
      return true
    else:
      val = res
      return true
  else:
    return false

# proc resolveVariable*(vars: CssVariables, varIdx: CssVarId, val: var Constraint): bool =
#   ## Resolves variables in a constraint
#   ## Returns a new constraint with all variables resolved
#   var lhs, rhs: ConstraintSize
#   case val.kind
#   of UiValue:
#     if vars.resolveVariable(val.value, lhs):
#       val = csValue(lhs)
#       return true
#   of UiMin:
#     if vars.resolveVariable(val.lmin, lhs) or vars.resolveVariable(val.rmin, rhs):
#       val = csMin(lhs, rhs)
#       return true
#   of UiMax:
#     if vars.resolveVariable(val.lmax, lhs) or vars.resolveVariable(val.rmax, rhs):
#       val = csMax(lhs, rhs)
#       return true
#   of UiAdd:
#     if vars.resolveVariable(val.ladd, lhs) or vars.resolveVariable(val.radd, rhs):
#       val = csAdd(lhs, rhs)
#       return true
#   of UiSub:
#     if vars.resolveVariable(val.lsub, lhs) or vars.resolveVariable(val.rsub, rhs):
#       val = csSub(lhs, rhs)
#       return true
#   of UiMinMax:
#     if vars.resolveVariable(val.lmm, lhs) or vars.resolveVariable(val.rmm, rhs):
#       val = csMinMax(lhs, rhs)
#       return true
#   of UiNone, UiEnd:
#     val = cxNone()
#     return true

proc csVar*(vars: CssVariables, name: string): Constraint =
  ## Creates a constraint for a CSS variable by name
  ## If the variable doesn't exist, it will be created with a default value
  if name in vars.names:
    csVar(vars.names[name])
  else:
    return vars.registerVariable(name, ConstraintSize(kind: UiAuto))