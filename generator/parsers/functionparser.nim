import
  regex,
  utils

proc parseFunc*(content: string, posStart, posEnd: int): string =
  ## Parses a C++ function declaration and converts it to Nim code bindings
  result &= "# [FUNCTION]\n"
  var input = content[posStart..posEnd]
  input.stripComments()
  result &= input