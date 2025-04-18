import strutils, os
import downloader


type
  ParsedEntity = object
    content: string
    kind: string
  ParserState = enum
    inNormal, inClass, inStruct, inEnum, inTypedef, inFunc

proc parseClass(content: string, posStart, posEnd: int): string =
  ## Parses a C++ class definition and converts it to Nim code bindings
  result &= "[CLASS]\n"
  result &= content[posStart..posEnd]

proc parseEnum(content: string, posStart, posEnd: int): string =
  ## Parses a C++ enum definition and converts it to Nim code bindings
  result &= "[ENUM]\n"
  result &= content[posStart..posEnd]

proc parseStruct(content: string, posStart, posEnd: int): string =
  ## Parses a C++ struct definition and converts it to Nim code bindings
  result &= "[STRUCT]\n"
  result &= content[posStart..posEnd]

proc parseTypedef(content: string, posStart, posEnd: int): string =
  ## Parses a C++ typedef definition and converts it to Nim code bindings
  result &= "[TYPEDEF]\n"
  result &= content[posStart..posEnd]

proc parseFunc(content: string, posStart, posEnd: int): string =
  ## Parses a C++ function declaration and converts it to Nim code bindings
  result &= "[FUNCTION]\n"
  result &= content[posStart..posEnd]

proc skipComments(content: string, pos: var int) =
  ## 
  while pos < content.len:
    if content[pos] in {' ', '\t', '\n', '\r'}:
      inc pos
    if content.continuesWith("/*M//", pos):
      let found = content.find("//M*/", pos)
      if found != -1:
        pos = found + 5
    elif content.continuesWith("//", pos):
      let found = content.find("\n", pos)
      if found != -1:
        pos = found + 1
    elif content.continuesWith("/*", pos):
      let found = content.find("*/", pos)
      if found != -1:
        pos = found + 2
    else:
      break

proc parseHeader(filePath: string): seq[ParsedEntity] =
  ## Main parser that reads a C++ header file and extracts entities
  var
    content = readFile(filePath)
    state = inNormal
    braceDepth = 0
    pos = 0
    posStart = 0
    posEnd = 0
    parsedContent: string
    entityKind: string
  while pos < content.len:
    skipComments(content, pos)
    case state:
    of inNormal:
      if content.continuesWith("class", pos):
        state = inClass
        posStart = pos
      elif content.continuesWith("enum", pos):
        state = inEnum
        posStart = pos
      elif content.continuesWith("struct", pos):
        state = inStruct
        posStart = pos
      elif content.continuesWith("typedef", pos):
        state = inTypedef
        posStart = pos
      elif content.continuesWith("CV_EXPORTS", pos):
        state = inFunc
        posStart = pos
    of inClass, inStruct, inEnum, inTypedef:
      if content[pos] == '{':
        inc braceDepth
      elif content[pos] == '}':
        dec braceDepth
        if braceDepth <= 0:
          posEnd = pos
          case state:
          of inClass:
            parsedContent = parseClass(content, posStart, posEnd)
            entityKind = "class"
          of inEnum:
            parsedContent = parseEnum(content, posStart, posEnd)
            entityKind = "enum"
          of inStruct:
            parsedContent = parseStruct(content, posStart, posEnd)
            entityKind = "struct"
          of inTypedef:
            parsedContent = parseTypedef(content, posStart, posEnd)
            entityKind = "typedef"
          else: raise newException(Exception, "State inNormal not expected")
          if parsedContent != "":
            result.add ParsedEntity(
              content: parsedContent,
              kind: entityKind
            )
          state = inNormal
    of inFunc:
      let found = content.find(");", posStart)
      if found != -1:
        posEnd = found + 2
        parsedContent = parseFunc(content, posStart, posEnd)
        pos = posEnd
        if parsedContent != "":
          result.add ParsedEntity(
            content: parsedContent,
            kind: entityKind
          )
        state = inNormal
    inc pos

proc generateBindings(filePath: string, outputPath: string) =
  ## Generates Nim bindings from a C++ header file
  let entities = parseHeader(filePath)
  var output = "# Auto-generated OpenCV bindings\n"
  for entity in entities:
    case entity.kind:
    of "class":
      output.add entity.content & "\n"
    of "enum":
      output.add entity.content & "\n"
    of "struct":
      output.add entity.content & "\n"
    of "typedef":
      output.add entity.content & "\n"
    of "function":
      output.add entity.content & "\n"
    else: discard
  writeFile(outputPath, output)



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
      generateBindings(path.path, outputNim)