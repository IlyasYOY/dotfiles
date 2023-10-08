; extends

; support cursor

(call 
 function: (attribute
             object: (identifier) @_object
             attribute: (identifier) @_attribute)
 arguments: (argument_list  
              (string 
                (string_content) @injection.content))
  (#eq? @_object "cur")
  (#eq? @_attribute "execute")
  (#set! injection.language "sql"))
