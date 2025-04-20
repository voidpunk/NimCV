import
  regex,
  utils

proc parseTypedef*(content: string): string =
  ## Parses a C++ typedef definition and converts it to Nim code bindings
  result &= "# [TYPEDEF]\n"
  result &= content.stripComments()
