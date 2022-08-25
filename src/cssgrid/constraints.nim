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
