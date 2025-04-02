import numberTypes
export sets, tables, numberTypes

type
  ConstraintBehavior* = enum
    CxStretch
    CxStart
    CxEnd
    CxCenter

  ConstraintSizes* = enum
    UiAuto
    UiFrac
    UiPerc
    UiViewPort  # Added for view width/height (vw/vh)
    UiFixed
    UiContentMin
    UiContentMax
    UiContentFit
    UiVariable

  ConstraintSize* = object
    case kind*: ConstraintSizes
    of UiFrac:
      frac*: UiScalar ## set `fr` aka CSS Grid fractions
    of UiPerc:
      perc*: UiScalar ## set percentage of parent box or grid
    of UiViewPort:
      view*: UiScalar ## set percentage of viewport width/height
    of UiFixed:
      coord*: UiScalar ## set fixed coordinate size
    of UiContentMin, UiContentMax, UiContentFit:
      discard
    of UiAuto:
      discard
    of UiVariable:
      varIdx*: int

  Constraints* = enum
    UiNone
    UiValue
    UiMin
    UiMax
    UiAdd
    UiSub
    UiMinMax
    UiEnd

  Constraint* = object
    case kind*: Constraints
    of UiNone:
      discard
    of UiValue:
      value*: ConstraintSize ## used for `ConstraintSize` above
    of UiMin:
      lmin*, rmin*: ConstraintSize ## minimum of lhs and rhs (partially supported)
    of UiMax:
      lmax*, rmax*: ConstraintSize ## maximum of lhs and rhs (partially supported)
    of UiAdd:
      ladd*, radd*: ConstraintSize ## sum of lhs and rhs (partially supported)
    of UiSub:
      lsub*, rsub*: ConstraintSize ## sum of lhs and rhs (partially supported)
    of UiMinMax:
      lmm*, rmm*: ConstraintSize ## min-max of lhs and rhs (partially supported)
    of UiEnd: discard ## marks end track of a CSS Grid layout

  
  CssVariables* = ref object
    variables*: Table[int, ConstraintSize]
    names*: Table[string, int]

proc csValue*(size: ConstraintSize): Constraint =
  Constraint(kind: UiValue, value: size)
proc csAuto*(): Constraint =
  csValue(ConstraintSize(kind: UiAuto))
proc csFrac*[T](size: T): Constraint =
  csValue(ConstraintSize(kind: UiFrac, frac: size.UiScalar))
proc csFixed*[T](coord: T): Constraint =
  csValue(ConstraintSize(kind: UiFixed, coord: UiScalar(coord)))
proc csPerc*[T](perc: T): Constraint =
  csValue(ConstraintSize(kind: UiPerc, perc: perc.UiScalar))
proc csViewPort*[T](view: T): Constraint =
  csValue(ConstraintSize(kind: UiViewPort, view: view.UiScalar))
proc csContentMin*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMin))
proc csContentMax*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMax))
proc csContentFit*(): Constraint =
  csValue(ConstraintSize(kind: UiContentFit))

proc cssFuncArgs*(cx: Constraint): tuple[l, r: ConstraintSize] =
  match cx:
    UiMin(lmin, rmin):
      result = (lmin, rmin)
    UiMax(lmax, rmax):
      result = (lmax, rmax)
    UiAdd(ladd, radd):
      result = (ladd, radd)
    UiSub(lsub, rsub):
      result = (lsub, rsub)
    UiMinMax(lmm, rmm):
      result = (lmm, rmm)
    _:
      discard

proc isFixed*(cs: ConstraintSize): bool =
  case cs.kind:
    of UiFixed, UiPerc, UiViewPort:
      return true
    else:
      return false

proc isFixed*(cx: Constraint): bool =
  case cx.kind:
    of UiValue:
      return isFixed(cx.value)
    of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
      let args = cssFuncArgs(cx)
      return isFixed(args.l) or isFixed(args.r)
    of UiNone, UiEnd:
      return false

