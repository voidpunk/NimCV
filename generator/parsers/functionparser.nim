import
  regex,
  utils

proc parseFunc*(content: string): string =
  ## Parses a C++ function declaration and converts it to Nim code bindings
  result &= "# [FUNCTION]\n"
  result &= content.stripComments()