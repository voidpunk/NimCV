import
  regex,
  utils

proc parseTypedef*(content: string, posStart, posEnd: int): string =
  ## Parses a C++ typedef definition and converts it to Nim code bindings
  result &= "# [TYPEDEF]\n"
  var input = content[posStart..posEnd]
  input.stripComments()
  result &= input
