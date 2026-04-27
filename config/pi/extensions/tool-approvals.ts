import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isAbsolute, relative, resolve } from "node:path";

const autoAllow = new Set(["read", "grep", "find", "ls", "ask_user"]);
const fileMutationTools = new Set(["edit", "write"]);

function formatInput(input: unknown): string {
  if (typeof input === "string") return input;

  try {
    return JSON.stringify(input, null, 2);
  } catch {
    return String(input);
  }
}

function isPathInsideCwd(cwd: string, targetPath: unknown): boolean {
  if (typeof targetPath !== "string" || targetPath.length === 0) return false;

  const absolutePath = resolve(cwd, targetPath);
  const relativePath = relative(cwd, absolutePath);

  return relativePath === "" || (!relativePath.startsWith("..") && !isAbsolute(relativePath));
}

export default function (pi: ExtensionAPI) {
  const sessionAllowedTools = new Set<string>();

  pi.on("tool_call", async (event, ctx) => {
    if (autoAllow.has(event.toolName) || sessionAllowedTools.has(event.toolName)) return;

    const path = (event.input as { path?: unknown }).path;

    if (fileMutationTools.has(event.toolName) && isPathInsideCwd(ctx.cwd, path)) {
      return;
    }

    const input = formatInput(event.input);

    if (!ctx.hasUI) {
      return {
        block: true,
        reason: `Tool '${event.toolName}' requires approval, but no interactive UI is available.`,
      };
    }

    const displayInput = input.length > 4000 ? `${input.slice(0, 4000)}\n\n...truncated...` : input;
    const choice = await ctx.ui.select(
      `Approve tool call: ${event.toolName}\n\n${displayInput}`,
      ["Allow once", "Allow for rest of session", "Deny"],
    );

    if (choice === "Allow for rest of session") {
      sessionAllowedTools.add(event.toolName);
      ctx.ui.notify(`Auto-allowing '${event.toolName}' for the rest of this session.`, "info");
      return;
    }

    if (choice !== "Allow once") {
      ctx.abort();
      return {
        block: true,
        reason: choice === undefined
          ? `User cancelled approval for '${event.toolName}'.`
          : `User denied '${event.toolName}'.`,
      };
    }
  });
}
