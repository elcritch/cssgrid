import std/[strformat, sequtils, strutils, hashes, sets, tables]

import pkg/patty
export patty

import vmath, bumpy, math
export math, vmath, bumpy

import macros, macroutils
import typetraits

export sequtils, strutils, hashes, sets, tables, strformat

template borrowMaths*(typ, base: typedesc) =
  proc `+` *(x, y: typ): typ = typ(`+`(base(x), base(y)))
  proc `-` *(x, y: typ): typ = typ(`-`(base(x), base(y)))
  
  when base isnot uint and base isnot uint64 and base isnot uint32:
    proc `-` *(x: typ): typ = typ(`-`(base(x)))

  proc `*` *(x, y: typ): typ = typ(`*`(base(x), base(y)))
  proc `/` *(x, y: typ): typ = typ(`/`(base(x), base(y)))

  proc `min` *(x: typ, y: typ): typ {.borrow.}
  proc `max` *(x: typ, y: typ): typ {.borrow.}
  proc `mod` *(x: typ, y: typ): typ {.borrow.}

  proc `<` * (x, y: typ): bool {.borrow.}
  proc `<=` * (x, y: typ): bool {.borrow.}
  proc `==` * (x, y: typ): bool {.borrow.}
  when base is SomeFloat:
    proc `~=` * (x, y: typ): bool {.borrow.}

  proc `+=` * (x: var typ, y: typ) {.borrow.}
  proc `-=` * (x: var typ, y: typ) {.borrow.}
  when base is SomeFloat:
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
  proc `op`*(a: T, b: UiScalar): T = T(`op`(B(a), b))

template genEqOp[T, B](op: untyped) =
  # proc `op`*(a: var T, b: float32) = `op`(B(a), b.T)
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

const CssScalar {.strdefine: "cssgrid.scalar".}: string = "float32"

when CssScalar == "float":
  type UiScalar* = distinct float
elif CssScalar == "float32":
  type UiScalar* = distinct float32
elif CssScalar == "float64":
  type UiScalar* = distinct float64
elif CssScalar == "int":
  type UiScalar* = distinct int
elif CssScalar == "int32":
  type UiScalar* = distinct int32
elif CssScalar == "int64":
  type UiScalar* = distinct int64
else:
  {.error: "unhandled UiScalar type: " & CssScalar.}

borrowMaths(UiScalar, distinctBase(UiScalar))

converter toUI*[F: float|int|float32](x: static[F]): UiScalar = UiScalar x

proc high*(_: typedesc[UiScalar]): UiScalar =
  distinctBase(UiScalar).high().UiScalar
proc low*(_: typedesc[UiScalar]): UiScalar =
  distinctBase(UiScalar).low().UiScalar

{.push hint[ConvFromXtoItselfNotNeeded]: on.}
# proc `'ux`*(n: string): UiScalar =
#   ## numeric literal UI Coordinate unit
#   result = UiScalar(parseFloat(n))

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct vec types
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
type
  UiSize* = distinct GVec2[UiScalar]
  UiPos* = distinct GVec2[UiScalar]

proc uiSize*(x, y: UiScalar): UiSize = UiSize(gvec2(x, y))
proc uiSize*(x, y: float): UiSize = uiSize(x.UiScalar, y.UiScalar)

proc uiPos*(x, y: UiScalar): UiPos = UiPos(gvec2(x, y))
proc uiPos*(x, y: float): UiPos = uiPos(x.UiScalar, y.UiScalar)

proc toPos*(r: UiSize): UiPos = GVec2[UiScalar](r).UiPos
proc toSize*(r: UiPos): UiSize = GVec2[UiScalar](r).UiSize

proc `[]=`*(a: var UiSize, i: int, v: UiScalar) =
  GVec2[UiScalar](a)[i] = v
proc `[]=`*(a: var UiPos, i: int, v: UiScalar) =
  GVec2[UiScalar](a)[i] = v
