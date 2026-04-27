import { AuthStorage, type ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface CodexUsageData {
  daily: number;
  weekly: number;
  dailyResetsIn?: string;
  weeklyResetsIn?: string;
}

const CODEX_PROVIDER = "openai-codex";
const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const REQUEST_TIMEOUT_MS = 12_000;

function clampPercent(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(100, Math.round(value)));
}

function readPercent(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  if (value >= 0 && value <= 1 && !Number.isInteger(value)) return value * 100;
  if (value >= 0 && value <= 100) return value;
  return 0;
}

function formatDuration(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) return "now";

  const days = Math.floor(seconds / 86_400);
  const hours = Math.floor((seconds % 86_400) / 3_600);
  const minutes = Math.floor((seconds % 3_600) / 60);

  if (days > 0 && hours > 0) return `${days}d ${hours}h`;
  if (days > 0) return `${days}d`;
  if (hours > 0 && minutes > 0) return `${hours}h ${minutes}m`;
  if (hours > 0) return `${hours}h`;
  if (minutes > 0) return `${minutes}m`;
  return "<1m";
}

async function fetchCodexUsage(token: string): Promise<CodexUsageData> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(CODEX_USAGE_URL, {
      headers: { Authorization: `Bearer ${token}` },
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Codex usage request failed with HTTP ${response.status}`);
    }

    const data = await response.json();
    const primary = data?.rate_limit?.primary_window;
    const secondary = data?.rate_limit?.secondary_window;

    return {
      daily: readPercent(primary?.used_percent),
      weekly: readPercent(secondary?.used_percent),
      dailyResetsIn:
        typeof primary?.reset_after_seconds === "number"
          ? formatDuration(primary.reset_after_seconds)
          : undefined,
      weeklyResetsIn:
        typeof secondary?.reset_after_seconds === "number"
          ? formatDuration(secondary.reset_after_seconds)
          : undefined,
    };
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error("Codex usage request timed out");
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

function formatUsage(usage: CodexUsageData): string {
  const daily = clampPercent(usage.daily);
  const weekly = clampPercent(usage.weekly);
  const dailyReset = usage.dailyResetsIn ? `, resets in ${usage.dailyResetsIn}` : "";
  const weeklyReset = usage.weeklyResetsIn
    ? `, resets in ${usage.weeklyResetsIn}`
    : "";

  return [
    "Codex usage",
    `Daily:  ${daily}%${dailyReset}`,
    `Weekly: ${weekly}%${weeklyReset}`,
  ].join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("usage", {
    description: "Show Codex daily and weekly usage limits",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      const provider = ctx.model?.provider;
      if (provider !== CODEX_PROVIDER) {
        ctx.ui.notify(
          `/usage is Codex-only. Current provider: ${provider ?? "unknown"}`,
          "warning",
        );
        return;
      }

      const auth = AuthStorage.create();
      const token = await auth.getApiKey(CODEX_PROVIDER);

      if (!token) {
        ctx.ui.notify("No Codex credentials found. Run /login.", "warning");
        return;
      }

      try {
        const usage = await fetchCodexUsage(token);
        ctx.ui.notify(formatUsage(usage), "info");
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Failed to fetch Codex usage: ${message}`, "error");
      }
    },
  });
}
