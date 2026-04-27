import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

const autoAllow = new Set(["read", "grep", "find", "ls", "ask_user"]);
const fileMutationTools = new Set(["edit", "write"]);
const globalApprovalsPath = join(homedir(), ".pi", "agent", "tool-approvals.json");

interface PersistedApprovals {
  bashCommands?: string[];
}

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

function loadGlobalBashApprovals(): Set<string> {
  try {
    if (!existsSync(globalApprovalsPath)) return new Set();

    const data = JSON.parse(readFileSync(globalApprovalsPath, "utf8")) as PersistedApprovals;
    return new Set(data.bashCommands?.filter((command) => typeof command === "string") ?? []);
  } catch {
    return new Set();
  }
}

function saveGlobalBashApprovals(commands: Set<string>) {
  const data: PersistedApprovals = { bashCommands: Array.from(commands).sort() };
  mkdirSync(dirname(globalApprovalsPath), { recursive: true });
  writeFileSync(globalApprovalsPath, `${JSON.stringify(data, null, 2)}\n`);
}

function shellTokens(command: string): string[] {
  const tokens: string[] = [];
  let token = "";
  let quote: "'" | '"' | undefined;
  let escaped = false;

  for (const char of command) {
    if (escaped) {
      token += char;
      escaped = false;
      continue;
    }

    if (char === "\\" && quote !== "'") {
      escaped = true;
      continue;
    }

    if (quote) {
      if (char === quote) quote = undefined;
      else token += char;
      continue;
    }

    if (char === "'" || char === '"') {
      quote = char;
      continue;
    }

    if (/\s/.test(char)) {
      if (token) {
        tokens.push(token);
        token = "";
      }
      if (char === "\n") tokens.push(";");
      continue;
    }

    if ([";", "|", "&", "(", ")"].includes(char)) {
      if (token) {
        tokens.push(token);
        token = "";
      }
      tokens.push(char);
      continue;
    }

    token += char;
  }

  if (token) tokens.push(token);
  return tokens;
}

function hasComplexShellExpansion(command: string): boolean {
  return command.includes("$(") || command.includes("`");
}

function extractBashCommandNames(command: string): string[] {
  const names: string[] = [];
  const seen = new Set<string>();
  let expectingCommand = true;
  let skippingWrapperOptions = false;

  for (const token of shellTokens(command)) {
    if ([";", "|", "&", "(", ")"].includes(token)) {
      expectingCommand = true;
      skippingWrapperOptions = false;
      continue;
    }

    if (!expectingCommand) continue;

    if (/^[A-Za-z_][A-Za-z0-9_]*=.*/.test(token) || /^[0-9]*[<>]/.test(token)) continue;

    if (["command", "builtin", "exec", "env", "noglob", "time", "sudo"].includes(token)) {
      skippingWrapperOptions = true;
      continue;
    }

    if (skippingWrapperOptions && token.startsWith("-")) continue;

    const name = token.includes("/") ? token.slice(token.lastIndexOf("/") + 1) : token;
    if (name && !seen.has(name)) {
      seen.add(name);
      names.push(name);
    }

    expectingCommand = false;
    skippingWrapperOptions = false;
  }

  return names;
}

export default function (pi: ExtensionAPI) {
  const sessionAllowedTools = new Set<string>();
  const sessionAllowedBashCommands = new Set<string>();
  const globalAllowedBashCommands = loadGlobalBashApprovals();

  pi.on("tool_call", async (event, ctx) => {
    if (autoAllow.has(event.toolName) || sessionAllowedTools.has(event.toolName)) return;

    const path = (event.input as { path?: unknown }).path;

    if (fileMutationTools.has(event.toolName) && isPathInsideCwd(ctx.cwd, path)) {
      return;
    }

    const bashCommand = event.toolName === "bash" ? (event.input as { command?: unknown }).command : undefined;
    const bashCommandNames = typeof bashCommand === "string" ? extractBashCommandNames(bashCommand) : [];
    const unapprovedBashCommandNames = bashCommandNames.filter(
      (command) => !sessionAllowedBashCommands.has(command) && !globalAllowedBashCommands.has(command),
    );

    if (
      event.toolName === "bash"
      && bashCommandNames.length > 0
      && unapprovedBashCommandNames.length === 0
      && typeof bashCommand === "string"
      && !hasComplexShellExpansion(bashCommand)
    ) {
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
    const choices = ["Allow once"];

    if (event.toolName === "bash" && unapprovedBashCommandNames.length > 0) {
      choices.push("Allow command name(s) for rest of session", "Allow command name(s) globally");
    }

    choices.push("Allow tool for rest of session", "Deny");

    const commandSummary = bashCommandNames.length > 0 ? `\n\nDetected bash command name(s): ${bashCommandNames.join(", ")}` : "";
    const choice = await ctx.ui.select(
      `Approve tool call: ${event.toolName}${commandSummary}\n\n${displayInput}`,
      choices,
    );

    if (choice === "Allow command name(s) for rest of session") {
      for (const command of unapprovedBashCommandNames) sessionAllowedBashCommands.add(command);
      ctx.ui.notify(
        `Auto-allowing bash command name(s) for this session: ${unapprovedBashCommandNames.join(", ")}.`,
        "info",
      );
      return;
    }

    if (choice === "Allow command name(s) globally") {
      for (const command of unapprovedBashCommandNames) globalAllowedBashCommands.add(command);
      saveGlobalBashApprovals(globalAllowedBashCommands);
      ctx.ui.notify(
        `Auto-allowing bash command name(s) globally: ${unapprovedBashCommandNames.join(", ")}.`,
        "info",
      );
      return;
    }

    if (choice === "Allow tool for rest of session") {
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
