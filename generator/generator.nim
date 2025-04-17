import 
  strutils, strformat, os, times,
  progress,
  parsers/enumparse,
  downloader


proc parseHeaderFile*(filePath: string): seq[string] =
  ## Parses a header file and returns valid Nim code to bind it
  var 
    currentBlock: seq[string] = @[]
    inEnum = false
    lineCount = 0
    startTime = getTime()
  # First count total lines for accurate progress
  for _ in filePath.lines:
    inc lineCount
  # Reset file reading
  let file = open(filePath)
  defer: file.close()
  # Start the progress bar
  var bar = newProgressBar(total = lineCount)
  bar.start()
  # Parse the header
  for line in file.lines:
    bar.increment()
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
  # Log info
  bar.finish()
  let elapsedTime = (getTime() - startTime).inMilliseconds
  echo &"Processed {lineCount} lines in {elapsedTime} ms"
  echo &"Found {result.len} enums\n"


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
  for path in walkDir(opencvSourcePath):
    if path.kind == pcFile:
      let (_, name, ext) = path.path.splitFile()
      let outputNim = nimcvSourcePath / name & ".nim"
      echo "⚙️ Parsing header: " & name & ext
      writeFileLines(outputNim, parseHeaderFile(path.path))