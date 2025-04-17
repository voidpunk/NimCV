# Package

version       = "0.1.0"
author        = "Nil"
description   = "OpenCV bindings for Nim"
license       = "GPL-3.0-only"
srcDir        = "src"


# Dependencies

requires "nim >= 2.2.2"

# required for codegen:
# zippy, progress

task codegen, "Generate code":
  exec "nim r --define:ssl --verbosity:0 --warnings:off --hints:off generator/generator.nim"