proc `[]`*(a: UiPos | UiSize, i: int): UiScalar =
  GVec2[UiScalar](a)[i]

genBoolOp[UiSize, GVec2[UiScalar]](`==`)
genBoolOp[UiSize, GVec2[UiScalar]](`!=`)
when UiScalar is SomeFloat:
  genBoolOp[UiSize, GVec2[UiScalar]](`~=`)

applyOps(UiSize, GVec2[UiScalar], genOp, `+`, `-`, `/`, `*`)
applyOps(UiSize, GVec2[UiScalar], genOp, `mod`)
applyOps(UiSize, GVec2[UiScalar], genEqOp, `+=`, `-=`, `*=`)
when UiScalar is SomeFloat:
  applyOps(UiSize, GVec2[UiScalar], genEqOp, `/=`)
applyOps(UiSize, GVec2[UiScalar], genFloatOp, `*`, `/`)
applyOps(UiSize, GVec2[UiScalar], genMathFn, `-`)

genBoolOp[UiPos, GVec2[UiScalar]](`==`)
genBoolOp[UiPos, GVec2[UiScalar]](`!=`)
when UiScalar is SomeFloat:
  genBoolOp[UiPos, GVec2[UiScalar]](`~=`)

applyOps(UiPos, GVec2[UiScalar], genOp, `+`, `-`, `/`, `*`)
applyOps(UiPos, GVec2[UiScalar], genOp, `mod`)
applyOps(UiPos, GVec2[UiScalar], genEqOp, `+=`, `-=`, `*=`)
when UiScalar is SomeFloat:
  applyOps(UiPos, GVec2[UiScalar], genEqOp, `/=`)
applyOps(UiPos, GVec2[UiScalar], genFloatOp, `*`, `/`)
applyOps(UiPos, GVec2[UiScalar], genMathFn, `-`)

type
  UiBox* = distinct GVec4[UiScalar]

proc uiBox*(x, y, w, h: UiScalar): UiBox = UiBox(gvec4[UiScalar](x, y, w, h))
proc uiBox*(x, y, w, h: float): UiBox = UiBox(gvec4[UiScalar](x.UiScalar, y.UiScalar, w.UiScalar, h.UiScalar))

proc `[]=`*(a: var UiBox, i: int, v: UiScalar) =
  GVec4[UiScalar](a)[i] = v
proc `[]`*(a: UiBox, i: int): UiScalar =
  GVec4[UiScalar](a)[i]

{.push hint[ConvFromXtoItselfNotNeeded]: on.}

# applyOps(UiBox, GVec4[UiScalar], genOp, `+`)
applyOps(UiBox, GVec4[UiScalar], genFloatOp, `*`, `/`)
genBoolOp[UiBox, GVec4[UiScalar]](`==`)
genEqOpC[UiBox, GVec4[UiScalar], GVec2[UiScalar]](`xy=`)

proc x*(r: UiBox): UiScalar = Gvec4[UiScalar](r)[0]
proc y*(r: UiBox): UiScalar = Gvec4[UiScalar](r)[1]
proc w*(r: UiBox): UiScalar = Gvec4[UiScalar](r)[2]
proc h*(r: UiBox): UiScalar = Gvec4[UiScalar](r)[3]
proc x*(r: var UiBox): var UiScalar = Gvec4[UiScalar](r)[0]
proc y*(r: var UiBox): var UiScalar = Gvec4[UiScalar](r)[1]
proc w*(r: var UiBox): var UiScalar = Gvec4[UiScalar](r)[2]
proc h*(r: var UiBox): var UiScalar = Gvec4[UiScalar](r)[3]

proc `x=`*(r: var UiBox, v: UiScalar) = r[0] = v
proc `y=`*(r: var UiBox, v: UiScalar) = r[1] = v
proc `w=`*(r: var UiBox, v: UiScalar) = r[2] = v
proc `h=`*(r: var UiBox, v: UiScalar) = r[3] = v

