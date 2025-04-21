import
  strutils, sequtils, strformat, parseutils, tables, algorithm,
  regex,
  utils


## register table to keep trace of values during substitution
var register = initTable[string, string]()

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
  ## Parse eventual hex, bin, oct numbers to decimal
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

proc processOperationLiteral(value: string): string =
  ## Replace eventual expressions with the resulting value
  result = value
  const expPat = re2"[()<>+\-*/]"
  const namePat = re2"[A-Za-z_][A-Za-z0-9_]*"
  if value.contains(expPat) and value.len > 2:
    var tempVal: string
    if not value.contains(namePat):
      let startExp = value.find("(")
      if startExp != -1:
        let endExp = value.find(")")
        let exp = value[startExp+1..endExp-1].split()
        let (a, b) = (parseInt(exp[0]), parseInt(exp[2]))
        tempVal = case exp[1]:
        of "<<": $(a shl b) & value[endExp+1..^1]
        of ">>": $(a shr b) & value[endExp+1..^1]
        else: raise newException(ValueError, "Unimplemented operator")
      else:
        tempVal = value
      let exp = tempVal.split()
      if exp.len > 1:
        let (a, b) = (parseInt(exp[0]), parseInt(exp[2]))
        result = case exp[1]:
        of "<<": $(a shl b)
        of ">>": $(a shr b)
        of "+" : $(a  +  b)
        of "-" : $(a  -  b)
        of "*" : $(a  *  b)
        else: raise newException(ValueError, "Unimplemented operator")
      else:
        result = tempVal

proc processSubstitution(name, value: string): string =
  ## Recursively substitutes variables until only numbers remain
  result = value
  register[name] = value
  const namePat = re2"[A-Za-z_][A-Za-z0-9_]*"
  var changed = true
  while changed:
    changed = false
    for match in result.findAll(namePat).toSeq.reversed:
      let varName = result[match.boundaries]
      var replacement = register[varName]
      replacement = processOperationLiteral(replacement)
      # Only substitute if the var hasn't been processed yet
      if replacement.contains(namePat):
        var processed = processSubstitution(varName, replacement)
        processed = processOperationLiteral(processed)
        register[varName] = processed
      result.delete(match.boundaries)
      result.insert(register[varName], match.boundaries.a)
      changed = true

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
    values: seq[string]
    duplicates = initOrderedTable[string, string]()
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
    thisPos = nextPos + 1
    value = processNumericLiteral(value)
    value = processOperationLiteral(value)
    value = processSubstitution(name, value)
    value = processOperationLiteral(value)
    if value notin values:
      values.add(value)
      result &= &"  {name} = {value}\n"
    else:
      duplicates[name] = value
  if duplicates.len > 0:
    result &= "const\n"
    for key, val in duplicates.pairs:
      result &= &"  {key} = {val}\n"