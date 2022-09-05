import basic
export sets, tables

type
  Constraint* = enum
    CxStretch
    CxStart
    CxEnd
    CxCenter

  ConstraintKind* = enum
    UiFrac
    UiAuto
    UiPerc
    UiFixed
    UiEnd

  ConstraintOps* = enum
    UiMin
    UiMax
    UiMinMax
    UiMinContent
    UiMaxContent

type
  ConstraintSize* = object
    case kind*: ConstraintKind
    of UiFrac:
      frac*: UiScalar
    of UiAuto:
      discard
    of UiPerc:
      perc*: UiScalar
    of UiFixed:
      coord*: UiScalar
    of UiEnd:
      discard

  Constraints* = object
    lhs*: ConstraintSize
    rhs*: ConstraintSize

proc csFrac*(size: int|float|UiScalar): ConstraintSize =
  ConstraintSize(kind: UiFrac, frac: size.UiScalar)
proc csFixed*(coord: int|float|UiScalar): ConstraintSize =
  ConstraintSize(kind: UiFixed, coord: coord.UiScalar)
proc csPerc*(perc: int|float|UiScalar): ConstraintSize =
  ConstraintSize(kind: UiPerc, perc: perc.UiScalar)
proc csAuto*(): ConstraintSize =
  ConstraintSize(kind: UiAuto)
proc csEnd*(): ConstraintSize =
  ConstraintSize(kind: UiEnd)

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiAuto(): return true
      UiPerc(perc): return perc == b.perc
      UiFixed(coord): return coord == b.coord
      UiEnd(): return true

proc repr*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ui"
    UiPerc(perc): result = $perc & "'perc"
    UiAuto(): result = "auto"
    UiEnd(): result = "ends"

proc `'ui`*(n: string): ConstraintSize =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = ConstraintSize(kind: UiFixed, coord: f.UiScalar)

proc `'fr`*(n: string): ConstraintSize =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = ConstraintSize(kind: UiFrac, frac: f.UiScalar)

proc `'pp`*(n: string): ConstraintSize =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = ConstraintSize(kind: UiPerc, perc: f.UiScalar)
