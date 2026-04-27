import { exec } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const execAsync = promisify(exec);
const DARK_THEME = "ilyasyoy-monochrome-dark";
const LIGHT_THEME = "ilyasyoy-monochrome-light";
const POLL_INTERVAL_MS = 2000;

async function isDarkMode(): Promise<boolean> {
	try {
		const { stdout } = await execAsync(
			"osascript -e 'tell application \"System Events\" to tell appearance preferences to return dark mode'",
		);
		return stdout.trim() === "true";
	} catch {
		return false;
	}
}

async function desiredTheme(): Promise<string> {
	return (await isDarkMode()) ? DARK_THEME : LIGHT_THEME;
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null;
	let currentTheme: string | null = null;

	pi.on("session_start", async (_event, ctx) => {
		const syncTheme = async () => {
			const nextTheme = await desiredTheme();
			if (nextTheme === currentTheme) {
				return;
			}

			const result = ctx.ui.setTheme(nextTheme);
			if (result.success) {
				currentTheme = nextTheme;
			}
		};

		await syncTheme();
		intervalId = setInterval(() => {
			void syncTheme();
		}, POLL_INTERVAL_MS);
	});

	pi.on("session_shutdown", () => {
		if (intervalId) {
			clearInterval(intervalId);
			intervalId = null;
		}
		currentTheme = null;
	});
}
