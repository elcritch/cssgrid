import std/tables
import std/strutils
import constraints
import gridtypes

type
  CssFunc* = proc(val: ConstraintSize): ConstraintSize {.nimcall.}

  CssVariables* = ref object of RootObj
    variables*: Table[CssVarId, ConstraintSize]
    funcs*: Table[CssVarId, CssFunc]
    names*: Table[Atom, CssVarId]

# CSS Variable functions
proc newCssVariables*(): CssVariables =
  ## Creates a new CSS variables container
  new(result)
  result.variables = initTable[CssVarId, ConstraintSize]()
  result.names = initTable[Atom, CssVarId]()

proc registerVariable*(vars: CssVariables, name: Atom): CssVarId =
  ## Registers a new CSS variable with the given name
  ## Returns the variable index
  if name in vars.names:
    result = vars.names[name]
  else:
    result = CssVarId(vars.names.len + 1)
    vars.names[name] = result

proc registerVariable*(vars: CssVariables, name: static string): CssVarId =
  ## Registers a new CSS variable with the given name
  ## Returns the variable index
  let nameAtom = atom(name)
  result = vars.registerVariable(nameAtom)

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

proc setFunction*(vars: CssVariables, idx: CssVarId, value: CssFunc) =
  ## Registers a new CSS function with the given name and value
  ## Returns the function index
  vars.funcs[idx] = value

proc lookupVariable*(vars: CssVariables, name: Atom, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by name
  if name in vars.names:
    let idx = vars.names[name]
    if idx in vars.variables:
      size = vars.variables[idx]
      return true
  return false

proc lookupVariable*(vars: CssVariables, name: static string, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by name
  let nameAtom = atom(name)
  return vars.lookupVariable(nameAtom, size)

proc lookupVariable*(vars: CssVariables, idx: CssVarId, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by index
  if idx in vars.variables:
    size = vars.variables[idx]
    return true
  return false

proc lookupFunc*(vars: CssVariables, idx: CssVarId, fun: var CssFunc): bool =
  ## Looks up a CSS function by index
  if idx in vars.funcs:
    fun = vars.funcs[idx]
    return true
  return false

proc variableName*(vars: CssVariables, id: CssVarId): string =
  ## Returns the name of a CSS variable by index
  for name, idx in vars.names:
    if idx == id:
      return $name
  return ""

proc variableName*(vars: CssVariables, cs: ConstraintSize): string =
  ## Returns the name of a CSS variable by index
  if cs.kind == UiVariable:
    return vars.variableName(cs.varIdx)
  return ""

proc resolveVariable*(vars: CssVariables, varIdx: CssVarId, funcIdx: CssVarId, val: var ConstraintSize): bool =
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
      if funcIdx in vars.funcs:
        val = vars.funcs[funcIdx](res)
      else:
        val = res
      return true
  else:
    return false

proc resolveVariable*(vars: CssVariables, cx: Constraint, val: var ConstraintSize): bool =
  ## Resolves a constraint, looking up variables if needed
  if cx.kind == UiValue:
    return vars.resolveVariable(cx.value.varIdx, cx.value.funcIdx, val)
  else:
    return false

proc csVar*(vars: CssVariables, name: Atom, value: Constraint = csAuto(), funcIdx: CssVarId = CssVarId(-1)): Constraint =
  ## Creates a constraint for a CSS variable by name
  ## If the variable doesn't exist, it will be created with a default value
  let idx = vars.registerVariable(name)
  vars.setVariable(idx, value)
  return csVar(idx, funcIdx)

proc csVar*(vars: CssVariables, name: static string, value: Constraint = csAuto(), funcIdx: CssVarId = CssVarId(-1)): Constraint =
  ## Creates a constraint for a CSS variable by name
  ## If the variable doesn't exist, it will be created with a default value
  let nameAtom = atom(name)
  return vars.csVar(nameAtom, value, funcIdx)

proc `$`*(vars: CssVariables): string =
  ## Returns a string representation of the CSS variables
  result = "CssVariables:\n"
  # Add names table
  result.add "  Names:\n"
  for name, id in vars.names:
    result.add "    " & $name & " => " & $id & "\n"
  
  # Add variables table
  result.add "  Variables:\n"
  for id, value in vars.variables:
    let varName = vars.variableName(id)
    let nameStr = if varName != "": " (" & varName & ")" else: ""
    result.add "    " & $id & nameStr & " => " & $value & "\n"
  
  # Add functions table
  result.add "  Functions:\n"
  for id, _ in vars.funcs:
    let varName = vars.variableName(id)
    let nameStr = if varName != "": " (" & varName & ")" else: ""
    result.add "    " & $id & nameStr & " => <function>\n"
