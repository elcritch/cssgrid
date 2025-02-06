import std/[strformat, sequtils, strutils, hashes, sets, tables]

import patty
export patty

import vmath, math
export math, vmath

import macros, macroutils
import typetraits

export sequtils, strutils, hashes, sets, tables, strformat

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Math Types
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

type
  UiSize* = GVec2[UiScalar]
  UiBox* = GVec4[UiScalar]

proc uiSize*(x, y: UiScalar): UiSize = UiSize(gvec2(x, y))
proc uiBox*(x, y, w, h: UiScalar): UiBox = UiBox(gvec4[UiScalar](x, y, w, h))

template w*(r: UiBox): UiScalar = r[2]
template h*(r: UiBox): UiScalar = r[3]
template `w=`*(r: UiBox, v: UiScalar) = r[2] = v
template `h=`*(r: UiBox, v: UiScalar) = r[3] = v

template xy*(r: UiBox): UiSize = UiSize r.xy
template wh*(r: UiBox): UiSize = uiSize(r.w, r.h)

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

proc `$`*(a: UiSize): string =
  fmt"UiSize<{a.x:.2f}, {a.y:.2f}>"

proc `$`*(b: UiBox): string =
  let a = GVec4[UiScalar](b)
  fmt"UiBox<{a.x:.2f}, {a.y:.2f}; [{a.w:.2f} x {a.h:.2f}]>"

# proc `<=`*(a,b: UiScalar): bool {.borrow.}

