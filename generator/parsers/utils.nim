import regex

proc stripComments*(content: var string) =
  ## Removes C/C++ comments using precompiled regex
  const
    blockComment = re2"""/\*[^*]*\*+(?:[^/*][^*]*\*+)*/"""  # Handles /* ... */ (even multiline)
    lineComment  = re2"""//[^\n]*"""                        # Handles // until newline
    whitespaces  = re2"""\s{1,}"""                          # Handles all whitespaces (' ', '\t', '\n')
    ifndefBlock  = re2"""#ifndef.*?#endif.*?"""             # Handles #ifndef ... #endif blocks inline
  # Replace in a single pass (faster than two separate replaces)
  content = content.replace(blockComment, "" )  
  content = content.replace(lineComment,  "" )
  content = content.replace(whitespaces,  " ")
  content = content.replace(ifndefBlock,  "" )
  # This last must be called after stripping whitespaces, since it only works inline