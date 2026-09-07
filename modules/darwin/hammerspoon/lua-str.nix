# Lua strings are byte strings, so UTF-8 passes through untouched; only the
# delimiters and the control characters need escaping.
s:
''"'' + builtins.replaceStrings [ "\\" "\"" "\n" "\r" "\t" ] [ "\\\\" "\\\"" "\\n" "\\r" "\\t" ] s + ''"''
