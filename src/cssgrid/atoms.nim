import std/typetraits
import std/hashes
import std/tables
import std/macrocache
import std/strutils
import std/macros

import crc32

const atomCache = CacheTable"atomCache"

proc contains(ct: CacheTable, nm: string): bool =
  for k, v in ct:
    if nm == k:
      return true

type
  Atom* = distinct uint32

var atomNames: Table[Atom, string]

proc `==`*(a, b: Atom): bool {.borrow.}
proc hash*(a: Atom): Hash = a.Hash

proc `$`*(a: Atom): string =
  "@:\"" & atomNames[a] & "\""
proc `repr`*(a: Atom): string =
  "@:" & "" & $a.int & "\"" & atomNames[a] & "\""

proc new*(a: typedesc[Atom], name: string): Atom =
  result = Atom(crc32(name.nimIdentNormalize()))
  atomNames[result] = name

proc new*(a: typedesc[Atom], raw: int, desc = ""): Atom =
  result = Atom(raw)
  atomNames[result] =
    if desc.len() == 0:
      "`" & $raw & "`"
    else: desc

proc declAtom*(nm: string, checkDeclared=false): NimNode =
  let idVar = genSym(nskVar, "atomVar")
  let idStr = newStrLitNode(nm)
  let id = crc32(nm.nimIdentNormalize())
  if nm notin atomCache:
    result = quote do:
      block:
        var `idVar` {.global.} = Atom.new(`idStr`)
        `idVar`
    atomCache[nm] = result
  else:
    result = quote do:
      Atom(`id`)

macro atom*(name: typed): Atom =
  result = declAtom(name.strVal)

macro `@:`*(name: untyped): Atom =
  result = declAtom(name.strVal)

macro `@@`*(name: untyped): Atom =
  let nm = name.strVal
  if nm notin atomCache:
    error("not declared: " & name.repr, name)
  result = declAtom(name.strVal)

when isMainModule:
  import unittest

  suite "tests":
    test "atom test":
      expandMacros:
        let x: Atom = atom"new long name"
        let y: Atom = @:"new Long Name"
        let z: Atom = @@"new Long Name"
      echo "x: ", x
      echo "y: ", y
      echo "z: ", z
      echo "repr x: ", repr x
      echo "repr y: ", repr y
      echo "repr z: ", repr z
      check x == atom"new long name"
      check x == y
      check x == z
  
    test "atom more tests":
      let x: Atom = atom"newLongName"
      let y: Atom = @:newLongName
      let z: Atom = @:newLongName
      echo "x: ", repr x
      echo "y: ", repr y
      echo "z: ", repr z
      check x == atom"newLongName"
      check x == y
      check x == z
