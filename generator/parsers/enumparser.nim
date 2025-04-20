import
  strutils, strformat, parseutils,
  regex,
  utils


proc analyzeEnum(input: string): (string, int) =
  ## Analyze enum and return name or empty string (if anonymous)
  ## along with position of starting '{' char
  let pattern = re2"enum\s*(?:\/\*.*?\*\/|\/\/[^\n]*)?\s*(\{|([a-zA-Z_]\w*)\s*\{)"
  var matches = RegexMatch2()
  if input.find(pattern, matches):
    if input[matches.group(0)] == "{":
      return ("", matches.boundaries.b)
    else:
      return (input[matches.group(1)], matches.boundaries.b)

proc processNumericLiteral(value: string): string =
  const
    hexPat = re2(r"^0[xX][0-9a-fA-F]+$")
    binPat = re2(r"^0[bB][01]+$")
    octPat = re2(r"^0[0-7]+$")
  var parsed: int
  if value.match(hexPat):
    assert parseHex(value, parsed) == value.len
  elif value.match(binPat):
    assert parseBin(value, parsed) == value.len
  elif value.match(octPat):
    assert parseOct(value, parsed) == value.len
  else:
    return value
  result = $parsed

proc parseEnum*(content: string): string =
  ## Parses a C++ enum definition and converts it to Nim code bindings
  result &= "# [ENUM]\n"
  var content = content.stripComments()
  let (enumName, position) = analyzeEnum(content)
  var namedEnum: bool
  if enumName.len > 0:
    result &= &"type {enumName} = enum\n"
    namedEnum = true
  else:
    result &= &"const\n"
    namedEnum = false
  var
    thisPos, nextPos = position + 1
    name, value: string
  while thisPos < content.len:
    nextPos = content.find("=", thisPos)
    if nextPos == -1:
      break
    name = content[thisPos..nextPos-1].strip()
    thisPos = nextPos + 1
    nextPos = content.find(",", thisPos)
    if nextPos == -1:
      nextPos = content.find("}", thisPos)
      if nextPos == -1:
        break
    value = content[thisPos..nextPos-1].strip()
    value = processNumericLiteral(value)
    thisPos = nextPos + 1
    result &= &"  {name} = {value}\n"