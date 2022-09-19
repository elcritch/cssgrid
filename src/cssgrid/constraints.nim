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
    UiValue
    UiAuto
    UiMin
    UiMax
    UiMinMax
    UiEnd

  Constraint* = object
    case kind*: Constraints
    of UiValue:
      value*: ConstraintSize
    of UiAuto:
      discard
    of UiMin:
      lmin, rmin*: ConstraintSize
    of UiMax:
      lmax, rmax*: ConstraintSize
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

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiPerc(perc): return perc == b.perc
      UiFixed(coord): return coord == b.coord

proc `==`*(a, b: Constraint): bool =
  if a.kind == b.kind:
    match a:
      UiAuto(): return true
      UiValue(value): return value == b.value
      UiMin(lmin, rmin): return lmin == b.lmin and rmin == b.rmin
      UiMax(lmax, rmax): return lmax == b.lmax and rmax == b.rmax
      UiMinMax(lmm, rmm): return lmm == b.lmm and rmm == b.rmm
      UiEnd(): return true

proc repr*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ui"
    UiPerc(perc): result = $perc & "'perc"

proc `'ui`*(n: string): Constraint =
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
