import std/[strformat, sequtils, strutils, hashes, sets, tables]

import patty
export patty

import vmath, math
export math, vmath

import macros, macroutils
import typetraits

export sequtils, strutils, hashes, sets, tables, strformat

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct percentages
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
## Distinct vec types
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

const CssScalar {.strdefine: "cssgrid.FooBar".}: string = ""

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
  type UiScalar* = float32

type
  UiSize* = GVec2[UiScalar]
  UiBox* = GVec4[UiScalar]

proc uiSize*(x, y: float32): UiSize = UiSize(vec2(x, y))
proc uiBox*(x, y, w, h: UiScalar): UiBox = UiBox(gvec4[US()](x.float32, y.float32, w.float32, h.float32))

template w*(r: UiBox): UiScalar = r[2]
template h*(r: UiBox): UiScalar = r[3]
template `w=`*(r: UiBox, v: UiScalar) = r[2] = v
template `h=`*(r: UiBox, v: UiScalar) = r[3] = v

template xy*(r: UiBox): UiSize = UiSize r.xy
template wh*(r: UiBox): UiSize = uiSize(r.w.float32, r.h.float32)

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
  fmt"UiSize<{a.x.float32:2.2f}, {a.y.float32:2.2f}>"

proc `$`*(b: UiBox): string =
  let a = GVec4[US()](b)
  # &"UiBox<{a.x:2.2f}, {a.y:2.2f}; {a.x+a.w:2.2f}, {a.y+a.h:2.2f} [{a.w:2.2f} x {a.h:2.2f}]>"
  fmt"UiBox<{a.x:2.2f}, {a.y:2.2f}; [{a.w:2.2f} x {a.h:2.2f}]>"

# const
#   uiScale* = 1.0