proc getFixedSize*(cs: ConstraintSize, containerSize, containerMin: UiScalar): UiScalar =
  case cs.kind:
    of UiFixed:
      return cs.coord
    of UiPerc:
      return cs.perc * containerSize / 100.0.UiScalar
    of UiViewPort:
      return cs.view * containerSize / 100.0.UiScalar  # Similar to percentage but based on viewport size
    of UiContentMin:
      return containerMin  # Use the container's min-content size
    of UiContentMax, UiContentFit:
      return containerSize  # For initial sizing, treat as content-based
    of UiAuto, UiFrac:
      return 0.UiScalar  # Treat as indefinite for fixed sizing
    of UiVariable:
      return 0.UiScalar  # Variables are resolved during lookup

proc getFixedSize*(cx: Constraint, containerSize, containerMin: UiScalar): UiScalar =
  case cx.kind:
    of UiValue:
      return getFixedSize(cx.value, containerSize, containerMin)
    of UiMin:
      let lsize = getFixedSize(cx.lmin, containerSize, containerMin)
      let rsize = getFixedSize(cx.rmin, containerSize, containerMin)
      return min(lsize, rsize)
    of UiMax:
      let lsize = getFixedSize(cx.lmax, containerSize, containerMin)
      let rsize = getFixedSize(cx.rmax, containerSize, containerMin)
      return max(lsize, rsize)
    of UiAdd:
      let lsize = getFixedSize(cx.ladd, containerSize, containerMin)
      let rsize = getFixedSize(cx.radd, containerSize, containerMin)
      return lsize + rsize
    of UiSub:
      let lsize = getFixedSize(cx.lsub, containerSize, containerMin)
      let rsize = getFixedSize(cx.rsub, containerSize, containerMin)
      return max(0.UiScalar, lsize - rsize)
    of UiMinMax:
      return getFixedSize(cx.lmm, containerSize, containerMin)
    of UiNone, UiEnd:
      return 0.UiScalar

proc isCssFunc*(cx: Constraint): bool =
  cx.kind in [UiAdd, UiSub, UiMin, UiMax, UiMinMax]

proc isContentSized*(cx: ConstraintSize): bool =
  cx.kind in [UiContentMin, UiContentMax, UiContentFit, UiAuto, UiFrac]

proc isContentSized*(cx: Constraint): bool =
  case cx.kind:
  of UiNone, UiEnd:
    result = false
  of UiValue:
    result = isContentSized(cx.value)
  of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
    let args = cssFuncArgs(cx)
    result = isContentSized(args.l) or isContentSized(args.r)


proc isBasicContentSized*(cs: ConstraintSize): bool =
  cs.kind in [UiContentMin, UiContentMax, UiContentFit]

proc isAuto*(cs: ConstraintSize): bool =
  cs.kind in [UiAuto]

proc isFrac*(cs: ConstraintSize): bool =
  cs.kind in [UiFrac]

proc getFrac*(cs: ConstraintSize): UiScalar =
  ## Extract the flex factor from a ConstraintSize
  case cs.kind
  of UiFrac:
    result = cs.frac
  else:
    result = 0.UiScalar

proc getFrac*(cs: Constraint): UiScalar =
  ## Extract the flex factor from a Constraint
  case cs.kind
  of UiValue:
    result = getFrac(cs.value)
  of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
    let args = cssFuncArgs(cs)
    # For compound constraints, take the maximum flex factor from either side
    result = max(getFrac(args.l), getFrac(args.r))
  of UiNone, UiEnd:
    result = 0.UiScalar


proc isFrac*(cs: Constraint): bool =
  case cs.kind:
  of UiNone, UiEnd:
    result = false
  of UiValue:
    result = isFrac(cs.value)
  of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
    let args = cssFuncArgs(cs)
    result = isFrac(args.l) or isFrac(args.r)

proc isAuto*(cx: Constraint): bool =
  case cx.kind:
  of UiNone, UiEnd:
    result = false
  of UiValue:
    result = isAuto(cx.value)
  of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
    let args = cssFuncArgs(cx)
    result = isAuto(args.l) or isAuto(args.r)
      

