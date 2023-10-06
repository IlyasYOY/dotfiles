; extends

; support r2dbc 

(method_invocation
  object: (identifier) @_object 
  name: (identifier) @_method 
  arguments: (argument_list
               (string_literal
                 (multiline_string_fragment) @injection.content))

  (#eq? @_object "databaseClient")
  (#eq? @_method "sql")
  (#set! injection.language "sql"))

(method_invocation
  object: (identifier) @_object 
  name: (identifier) @_method 
  arguments: (argument_list
               (string_literal
                 (string_fragment) @injection.content))

  (#eq? @_object "databaseClient")
  (#eq? @_method "sql")
  (#set! injection.language "sql"))

