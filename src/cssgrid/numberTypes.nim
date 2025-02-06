import std/[strformat, sequtils, strutils, hashes, sets, tables]

import pkg/patty
export patty

import vmath, bumpy, math
export math, vmath, bumpy

import macros, macroutils
import typetraits

export sequtils, strutils, hashes, sets, tables, strformat

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
  static:
    echo "GEN OP: ", $T, " B: ", $B, " op: ", astToStr(op)
  proc `op`*(a, b: T): T = T(`op`(B(a), B(b)))

macro applyOps(a, b: typed, fn: untyped, ops: varargs[untyped]) =
  result = newStmtList()
  for op in ops:
    result.add quote do:
      `fn`[`a`, `b`](`op`)

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct percentages
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

const CssScalar {.strdefine: "cssgrid.scalar".}: string = ""

when CssScalar == "float":
  type UiScalar* = float
elif CssScalar == "float32":
  type UiScalar* = float32
elif CssScalar == "float64":
  type UiScalar* = float64
elif CssScalar == "int32":
  type UiScalar* = int32
elif CssScalar == "int64":
  type UiScalar* = int64
elif CssScalar == "uint32":
  type UiScalar* = uint32
elif CssScalar == "uint64":
  type UiScalar* = uint64
else:
  type UiScalar* = float

# borrowMaths(UiScalar, float32)

converter toUI*[F: float|int|float32](x: static[F]): UiScalar = UiScalar x

# proc `'ux`*(n: string): UiScalar =
#   ## numeric literal UI Coordinate unit
#   result = UiScalar(parseFloat(n))

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct vec types
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
type
  UiSize* = distinct GVec2[UiScalar]

proc uiSize*(x, y: UiScalar): UiSize = UiSize(gvec2(x, y))

genBoolOp[UiSize, GVec2[UiScalar]](`==`)
genBoolOp[UiSize, GVec2[UiScalar]](`!=`)
genBoolOp[UiSize, GVec2[UiScalar]](`~=`)

applyOps(UiSize, GVec2[UiScalar], genOp, `+`, `-`, `/`, `*`)
applyOps(UiSize, GVec2[UiScalar], genOp, `mod`, `zmod`, `zmod`)
applyOps(UiSize, GVec2[UiScalar], genEqOp, `+=`, `-=`, `*=`, `/=`)
applyOps(UiSize, GVec2[UiScalar], genMathFn, `-`, sin, cos, tan, arcsin, arccos, arctan, sinh, cosh, tanh)
applyOps(UiSize, GVec2[UiScalar], genMathFn, exp, ln, log2, sqrt, floor, ceil, abs) 
applyOps(UiSize, GVec2[UiScalar], genFloatOp, `*`, `/`)

type
  UiBox* = distinct GVec4[UiScalar]

proc uiBox*(x, y, w, h: UiScalar): UiBox = UiBox(gvec4[UiScalar](x, y, w, h))

applyOps(UiBox, GVec4[UiScalar], genOp, `+`)
applyOps(UiBox, GVec4[UiScalar], genFloatOp, `*`, `/`)
genBoolOp[UiBox, GVec4[UiScalar]](`==`)
genEqOpC[UiBox, GVec4[UiScalar], GVec2[UiScalar]](`xy=`)

template x*(r: UiBox): var UiScalar = Gvec4[UiScalar](r)[1]
template y*(r: UiBox): var UiScalar = Gvec4[UiScalar](r)[1]
template w*(r: UiBox): var UiScalar = Gvec4[UiScalar](r)[2]
template h*(r: UiBox): var UiScalar = Gvec4[UiScalar](r)[3]

template `x=`*(r: UiBox, v: UiScalar) = r.x = v
template `y=`*(r: UiBox, v: UiScalar) = r.y = v
template `w=`*(r: UiBox, v: UiScalar) = r.w = v
template `h=`*(r: UiBox, v: UiScalar) = r.h = v

template xy*(r: UiBox): UiSize = r.xy
template wh*(r: UiBox): UiSize = uiSize(r.w.float32, r.h.float32)

template x*(r: UiSize): UiScalar = GVec2[UiScalar](r)[0]
template y*(r: UiSize): UiScalar = GVec2[UiScalar](r)[1]
template `x=`*(r: UiSize, v: UiScalar) = r.x = v
template `y=`*(r: UiSize, v: UiScalar) = r.y = v

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

proc `$`*(a: UiBox): string =
  fmt"UiBox<{a.x:2.2f}, {a.y:2.2f}; [{a.w:2.2f} x {a.h:2.2f}]>"

