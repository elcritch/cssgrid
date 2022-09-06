import basic
export sets, tables

type
  ConstraintBehavior* = enum
    CxStretch
    CxStart
    CxEnd
    CxCenter

  ConstraintKind* = enum
    UiFrac
    UiPerc
    UiFixed
    UiEnd

  ConstraintOps* = enum
    UiValue
    UiAuto
    UiMin
    UiMax
    UiMinMax

  ConstraintSize* = object
    case kind*: ConstraintKind
    of UiFrac:
      frac*: UiScalar
    of UiPerc:
      perc*: UiScalar
    of UiFixed:
      coord*: UiScalar
    of UiEnd:
      discard

  Constraints* = object
    case kind*: ConstraintOps
    of UiValue:
      value*: ConstraintSize
    of UiAuto:
      discard
    of UiMin:
      min*: ConstraintSize
    of UiMax:
      max*: ConstraintSize
    of UiMinMax:
      minof*: ConstraintSize
      maxof*: ConstraintSize

proc csValue*(size: ConstraintSize): Constraints =
  Constraints(kind: UiValue, value: size)
proc csAuto*(): Constraints =
  Constraints(kind: UiAuto)

proc csFrac*(size: int|float|UiScalar): Constraints =
  csValue(ConstraintSize(kind: UiFrac, frac: size.UiScalar))
proc csFixed*(coord: int|float|UiScalar): Constraints =
  csValue(ConstraintSize(kind: UiFixed, coord: coord.UiScalar))
proc csPerc*(perc: int|float|UiScalar): Constraints =
  csValue(ConstraintSize(kind: UiPerc, perc: perc.UiScalar))
proc csEnd*(): Constraints =
  csValue(ConstraintSize(kind: UiEnd))

proc `==`*(a, b: ConstraintSize): bool =
  if a.kind == b.kind:
    match a:
      UiFrac(frac): return frac == b.frac
      UiPerc(perc): return perc == b.perc
      UiFixed(coord): return coord == b.coord
      UiEnd(): return true

proc `==`*(a, b: Constraints): bool =
  if a.kind == b.kind:
    match a:
      UiAuto(): return true
      UiValue(value): return value == b.value
      UiMin(min): return min == b.min
      UiMax(max): return max == b.max
      UiMinMax(minof, maxof): return minof == b.minof and maxof == b.maxof

proc repr*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ui"
    UiPerc(perc): result = $perc & "'perc"
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
