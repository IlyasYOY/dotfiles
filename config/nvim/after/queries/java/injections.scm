; extends

; support r2dbc 

(method_invocation
  object: (identifier) @_object 
  name: (identifier) @_method 
  arguments: (argument_list
               (string_literal
                 (multiline_string_fragment) @injection.content))

  (#any-of? @_object 
   "databaseClient"
   "statement"
   "connection"
   "conn"
   "client")
  (#any-of? @_method 
   "sql"
   "executeQuery"
   "createStatement"
   "execute")

  (#set! injection.language "sql"))

(method_invocation
  object: (identifier) @_object 
  name: (identifier) @_method 
  arguments: (argument_list
               (string_literal
                 (string_fragment) @injection.content))

  (#any-of? @_object 
   "databaseClient"
   "statement"
   "connection"
   "conn"
   "client")
  (#any-of? @_method 
   "sql"
   "executeQuery"
   "createStatement"
   "execute")

  (#set! injection.language "sql"))

