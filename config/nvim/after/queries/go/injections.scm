; extends

((call_expression
  function:
    (selector_expression
      field: (field_identifier) @_method)
  arguments:
    (argument_list
      .
      (interpreted_string_literal) @injection.content))
  (#any-of? @_method "Errorf")
  (#set! injection.language "printf"))

