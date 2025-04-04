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

proc resolveVariable*(vars: CssVariables, cs: ConstraintSize): ConstraintSize =
  ## Resolves a constraint size, looking up variables if needed
  ## Returns the resolved constraint size
  case cs.kind
  of UiVariable:
    if vars != nil and cs.varIdx in vars.variables:
      result = vars.variables[cs.varIdx]
      # Handle recursive variable resolution (up to a limit to prevent cycles)
      var resolveCount = 0
      while result.kind == UiVariable and resolveCount < 10:
        if result.varIdx in vars.variables:
          result = vars.variables[result.varIdx]
          inc resolveCount
        else:
          break
      if result.kind == UiVariable and resolveCount >= 10:
        # Prevent infinite recursion, return a default value
        result = ConstraintSize(kind: UiAuto)
    else:
      # Variable not found, return a default value
      result = ConstraintSize(kind: UiAuto)
  else:
    result = cs

proc resolveVariable*(vars: CssVariables, cx: Constraint): Constraint =
  ## Resolves variables in a constraint
  ## Returns a new constraint with all variables resolved
  case cx.kind
  of UiValue:
    result = csValue(vars.resolveVariable(cx.value))
  of UiMin:
    result = csMin(vars.resolveVariable(cx.lmin), vars.resolveVariable(cx.rmin))
  of UiMax:
    result = csMax(vars.resolveVariable(cx.lmax), vars.resolveVariable(cx.rmax))
  of UiAdd:
    result = csAdd(vars.resolveVariable(cx.ladd), vars.resolveVariable(cx.radd))
  of UiSub:
    result = csSub(vars.resolveVariable(cx.lsub), vars.resolveVariable(cx.rsub))
  of UiMinMax:
    result = csMinMax(vars.resolveVariable(cx.lmm), vars.resolveVariable(cx.rmm))
  of UiNone, UiEnd:
    result = cx

proc csVar*(vars: CssVariables, name: string): Constraint =
  ## Creates a constraint for a CSS variable by name
  ## If the variable doesn't exist, it will be created with a default value
  if name in vars.names:
    csVar(vars.names[name])
  else:
    return vars.registerVariable(name, ConstraintSize(kind: UiAuto))