; extends

; support liquibase

(element
  (STag
    (Name) @_tag )
  (content) @injection.content

  (#eq? @_tag "sql")
  (#set! injection.combined)
  (#set! injection.include-children)
  (#set! injection.language "sql"))

(element
  (STag
    (Name) @_tag )
  (content) @injection.content

  (#eq? @_tag "sqlCheck")
  (#set! injection.combined)
  (#set! injection.include-children)
  (#set! injection.language "sql"))

(element 
  (EmptyElemTag
    (Name) @_name
    (Attribute 
      (Name) @_attribute_name
      (AttValue) @injection.content)) 

  (#eq? @_name "column")
  (#eq? @_attribute_name "valueComputed")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.combined)
  (#set! injection.include-children)
  (#set! injection.language "sql"))
