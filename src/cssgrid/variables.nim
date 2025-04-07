import std/tables
import constraints

type
  CssVariables* = ref object of RootObj
    variables*: Table[CssVarId, ConstraintSize]
    names*: Table[string, CssVarId]

# CSS Variable functions
proc newCssVariables*(): CssVariables =
  ## Creates a new CSS variables container
  new(result)
  result.variables = initTable[CssVarId, ConstraintSize]()
  result.names = initTable[string, CssVarId]()

proc registerVariable*(vars: CssVariables, name: string): CssVarId =
  ## Registers a new CSS variable with the given name
  ## Returns the variable index
  if name in vars.names:
    result = vars.names[name]
  else:
    result = CssVarId(vars.names.len + 1)
    vars.names[name] = result

proc setVariable*(vars: CssVariables, idx: CssVarId, value: ConstraintSize) =
  ## Registers a new CSS variable with the given name and value
  ## Returns the variable index
  vars.variables[idx] = value

proc setVariable*(vars: CssVariables, idx: CssVarId, value: Constraint) =
  ## Registers a new CSS variable with the given name and constraint value
  ## Returns the variable index
  if value.kind == UiValue:
    vars.setVariable(idx, value.value)
  else:
    # For complex constraints, we can't directly store them
    # We'd need an expanded CssVariables type to handle this
    raise newException(ValueError, "Only simple constraint values can be registered as variables")

proc lookupVariable*(vars: CssVariables, name: string, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by name
  if name in vars.names:
    let idx = vars.names[name]
    if idx in vars.variables:
      size = vars.variables[idx]
      return true
  return false

proc lookupVariable*(vars: CssVariables, idx: CssVarId, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by index
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
      return false
    else:
      val = res
      return true
  else:
    return false

proc resolveVariable*(vars: CssVariables, cx: Constraint, val: var ConstraintSize): bool =
  ## Resolves a constraint, looking up variables if needed
  if cx.kind == UiValue:
    return vars.resolveVariable(cx.value.varIdx, val)
  else:
    return false

proc csVar*(vars: CssVariables, name: string, value: Constraint = csAuto()): Constraint =
  ## Creates a constraint for a CSS variable by name
  ## If the variable doesn't exist, it will be created with a default value
  let idx = vars.registerVariable(name)
  vars.setVariable(idx, value)
  return csVar(idx)
