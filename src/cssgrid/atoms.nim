import std/typetraits
import std/hashes
import std/sets
import std/tables
import std/macrocache
import std/sequtils
import std/strutils
import std/macros

import crc32

const atomCache = CacheTable"atomCache"

proc contains(ct: CacheTable, nm: string): bool =
  for k, v in ct:
    if nm == k:
      return true

type
  Atom* = distinct int32

var atomNames: Table[Atom, string]

proc `==`*(a, b: Atom): bool {.borrow.}
proc hash*(a: Atom): Hash {.borrow.}

proc `$`*(a: Atom): string =
  "atom\"" & atomNames[a] & "\""
proc `repr`*(a: Atom): string =
  "@`" & atomNames[a] & "`(" & $a.int & ")"

proc new*(a: typedesc[Atom], name: string): Atom =
  result = Atom(crc32(name.nimIdentNormalize()))
  atomNames[result] = name

proc declAtomImpl(nm: string): NimNode =
  let idVar = genSym(nskVar, "atomVar")
  let idStr = newStrLitNode(nm)
  result = quote do:
    block:
      var `idVar` {.global.} = Atom.new(`idStr`)
      `idVar`

macro atom*(name: typed): Atom =
  result = declAtomImpl(name.strVal)

macro `@!`*(name: untyped): Atom =
  result = declAtomImpl(name.strVal)

macro `@@`*(name: untyped): Atom =
  result = declAtomImpl(name.strVal)

when isMainModule:
  import unittest

  suite "tests":

    test "atom test":
      expandMacros:
        let x: Atom = atom"new long name"
        let y: Atom = @!"new Long Name"
        let z: Atom = @@"new Long Name"

        echo "x: ", x
        echo "y: ", y
        echo "repr x: ", repr x
        echo "repr y: ", repr y
        check x == atom"new long name"
        check x == y
        check x == z
    
    test "atom more tests":
      let x: Atom = atom"newLongName"
      let y: Atom = @!newLongName
      let z: Atom = @!newLongName
      echo "x: ", repr x
      echo "y: ", repr y
      check x == atom"newLongName"
      check x == y
      check x == z
