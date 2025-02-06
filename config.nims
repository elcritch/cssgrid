import std/[os, strutils]

task test, "test all":
  for test in walkDirRec("tests/", skipSpecial=true):
    if test.endsWith(".nim"):
      echo "test: ", test
      exec "nim c -r " & test

# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
