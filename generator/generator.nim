import strutils, os
import parsers/enumparse
import downloader


proc parseHeaderFile*(filename: string): seq[string] =
  ## Parses a header file and returns Nim valid code bindings
  var currentBlock: seq[string] = @[]
  var inEnum = false
  # Parshe the file
  for line in filename.lines:
    if line.contains("enum") and line.contains("{"):
      inEnum = true
      currentBlock.add(line)
    elif inEnum:
      currentBlock.add(line)
      if line.contains("};"):
        inEnum = false
        let nimEnum = parseEnumBlock(currentBlock)
        if nimEnum.len > 0:
          result.add(nimEnum)
        currentBlock = @[]


proc writeFileLines(path: string, lines: seq[string]) =
  let file = open(path, fmWrite)
  defer: file.close()
  file.writeLine("import cpp\n")
  for line in lines:
    file.writeLine(line)



when isMainModule:
  let
    opencvVersion = "4.10.0"
    opencvSourcePath = "./opencv"
    nimcvSourcePath = "./src/NimCV"
  downloadOpencvSource(opencvVersion, opencvSourcePath)
  echo "⚙️ Parsing headers..."
  for path in walkDir(opencvSourcePath):
    if path.kind == pcFile:
      let (_, name, _) = path.path.splitFile()
      let outputNim = nimcvSourcePath / name & ".nim"
      writeFileLines(outputNim, parseHeaderFile(path.path))