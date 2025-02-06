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
  # proc `+` *(x: typ, y: static[float32|float64|int]): typ = typ(`+`(base x, base y))
  # proc `-` *(x: typ, y: static[float32|float64|int]): typ = typ(`-`(base x, base y))
  # proc `+` *(x: static[float32|float64|int], y: typ): typ = typ(`+`(base x, base y))
  # proc `-` *(x: static[float32|float64|int], y: typ): typ = typ(`-`(base x, base y))

  proc `*` *(x, y: typ): typ = typ(`*`(base(x), base(y)))
  proc `/` *(x, y: typ): typ = typ(`/`(base(x), base(y)))

  # proc `*` *(x: typ, y: static[distinctBase(typ)]): typ = typ(`*`(base(x), base(y)))
  # proc `/` *(x: typ, y: static[distinctBase(typ)]): typ = typ(`/`(base(x), base(y)))
  # proc `*` *(x: static[base], y: typ): typ = typ(`*`(base(x), base(y)))
  # proc `/` *(x: static[base], y: typ): typ = typ(`/`(base(x), base(y)))

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
  UiScalar* = distinct float32

# borrowMaths(UiScalar, float32)

# converter toUI*[F: float|int|float32](x: static[F]): UiScalar = UiScalar x

# proc `'ux`*(n: string): UiScalar =
#   ## numeric literal UI Coordinate unit
#   result = UiScalar(parseFloat(n))

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct vec types
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
type
  UiSize* = distinct Vec2

proc uiSize*(x, y: float32): UiSize = UiSize(vec2(x, y))
genBoolOp[UiSize, Vec2](`==`)
genBoolOp[UiSize, Vec2](`!=`)
genBoolOp[UiSize, Vec2](`~=`)

applyOps(UiSize, Vec2, genOp, `+`, `-`, `/`, `*`, `mod`, `zmod`, `min`, `zmod`)
applyOps(UiSize, Vec2, genEqOp, `+=`, `-=`, `*=`, `/=`)
applyOps(UiSize, Vec2, genMathFn, `-`, sin, cos, tan, arcsin, arccos, arctan, sinh, cosh, tanh)
applyOps(UiSize, Vec2, genMathFn, exp, ln, log2, sqrt, floor, ceil, abs) 
applyOps(UiSize, Vec2, genFloatOp, `*`, `/`)

type
  UiBox* = distinct Rect

proc uiBox*(x, y, w, h: float32): UiBox = UiBox(rect(x, y, w, h))
proc uiBox*(x, y, w, h: UiScalar): UiBox = UiBox(rect(x.float32, y.float32, w.float32, h.float32))

applyOps(UiBox, Rect, genOp, `+`)
applyOps(UiBox, Rect, genFloatOp, `*`, `/`)
genBoolOp[UiBox, Rect](`==`)
genEqOpC[UiBox, Rect, Vec2](`xy=`)

template x*(r: UiBox): UiScalar = r.Rect.x.UiScalar
template y*(r: UiBox): UiScalar = r.Rect.y.UiScalar
template w*(r: UiBox): UiScalar = r.Rect.w.UiScalar
template h*(r: UiBox): UiScalar = r.Rect.h.UiScalar
template `x=`*(r: UiBox, v: UiScalar) = r.Rect.x = v.float32
template `y=`*(r: UiBox, v: UiScalar) = r.Rect.y = v.float32
template `w=`*(r: UiBox, v: UiScalar) = r.Rect.w = v.float32
template `h=`*(r: UiBox, v: UiScalar) = r.Rect.h = v.float32

template xy*(r: UiBox): UiSize = UiSize r.Rect.xy
template wh*(r: UiBox): UiSize = uiSize(r.w.float32, r.h.float32)

template x*(r: UiSize): UiScalar = r.Vec2.x.UiScalar
template y*(r: UiSize): UiScalar = r.Vec2.y.UiScalar
template `x=`*(r: UiSize, v: UiScalar) = r.Vec2.x = v.float32
template `y=`*(r: UiSize, v: UiScalar) = r.Vec2.y = v.float32

proc `+`*(rect: UiBox, xy: UiSize): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.x += xy.x
  result.y += xy.y

proc `-`*(rect: UiBox, xy: UiSize): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.x -= xy.x
  result.y -= xy.y

proc sum*(rect: Rect): float32 =
  result = rect.x + rect.y + rect.w + rect.h
proc sum*(rect: (float32, float32, float32, float32)): float32 =
  result = rect[0] + rect[1] + rect[2] + rect[3]
proc sum*(rect: UiBox): UiScalar =
  result = rect.x + rect.y + rect.w + rect.h
proc sum*(rect: (UiScalar, UiScalar, UiScalar, UiScalar)): UiScalar =
  result = rect[0] + rect[1] + rect[2] + rect[3]

proc `$`*(a: UiSize): string =
  fmt"UiSize<{a.x.float32:2.2f}, {a.y.float32:2.2f}>"

proc `$`*(b: UiBox): string =
  let a = b.Rect
  # &"UiBox<{a.x:2.2f}, {a.y:2.2f}; {a.x+a.w:2.2f}, {a.y+a.h:2.2f} [{a.w:2.2f} x {a.h:2.2f}]>"
  fmt"UiBox<{a.x:2.2f}, {a.y:2.2f}; [{a.w:2.2f} x {a.h:2.2f}]>"

# const
#   uiScale* = 1.0
