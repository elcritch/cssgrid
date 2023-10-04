import numberTypes
export sets, tables, numberTypes

type
  ConstraintBehavior* = enum
    CxStretch
    CxStart
    CxEnd
    CxCenter

type
  ConstraintSizes* = enum
    UiAuto
    UiFrac
    UiPerc
    UiFixed
    UiContentMin
    UiContentMax

  ConstraintSize* = object
    case kind*: ConstraintSizes
    of UiAuto:
      amin*: UiScalar ## default, which is parent width/height less the x/y positions of the node and it's parents
    of UiFrac:
      frac*: UiScalar ## set `fr` aka CSS Grid fractions
    of UiPerc:
      perc*: UiScalar ## set percentage of parent box or grid
    of UiFixed:
      coord*: UiScalar ## set fixed coordinate size
    of UiContentMin:
      cmin*: UiScalar ## sets layout to use min-content, `cmin` is calculated internally
    of UiContentMax:
      cmax*: UiScalar ## sets layout to use max-content, `cmax` is calculated internally

  Constraints* = enum
    UiValue
    UiMin
    UiMax
    UiSum
    UiMinMax
    UiNone
    UiEnd

  Constraint* = object
    case kind*: Constraints
    of UiNone:
      discard
    of UiValue:
      value*: ConstraintSize ## used for `ConstraintSize` above
    of UiMin:
      lmin, rmin*: ConstraintSize ## minimum of lhs and rhs (partially supported)
    of UiMax:
      lmax, rmax*: ConstraintSize ## maximum of lhs and rhs (partially supported)
    of UiSum:
      lsum, rsum*: ConstraintSize ## sum of lhs and rhs (partially supported)
    of UiMinMax:
      lmm, rmm*: ConstraintSize ## min-max of lhs and rhs (partially supported)
    of UiEnd: discard ## marks end track of a CSS Grid layout

proc csValue*(size: ConstraintSize): Constraint =
  Constraint(kind: UiValue, value: size)
proc csAuto*(): Constraint =
  csValue(ConstraintSize(kind: UiAuto, amin: 0.UiScalar))

proc csFrac*[T](size: T): Constraint =
  csValue(ConstraintSize(kind: UiFrac, frac: size.UiScalar))
proc csFixed*[T](coord: T): Constraint =
  csValue(ConstraintSize(kind: UiFixed, coord: coord.UiScalar))
proc csPerc*[T](perc: T): Constraint =
  csValue(ConstraintSize(kind: UiPerc, perc: perc.UiScalar))
proc csContentMin*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMin, cmin: float.high().UiScalar))
proc csContentMax*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMax, cmax: 0.UiScalar))

proc isContentSized*(cx: Constraint): bool =
  cx.kind == UiValue and cx.value.kind in [UiContentMin, UiContentMax, UiAuto] 
proc isAuto*(cx: Constraint): bool =
  cx.kind == UiValue and cx.value.kind in [UiAuto]

proc csEnd*(): Constraint =
  Constraint(kind: UiEnd)
proc csNone*(): Constraint =
  Constraint(kind: UiNone)

proc csSum*[U, T](a: U, b: T): Constraint =
  ## create sum op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif a is Constraint: a.value
          else: csFixed(b).value
  Constraint(kind: UiSum, lsum: a, rsum: b)

proc csMax*[U, T](a: U, b: T): Constraint =
  ## create max op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif a is Constraint: a.value
          else: csFixed(b).value
  Constraint(kind: UiMax, lmax: a, rmax: b)

proc csMin*[U, T](a: U, b: T): Constraint =
  ## create min op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif a is Constraint: a.value
          else: csFixed(b).value
  Constraint(kind: UiMin, lmin: a, rmin: b)

proc csMinMax*[U, T](a: U, b: T): Constraint =
  ## create minmin op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif a is Constraint: a.value
          else: csFixed(b).value
  Constraint(kind: UiMinMax, lmm: a, rmm: b)

proc `+`*[U: Constraint, T](a: U, b: T): Constraint =
  csSum(a, b)
proc `-`*[U: Constraint, T](a: U, b: T): Constraint =
  csSum(a, b)

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiPerc(perc): return perc == b.perc
      UiFixed(coord): return coord == b.coord
      UiContentMin(): return true
      UiContentMax(): return true
      UiAuto(): return true

proc `==`*(a, b: Constraint): bool =
  if a.kind == b.kind:
    match a:
      UiNone(): return true
      UiValue(value): return value == b.value
      UiMin(lmin, rmin): return lmin == b.lmin and rmin == b.rmin
      UiMax(lmax, rmax): return lmax == b.lmax and rmax == b.rmax
      UiSum(lsum, rsum): return lsum == b.lsum and rsum == b.rsum
      UiMinMax(lmm, rmm): return lmm == b.lmm and rmm == b.rmm
      UiEnd(): return true

proc `$`*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ux"
    UiPerc(perc): result = $perc & "'perc"
    UiContentMin(cmin): result = $cmin & "'min"
    UiContentMax(cmax): result = $cmax & "'max"
    UiAuto(amin): result = $amin & "'auto"

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

template `cx`*(n: static string): auto =
  when n == "auto":
    csAuto()
  elif n == "min-content":
    csContentMin()
  elif n == "max-content":
    csContentMax()
  else:
    {.error: "unknown constraint constant: " & n.}
