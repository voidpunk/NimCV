import
  regex,
  utils

proc parseEnum*(content: string, posStart, posEnd: int): string =
  ## Parses a C++ enum definition and converts it to Nim code bindings
  result &= "# [ENUM]\n"
  var input = content[posStart..posEnd]
  input.stripComments()
  result &= input