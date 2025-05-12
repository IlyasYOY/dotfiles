; extends

( 
  (raw_string_literal
                 (raw_string_literal_content) @injection.content)
  (comment) @_comment

  (#any-of? @_comment 
   "// sql"
   "// SQL"
   "sql"
   "SQL"
   "//SQL"
   "//sql")

  (#set! injection.language "sql"))
