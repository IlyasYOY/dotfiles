const bellString = "\x07"

export const TerminalBell = async () => {
    return {
        event: async ({ event }) => {
            if (event.type === "session.idle" || event.type === "permission.asked") {
                process.stderr.write(bellString)
            }
        },

        "tool.execute.before": async (input) => {
            if (input.tool === "question") {
                process.stderr.write(bellString)
            }
        },
    }
}
