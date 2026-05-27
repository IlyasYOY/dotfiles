require("ilyasyoy.functions.toggle_test").setup {
    command = "JavaToggleTest",
    rules = {
        {
            detect = "/main/java/",
            transform = function(cwf)
                cwf = string.gsub(cwf, "/main/java/", "/test/java/")
                cwf = string.gsub(cwf, "(%w+)%.java$", "%1Test.java")
                return cwf
            end,
        },
        {
            detect = "/test/java/",
            transform = function(cwf)
                cwf = string.gsub(cwf, "/test/java/", "/main/java/")
                cwf = string.gsub(cwf, "(%w+)Test%.java$", "%1.java")
                return cwf
            end,
        },
    },
}
