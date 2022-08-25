import std/[strformat, sequtils, strutils, hashes, sets, tables]

import patty
export patty

import vmath, bumpy, math
export math, vmath, bumpy

import macros, macroutils
import typetraits

export sequtils, strutils, hashes, sets, tables, strformat

template borrowMaths*(typ, base: typedesc) =
  proc `+` *(x, y: typ): typ = typ(`+`(base(x), base(y)))
  proc `-` *(x, y: typ): typ = typ(`-`(base(x), base(y)))
  
  proc `-` *(x: typ): typ = typ(`-`(base(x)))

  ## allow NewType(3.2) + 3.2 ... 
  proc `+` *(x: typ, y: static[float32|float64|int]): typ = typ(`+`(base x, base y))
  proc `-` *(x: typ, y: static[float32|float64|int]): typ = typ(`-`(base x, base y))
  proc `+` *(x: static[float32|float64|int], y: typ): typ = typ(`+`(base x, base y))
  proc `-` *(x: static[float32|float64|int], y: typ): typ = typ(`-`(base x, base y))

  proc `*` *(x, y: typ): typ = typ(`*`(base(x), base(y)))
  proc `/` *(x, y: typ): typ = typ(`/`(base(x), base(y)))

  proc `*` *(x: typ, y: static[distinctBase(typ)]): typ = typ(`*`(base(x), base(y)))
  proc `/` *(x: typ, y: static[distinctBase(typ)]): typ = typ(`/`(base(x), base(y)))
  proc `*` *(x: static[base], y: typ): typ = typ(`*`(base(x), base(y)))
  proc `/` *(x: static[base], y: typ): typ = typ(`/`(base(x), base(y)))

  proc `min` *(x: typ, y: typ): typ {.borrow.}
  proc `max` *(x: typ, y: typ): typ {.borrow.}

  proc `<` * (x, y: typ): bool {.borrow.}
  proc `<=` * (x, y: typ): bool {.borrow.}
  proc `==` * (x, y: typ): bool {.borrow.}

  proc `+=` * (x: var typ, y: typ) {.borrow.}
  proc `-=` * (x: var typ, y: typ) {.borrow.}
  proc `/=` * (x: var typ, y: typ) {.borrow.}
  proc `*=` * (x: var typ, y: typ) {.borrow.}
  proc `$` * (x: typ): string {.borrow.}
  proc `hash` * (x: typ): Hash {.borrow.}

template borrowMathsMixed*(typ: typedesc) =
  proc `*` *(x: typ, y: distinctBase(typ)): typ {.borrow.}
  proc `*` *(x: distinctBase(typ), y: typ): typ {.borrow.}
  proc `/` *(x: typ, y: distinctBase(typ)): typ {.borrow.}
  proc `/` *(x: distinctBase(typ), y: typ): typ {.borrow.}


template genBoolOp[T, B](op: untyped) =
  proc `op`*(a, b: T): bool = `op`(B(a), B(b))

template genFloatOp[T, B](op: untyped) =
  proc `op`*(a: T, b: UiScalar): T = T(`op`(B(a), b.float32))

template genEqOp[T, B](op: untyped) =
  proc `op`*(a: var T, b: float32) = `op`(B(a), b)
  proc `op`*(a: var T, b: T) = `op`(B(a), B(b))

template genEqOpC[T, B, C](op: untyped) =
  proc `op`*[D](a: var T, b: D) = `op`(B(a), C(b))

template genMathFn[T, B](op: untyped) =
  proc `op`*(a: `T`): `T` =
    T(`op`(B(a)))

template genOp[T, B](op: untyped) =
  proc `op`*(a, b: T): T = T(`op`(B(a), B(b)))

macro applyOps(a, b: typed, fn: untyped, ops: varargs[untyped]) =
  result = newStmtList()
  for op in ops:
    result.add quote do:
      `fn`[`a`, `b`](`op`)

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct percentages
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

type
  PercKind* = enum
    relative
    absolute
  Percent* = distinct float32
  Percentages* = tuple[value: float32, kind: PercKind]

borrowMaths(Percent, float32)
# borrowMathsMixed(Percent)

type
  # ScaledCoord* = distinct float32
  UiScalar* = distinct float32

# borrowMaths(ScaledCoord)
borrowMaths(UiScalar, float32)

converter toUI*[F: float|int|float32](x: static[F]): UiScalar = UiScalar x

proc `'ui`*(n: string): UiScalar =
  ## numeric literal UI Coordinate unit
  result = UiScalar(parseFloat(n))

template scaled*(a: UiScalar): float32 =
  a.float32 * common.uiScale
