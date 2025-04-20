import
  regex,
  utils

proc parseClass*(content: string): string =
  ## Parses a C++ class definition and converts it to Nim code bindings
  result &= "# [CLASS]\n"
  result &= content.stripComments()