proc csEnd*(): Constraint =
  Constraint(kind: UiEnd)
proc csNone*(): Constraint =
  Constraint(kind: UiNone)

proc csAdd*[U, T](a: U, b: T): Constraint =
  ## create sum op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  Constraint(kind: UiAdd, ladd: a, radd: b)

proc csSub*[U, T](a: U, b: T): Constraint =
  ## create sum op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  Constraint(kind: UiSub, lsub: a, rsub: b)

proc csMax*[U, T](a: U, b: T): Constraint =
  ## create max op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  
  Constraint(kind: UiMax, lmax: a, rmax: b)

proc csMin*[U, T](a: U, b: T): Constraint =
  ## create min op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  
  Constraint(kind: UiMin, lmin: a, rmin: b)

proc csMinMax*[U, T](a: U, b: T): Constraint =
  ## create minmax op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  Constraint(kind: UiMinMax, lmm: a, rmm: b)

proc csVar*(idx: int): Constraint =
  ## Creates a constraint for a CSS variable by index
  csValue(ConstraintSize(kind: UiVariable, varIdx: idx))

proc `+`*[U: Constraint, T](a: U, b: T): Constraint =
  csAdd(a, b)
proc `-`*[U: Constraint, T](a: U, b: T): Constraint =
  csSub(a, b)

proc max*[U, T: Constraint](a: U, b: T): Constraint =
  csMax(a, b)

proc min*[U, T: Constraint](a: U, b: T): Constraint =
  csMin(a, b)

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiPerc(perc): return perc == b.perc
      UiViewPort(view): return view == b.view
      UiFixed(coord): return coord == b.coord
      UiContentMin(): return true
      UiContentMax(): return true
      UiContentFit(): return true
      UiAuto(): return true
      UiVariable(varIdx): return varIdx == b.varIdx

proc `==`*(a, b: Constraint): bool =
  if a.kind == b.kind:
    case a.kind:
      of UiNone, UiEnd: return true
      of UiValue, UiMin, UiMax, UiAdd, UiSub, UiMinMax: return cssFuncArgs(a) == cssFuncArgs(b)

proc `$`*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ux"
    UiPerc(perc): result = $perc & "'perc"
    UiViewPort(view): result = $view & "'vp"
    UiContentMin(): result = "cx'content-min"
    UiContentMax(): result = "cx'content-max"
    UiContentFit(): result = "cx'fit-content"
    UiAuto(): result = "cx'auto"
    UiVariable(varIdx): result = "var(" & $varIdx & ")"

proc `$`*(a: Constraint): string =
  match a:
    UiNone(): "cx(none)"
    UiValue(value): "cx(" & $value & ")"
    UiMin(lmin, rmin): "min(" & $lmin & "," & $rmin & ")"
    UiMax(lmax, rmax): "max(" & $lmax & "," & $rmax & ")"
    UiAdd(ladd, radd): "add(" & $ladd & "," & $radd & ")"
    UiSub(lsub, rsub): "sub(" & $lsub & "," & $rsub & ")"
    UiMinMax(lmm, rmm): "minmax(" & $lmm & "," & $rmm & ")"
    UiEnd(): "cx(end)"

proc `'ux`*(n: string): Constraint =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = csFixed(f)

proc `'fr`*(n: string): Constraint =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = csFrac(f)

proc `'pp`*(n: string): Constraint =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = csPerc(f)

proc `'vp`*(n: string): Constraint =
  ## numeric literal for viewport-relative units (vw/vh)
  let f = parseFloat(n)
  result = csViewPort(f)

template `cx`*(n: static string): auto =
  when n == "auto":
    csAuto()
  elif n == "none":
    csNone()
  elif n == "min-content":
    csContentMin()
  elif n == "max-content":
    csContentMax()
  elif n == "fit-content":
    csContentFit()
  else:
    {.error: "unknown constraint constant: " & n.}