template descaled*(a: float32): UiScalar =
  UiScalar(a / common.uiScale)

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct vec types
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

type
  Position* = distinct Vec2

proc initPosition*(x, y: float32): Position = Position(vec2(x, y))
genBoolOp[Position, Vec2](`==`)
genBoolOp[Position, Vec2](`!=`)
genBoolOp[Position, Vec2](`~=`)

applyOps(Position, Vec2, genOp, `+`, `-`, `/`, `*`, `mod`, `zmod`, `min`, `zmod`)
applyOps(Position, Vec2, genEqOp, `+=`, `-=`, `*=`, `/=`)
applyOps(Position, Vec2, genMathFn, `-`, sin, cos, tan, arcsin, arccos, arctan, sinh, cosh, tanh)
applyOps(Position, Vec2, genMathFn, exp, ln, log2, sqrt, floor, ceil, abs) 
applyOps(Position, Vec2, genFloatOp, `*`, `/`)

type
  Box* = distinct Rect

proc initBox*(x, y, w, h: float32): Box = Box(rect(x, y, w, h))
proc initBox*(x, y, w, h: UiScalar): Box = Box(rect(x.float32, y.float32, w.float32, h.float32))

applyOps(Box, Rect, genOp, `+`)
applyOps(Box, Rect, genFloatOp, `*`, `/`)
genBoolOp[Box, Rect](`==`)
genEqOpC[Box, Rect, Vec2](`xy=`)

template x*(r: Box): UiScalar = r.Rect.x.UiScalar
template y*(r: Box): UiScalar = r.Rect.y.UiScalar
template w*(r: Box): UiScalar = r.Rect.w.UiScalar
template h*(r: Box): UiScalar = r.Rect.h.UiScalar
template `x=`*(r: Box, v: UiScalar) = r.Rect.x = v.float32
template `y=`*(r: Box, v: UiScalar) = r.Rect.y = v.float32
template `w=`*(r: Box, v: UiScalar) = r.Rect.w = v.float32
template `h=`*(r: Box, v: UiScalar) = r.Rect.h = v.float32

template xy*(r: Box): Position = Position r.Rect.xy
template wh*(r: Box): Position = initPosition(r.w.float32, r.h.float32)

template x*(r: Position): UiScalar = r.Vec2.x.UiScalar
template y*(r: Position): UiScalar = r.Vec2.y.UiScalar
template `x=`*(r: Position, v: UiScalar) = r.Vec2.x = v.float32
template `y=`*(r: Position, v: UiScalar) = r.Vec2.y = v.float32

proc `+`*(rect: Box, xy: Position): Box =
  ## offset rect with xy vec2 
  result = rect
  result.x += xy.x
  result.y += xy.y

proc `-`*(rect: Box, xy: Position): Box =
  ## offset rect with xy vec2 
  result = rect
  result.x -= xy.x
  result.y -= xy.y

# proc `$`*(a: Position): string {.borrow.}
# proc `$`*(a: Box): string {.borrow.}

template scaled*(a: Box): Rect = Rect(a * common.uiScale.UiScalar)
template descaled*(a: Rect): Box = Box(a / common.uiScale)

template scaled*(a: Position): Vec2 = Vec2(a * common.uiScale.UiScalar)
template descaled*(a: Vec2): Position = Position(a / common.uiScale)

proc overlaps*(a, b: Position): bool = overlaps(Vec2(a), Vec2(b))
proc overlaps*(a: Position, b: Box): bool = overlaps(Vec2(a), Rect(b))
proc overlaps*(a: Box, b: Position): bool = overlaps(Rect(a), Vec2(b))
proc overlaps*(a: Box, b: Box): bool = overlaps(Rect(a), Rect(b))

proc sum*(rect: Rect): float32 =
  result = rect.x + rect.y + rect.w + rect.h
proc sum*(rect: (float32, float32, float32, float32)): float32 =
  result = rect[0] + rect[1] + rect[2] + rect[3]
proc sum*(rect: Box): UiScalar =
  result = rect.x + rect.y + rect.w + rect.h
proc sum*(rect: (UiScalar, UiScalar, UiScalar, UiScalar)): UiScalar =
  result = rect[0] + rect[1] + rect[2] + rect[3]

proc `$`*(a: Position): string =
  &"Position<{a.x:2.2f}, {a.y:2.2f}>"
proc `$`*(b: Box): string =
  let a = b.Rect
  &"Box<{a.x:2.2f}, {a.y:2.2f}; {a.x+a.w:2.2f}, {a.y+a.h:2.2f} [{a.w:2.2f} x {a.h:2.2f}]>"


