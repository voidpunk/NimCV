import
  regex,
  utils

proc parseStruct*(content: string, posStart, posEnd: int): string =
  ## Parses a C++ struct definition and converts it to Nim code bindings
  result &= "# [STRUCT]\n"
  var input = content[posStart..posEnd]
  input.stripComments()
  result &= input