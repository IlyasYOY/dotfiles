require("agent-review").setup {
    runners = {
        opencode = {
            default_args = { "--command", "review" },
        },
    },
}