proc isIntrinsicSizing*(cs: ConstraintSize): bool =
  ## Check if a constraint size is an intrinsic sizing function according to CSS Grid spec.
  ## Intrinsic sizing functions are: min-content, max-content, auto, and fit-content().
  case cs.kind
  of UiContentMin, UiContentMax, UiContentFit, UiAuto:
    result = true
  else:
    result = false

proc isIntrinsicSizing*(cx: Constraint): bool =
  ## Check if a constraint is an intrinsic sizing function according to CSS Grid spec.
  ## For compound constraints, returns true if either component is an intrinsic sizing function.
  case cx.kind
  of UiNone, UiEnd:
    result = false
  of UiValue:
    result = isIntrinsicSizing(cx.value)
  of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
    let args = cssFuncArgs(cx)
    result = isIntrinsicSizing(args.l) or isIntrinsicSizing(args.r)

proc getMinSize*(cs: ConstraintSize, contentSize: UiScalar = 0.UiScalar): UiScalar =
  ## Extract the minimum size from a ConstraintSize
  ## For intrinsic sizing, uses contentSize if provided
  case cs.kind
  of UiFixed:
    # Fixed sizes are their own minimum
    result = cs.coord
  of UiPerc:
    # Percentages are their own minimum
    result = cs.perc
  of UiViewPort:
    # Viewport sizes are their own minimum
    result = cs.view
  of UiFrac:
    # Flex units have a default minimum of 0
    result = 0.UiScalar
  of UiContentMin, UiAuto:
    # For min-content and auto, use provided content size
    result = contentSize
  of UiContentMax, UiContentFit:
    # For max-content and fit-content, also use content size
    result = contentSize
  of UiVariable:
    # Variables are resolved during lookup - use 0 as default min
    result = 0.UiScalar

proc getMinSize*(cs: Constraint, contentSize: UiScalar): UiScalar =
  ## Extract the minimum size from a Constraint
  ## If constraint is a compound expression like minmax(), returns appropriate minimum
  case cs.kind
  of UiNone, UiEnd:
    result = 0.UiScalar
  of UiValue:
    result = getMinSize(cs.value, contentSize)
  of UiMin:
    # For min(), take the smaller of the two minimums as the result could be the smaller
    let lmin = getMinSize(cs.lmin, contentSize)
    let rmin = getMinSize(cs.rmin, contentSize)
    result = min(lmin, rmin)
  of UiMax:
    # For max(), the minimum is the larger of the two minimums
    # since the result will always be at least the larger minimum
    let lmin = getMinSize(cs.lmax, contentSize)
    let rmin = getMinSize(cs.rmax, contentSize)
    result = max(lmin, rmin)
  of UiMinMax:
    # For minmax(), the minimum is simply the first argument
    result = getMinSize(cs.lmm, contentSize)
  of UiAdd:
    # For addition, the minimum is the sum of minimums
    result = getMinSize(cs.ladd, contentSize) + getMinSize(cs.radd, contentSize)
  of UiSub:
    # For subtraction, the minimum is the difference of minimums
    # with a floor of 0 to prevent negative sizes
    result = max(0.UiScalar, getMinSize(cs.lsub, contentSize) - getMinSize(cs.rsub, contentSize))

# CSS Variable functions
proc newCssVariables*(): CssVariables =
  ## Creates a new CSS variables container
  new(result)
  result.variables = initTable[int, ConstraintSize]()
  result.names = initTable[string, int]()

proc registerVariable*(vars: CssVariables, name: string, value: ConstraintSize): Constraint =
  ## Registers a new CSS variable with the given name and value
  ## Returns the variable index
  if name in vars.names:
    let idx = vars.names[name]
    vars.variables[idx] = value
    return csVar(idx)
  else:
    let idx = vars.variables.len + 1
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

proc lookupVariable*(vars: CssVariables, idx: int, size: var ConstraintSize): bool =
  ## Looks up a CSS variable by index
  ## Returns Some(value) if found, None otherwise
  if idx in vars.variables:
    size = vars.variables[idx]
    return true
  return false

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
