import numberTypes
export sets, tables, numberTypes

type
  ConstraintBehavior* = enum
    CxStretch
    CxStart
    CxEnd
    CxCenter

  ConstraintSizes* = enum
    UiFrac
    UiPerc
    UiFixed

  ConstraintSize* = object
    case kind*: ConstraintSizes
    of UiFrac:
      frac*: UiScalar
    of UiPerc:
      perc*: UiScalar
    of UiFixed:
      coord*: UiScalar

  Constraints* = enum
    UiNone
    UiValue
    UiAuto
    UiMin
    UiMax
    UiSum
    UiMinMax
    UiEnd

  Constraint* = object
    case kind*: Constraints
    of UiNone:
      discard
    of UiValue:
      value*: ConstraintSize
    of UiAuto:
      discard
    of UiMin:
      lmin, rmin*: ConstraintSize
    of UiMax:
      lmax, rmax*: ConstraintSize
    of UiSum:
      lsum, rsum*: ConstraintSize
    of UiMinMax:
      lmm, rmm*: ConstraintSize
    of UiEnd:
      discard

proc csValue*(size: ConstraintSize): Constraint =
  Constraint(kind: UiValue, value: size)
proc csAuto*(): Constraint =
  Constraint(kind: UiAuto)

proc csFrac*(size: int|float|UiScalar): Constraint =
  csValue(ConstraintSize(kind: UiFrac, frac: size.UiScalar))
proc csFixed*(coord: int|float|UiScalar): Constraint =
  csValue(ConstraintSize(kind: UiFixed, coord: coord.UiScalar))
proc csPerc*(perc: int|float|UiScalar): Constraint =
  csValue(ConstraintSize(kind: UiPerc, perc: perc.UiScalar))
proc csEnd*(): Constraint =
  Constraint(kind: UiEnd)
proc csNone*(): Constraint =
  Constraint(kind: UiNone)

proc csSum*(a, b: int|float|UiScalar|ConstraintSize): Constraint =
  let a = when a is ConstraintSize: a else: csFixed(a)
  let b = when b is ConstraintSize: b else: csFixed(b)
  csSum(a: a, b: b)

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiPerc(perc): return perc == b.perc
      UiFixed(coord): return coord == b.coord

proc `==`*(a, b: Constraint): bool =
  if a.kind == b.kind:
    match a:
      UiNone(): return true
      UiAuto(): return true
      UiValue(value): return value == b.value
      UiMin(lmin, rmin): return lmin == b.lmin and rmin == b.rmin
      UiMax(lmax, rmax): return lmax == b.lmax and rmax == b.rmax
      UiSum(lsum, rsum): return lsum == b.lsum and rsum == b.rsum
      UiMinMax(lmm, rmm): return lmm == b.lmm and rmm == b.rmm
      UiEnd(): return true

proc repr*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ux"
    UiPerc(perc): result = $perc & "'perc"

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
