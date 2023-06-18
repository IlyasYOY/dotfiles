local methods = require "null-ls.methods"
local h = require "null-ls.helpers"
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin {
    name = "pmd cpd",
    meta = {
        url = "https://github.com/pmd/pmd",
        description = "CPD (copy and paste detector) finds duplicated code in C/C++, C#, Dart, Fortran, Gherkin, Go, Groovy, HTML, Java, JavaScript, JSP, Kotlin, Lua, Matlab, Modelica, Objective-C, Perl, PHP, PLSQL, Python, Ruby, Salesforce.com Apex and Visualforce, Scala, Swift, T-SQL and XML",
    },
    method = DIAGNOSTICS,
    filetypes = { "java" },
    generator_opts = {
        command = "pmd",
        args = {
            "cpd",
            "--dir",
            "$ROOT",
            "--format=vs",
            "--language=java",
        },
        diagnostics_format = "(#{s}) #{m}.",
        from_stderr = false,
        ignore_stderr = true,
        format = "line",
        check_exit_code = { 0, 4 },
        on_output = h.diagnostics.from_pattern(
            [[([^%(]+)%((%d+)%): (.+)]],
            { "filename", "row", "message" }
        ),
    },
    factory = h.generator_factory,
}