proc `+`*(a, b: UiBox): UiBox =
  ## Add two boxes together.
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.w = a.w
  result.h = a.h

## Setup 2D Points
proc xy*(r: UiBox): UiPos = uiPos(r.x, r.y)
proc wh*(r: UiBox): UiSize = uiSize(r.w, r.h)

## Setup 2D UiBox
proc w*(r: UiSize): UiScalar = GVec2[UiScalar](r)[0]
proc h*(r: UiSize): UiScalar = GVec2[UiScalar](r)[1]
proc w*(r: var UiSize): var UiScalar = GVec2[UiScalar](r)[0]
proc h*(r: var UiSize): var UiScalar = GVec2[UiScalar](r)[1]
proc `w=`*(r: var UiSize, v: UiScalar) = r[0] = v
proc `h=`*(r: var UiSize, v: UiScalar) = r[1] = v

proc `+`*(rect: UiBox, xy: UiSize): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.w += xy.w
  result.h += xy.h

proc `-`*(rect: UiBox, xy: UiSize): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.w -= xy.w
  result.h -= xy.h

## Setup 2D UiPos
proc x*(r: UiPos): UiScalar = GVec2[UiScalar](r)[0]
proc y*(r: UiPos): UiScalar = GVec2[UiScalar](r)[1]
proc x*(r: var UiPos): var UiScalar = GVec2[UiScalar](r)[0]
proc y*(r: var UiPos): var UiScalar = GVec2[UiScalar](r)[1]
proc `x=`*(r: var UiPos, v: UiScalar) = r[0] = v
proc `y=`*(r: var UiPos, v: UiScalar) = r[1] = v

proc `+`*(rect: UiBox, xy: UiPos): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.x += xy.x
  result.y += xy.y

proc `-`*(rect: UiBox, xy: UiPos): UiBox =
  ## offset rect with xy vec2 
  result = rect
  result.x -= xy.x
  result.y -= xy.y

proc sum*(rect: UiBox): UiScalar =
  result = rect.x + rect.y + rect.w + rect.h
proc sum*(rect: (UiScalar, UiScalar, UiScalar, UiScalar)): UiScalar =
  result = rect[0] + rect[1] + rect[2] + rect[3]

proc toRect*(box: UiBox): Rect = rect(box.x.float32, box.y.float32, box.w.float32, box.h.float32)
proc toVec*(p: UiPos): Vec2 = vec2(p.x.float32, p.y.float32)
proc toVec*(p: UiSize): Vec2 = vec2(p.w.float32, p.h.float32)

proc hash*(p: UiBox): Hash =
  result = Hash(0)
  result = result !& hash(p[0])
  result = result !& hash(p[1])
  result = result !& hash(p[2])
  result = result !& hash(p[3])
  result = !$result

proc hash*(p: UiPos | UiSize): Hash =
  result = Hash(0)
  result = result !& hash(p[0])
  result = result !& hash(p[1])
  result = !$result

proc `$`*(a: UiPos): string =
  when typeof(UiScalar) is SomeFloat:
    fmt"UiPox<{a.x.float32:2.2f}, {a.y.float32:2.2f}>"
  else:
    fmt"UiPos<{$a.x}, {$a.y}>"

proc `$`*(a: UiSize): string =
  when typeof(UiScalar) is SomeFloat:
    fmt"UiSize<{a.w.float32:2.2f}, {a.h.float32:2.2f}>"
  else:
    fmt"UiSize<{$a.w}, {$a.h}>"

proc `$`*(a: UiBox): string =
  when typeof(UiScalar) is SomeFloat:
    fmt"UiBox<{a.x:2.2f}, {a.y:2.2f}; [{a.w:2.2f} x {a.h:2.2f}]>"
  else:
    fmt"UiBox<{$a.x}, {$a.y}; [{$a.w} x {$a.h}]>"

