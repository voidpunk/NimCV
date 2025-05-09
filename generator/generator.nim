import
  strutils, os,
  downloader,
  parsers/[classparser, enumparser, functionparser, structparser, typedefparser]


type
  ParserState = enum
    Header, Class, Struct, Enum, Typedef, Function
  ParsedEntity = object
    content: string
    kind: ParserState

proc skipComments(content: string, pos: var int) =
  ## Skip all comments by increasing the reading pos to after them
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
    state = Header
    entityKind: ParserState
    parsedContent: string
    braceDepth, pos, posStart, posEnd: int
  while pos < content.len:
    skipComments(content, pos)
    case state:
    of Header:
      if content.continuesWith("class", pos):
        state = Class
        posStart = pos
      elif content.continuesWith("enum", pos):
        state = Enum
        posStart = pos
      elif content.continuesWith("struct", pos):
        state = Struct
        posStart = pos
      elif content.continuesWith("typedef", pos):
        state = Typedef
        posStart = pos
      elif content.continuesWith("CV_EXPORTS", pos):
        state = Function
        posStart = pos
    of Class, Struct, Enum:
      if content[pos] == '{':
        inc braceDepth
      elif content[pos] == '}':
        dec braceDepth
        if braceDepth <= 0:
          posEnd = pos
          case state:
          of Class:
            parsedContent = parseClass(content[posStart..posEnd])
            entityKind = Class
          of Enum:
            parsedContent = enumparser.parseEnum(content[posStart..posEnd])
            entityKind = Enum
          of Struct:
            parsedContent = parseStruct(content[posStart..posEnd])
            entityKind = Struct
          else: raise newException(Exception, "State Header not expected")
          if parsedContent != "":
            result.add ParsedEntity(
              content: parsedContent,
              kind: entityKind
            )
          state = Header
    of Typedef:
      let found = content.find(";", posStart)
      if found != -1:
        posEnd = found + 1
        parsedContent = parseTypedef(content[posStart..posEnd])
        pos = posEnd
        if parsedContent != "":
          result.add ParsedEntity(
            content: parsedContent,
            kind: Typedef
          )
        state = Header
    of Function:
      let found = content.find(");", posStart)
      if found != -1:
        posEnd = found + 2
        parsedContent = parseFunc(content[posStart..posEnd])
        pos = posEnd
        if parsedContent != "":
          result.add ParsedEntity(
            content: parsedContent,
            kind: Function
          )
        state = Header
    inc pos

proc generateBindings(filePath: string, outputPath: string) =
  ## Generates Nim bindings from a C++ header file
  let entities = parseHeader(filePath)
  var output = "# Auto-generated OpenCV bindings\n"
  for entity in entities:
    case entity.kind:
    of Class:
      output.add entity.content & "\n"
    of Enum:
      output.add entity.content & "\n"
    of Struct:
      output.add entity.content & "\n"
    of Typedef:
      output.add entity.content & "\n"
    of Function:
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