import { complete, type Api, type AssistantMessage, type Model, type TextContent, type UserMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ModelRegistry, SessionEntry } from "@mariozechner/pi-coding-agent";
import { BorderedLoader } from "@mariozechner/pi-coding-agent";

const PLAN_MODEL_PROVIDER = "openai-codex";
const PLAN_MODEL_ID = "gpt-5.4-mini";

const SYSTEM_PROMPT = `You are a planning-to-execution converter.

Convert the assistant message into a clean first user message for a fresh coding session.

Requirements:
- Preserve the intended plan, scope, constraints, and acceptance checks.
- Rewrite planning language into direct actionable instructions for execution.
- Keep only information needed to execute the task in a new session.
- Preserve file paths, sequencing, caveats, and verification steps when present.
- Do not invent new requirements or change scope.
- If the source is not clearly a plan, still convert it into the best possible execution-ready request.
- Output only the final user message text.`;

function isAssistantEntry(entry: SessionEntry): entry is SessionEntry & { type: "message"; message: AssistantMessage } {
	return entry.type === "message" && entry.message.role === "assistant";
}

function getAssistantText(message: AssistantMessage): string {
	return message.content
		.filter((part): part is TextContent => part.type === "text")
		.map((part) => part.text)
		.join("\n")
		.trim();
}

function getLastAssistantPlan(branch: SessionEntry[]): { text: string; stopReason?: string } | null {
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (!isAssistantEntry(entry)) continue;

		const text = getAssistantText(entry.message);
		if (!text) continue;

		return {
			text,
			stopReason: entry.message.stopReason,
		};
	}

	return null;
}

async function selectPlanModel(currentModel: Model<Api> | undefined, modelRegistry: ModelRegistry): Promise<Model<Api> | null> {
	const preferred = modelRegistry.find(PLAN_MODEL_PROVIDER, PLAN_MODEL_ID);
	if (preferred) {
		const auth = await modelRegistry.getApiKeyAndHeaders(preferred);
		if (auth.ok) {
			return preferred;
		}
	}

	if (currentModel?.provider === PLAN_MODEL_PROVIDER && currentModel.id === PLAN_MODEL_ID) {
		const auth = await modelRegistry.getApiKeyAndHeaders(currentModel);
		if (auth.ok) {
			return currentModel;
		}
	}

	return null;
}

export default function executePlanExtension(pi: ExtensionAPI) {
	pi.registerCommand("execute-plan", {
		description: "Create a fresh session from the last assistant plan",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("execute-plan requires interactive mode", "error");
				return;
			}

			const mode = args.trim().toLowerCase();
			if (mode && mode !== "now" && mode !== "review") {
				ctx.ui.notify("Usage: /execute-plan [review|now]", "warning");
				return;
			}

			const shouldReview = mode !== "now";
			const lastAssistant = getLastAssistantPlan(ctx.sessionManager.getBranch());
			if (!lastAssistant) {
				ctx.ui.notify("No assistant message with text found in the current branch", "error");
				return;
			}

			if (lastAssistant.stopReason && lastAssistant.stopReason !== "stop") {
				ctx.ui.notify(`Last assistant message is incomplete (${lastAssistant.stopReason})`, "error");
				return;
			}

			const planModel = await selectPlanModel(ctx.model, ctx.modelRegistry);
			if (!planModel) {
				ctx.ui.notify(
					`Could not use ${PLAN_MODEL_PROVIDER}/${PLAN_MODEL_ID}. Make sure that model is available and authenticated.`,
					"error",
				);
				return;
			}

			const transformed = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(tui, theme, `Structuring plan with ${planModel.id}...`);
				loader.onAbort = () => done(null);

				const structurePlan = async () => {
					const auth = await ctx.modelRegistry.getApiKeyAndHeaders(planModel);
					if (!auth.ok) {
						throw new Error("Authentication failed for plan structuring model");
					}
					if (!auth.apiKey) {
						throw new Error("No API key available for plan structuring model");
					}

					const message: UserMessage = {
						role: "user",
						timestamp: Date.now(),
						content: [
							{
								type: "text",
								text: `Convert this assistant message into the first user message for a fresh execution session:\n\n${lastAssistant.text}`,
							},
						],
					};

					const response = await complete(
						planModel,
						{ systemPrompt: SYSTEM_PROMPT, messages: [message] },
						{ apiKey: auth.apiKey, headers: auth.headers, signal: loader.signal },
					);

					if (response.stopReason === "aborted") {
						return null;
					}

					return response.content
						.filter((part): part is TextContent => part.type === "text")
						.map((part) => part.text)
						.join("\n")
						.trim();
				};

				void structurePlan()
					.then(done)
					.catch((error) => {
						const message = error instanceof Error ? error.message : String(error);
						ctx.ui.notify(`Failed to structure plan: ${message}`, "error");
						done(null);
					});

				return loader;
			});

			if (transformed === null) {
				ctx.ui.notify("Cancelled", "info");
				return;
			}

			if (!transformed.trim()) {
				ctx.ui.notify("The structured plan was empty", "error");
				return;
			}

			const finalPrompt = shouldReview ? await ctx.ui.editor("Review execution prompt", transformed) : transformed;
			if (finalPrompt === undefined) {
				ctx.ui.notify("Cancelled", "info");
				return;
			}

			const trimmedPrompt = finalPrompt.trim();
			if (!trimmedPrompt) {
				ctx.ui.notify("Execution prompt is empty", "error");
				return;
			}

			const parentSession = ctx.sessionManager.getSessionFile();
			const result = await ctx.newSession({
				parentSession,
				withSession: async (replacementCtx) => {
					await replacementCtx.sendUserMessage(trimmedPrompt);
				},
			});

			if (result.cancelled) {
				ctx.ui.notify("New session cancelled", "info");
			}
		},
	});
}
