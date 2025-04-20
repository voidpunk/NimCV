import
  regex,
  utils

proc parseStruct*(content: string): string =
  ## Parses a C++ struct definition and converts it to Nim code bindings
  result &= "# [STRUCT]\n"
  result &= content.stripComments()