import
  regex,
  utils

proc parseClass*(content: string, posStart, posEnd: int): string =
  ## Parses a C++ class definition and converts it to Nim code bindings
  result &= "# [CLASS]\n"
  var input = content[posStart..posEnd]
  input.stripComments()
  result &= input