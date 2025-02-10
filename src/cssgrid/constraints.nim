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
    of UiFrac:
      frac*: UiScalar ## set `fr` aka CSS Grid fractions
    of UiPerc:
      perc*: UiScalar ## set percentage of parent box or grid
    of UiFixed:
      coord*: UiScalar ## set fixed coordinate size
    of UiContentMin, UiContentMax:
      discard
    of UiAuto:
      discard

  Constraints* = enum
    UiValue
    UiMin
    UiMax
    UiAdd
    UiSub
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
proc csContentMin*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMin))
proc csContentMax*(): Constraint =
  csValue(ConstraintSize(kind: UiContentMax))

proc isContentSized*(cx: Constraint): bool =
  cx.kind == UiValue and cx.value.kind in [UiContentMin, UiContentMax, UiAuto, UiFrac] 
proc isBasicContentSized*(cs: ConstraintSize): bool =
  cs.kind in [UiContentMin, UiContentMax]
proc isAuto*(cx: Constraint): bool =
  cx.kind == UiValue and cx.value.kind in [UiAuto, UiFrac]

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
  ## create minmin op
  let a = when a is ConstraintSize: a
          elif a is Constraint: a.value
          else: csFixed(a).value
  let b = when b is ConstraintSize: b
          elif b is Constraint: b.value
          else: csFixed(b).value
  Constraint(kind: UiMinMax, lmm: a, rmm: b)

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
      UiAdd(ladd, radd): return ladd == b.ladd and radd == b.radd
      UiSub(lsub, rsub): return lsub == b.lsub and rsub == b.rsub
      UiMinMax(lmm, rmm): return lmm == b.lmm and rmm == b.rmm
      UiEnd(): return true

proc `$`*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ux"
    UiPerc(perc): result = $perc & "'perc"
    UiContentMin(): result = "cx'content-min"
    UiContentMax(): result = "cx'content-max"
    UiAuto(): result = "cx'auto"

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
