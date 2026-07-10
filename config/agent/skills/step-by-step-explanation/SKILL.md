---
name: step-by-step-explanation
description: >
  Code immersion: walks the user through how a project, component, or feature
  works, step by step. Use when the user wants to understand how code works or
  asks for a walkthrough.
---

# Step-by-Step Explanation

Immersion — progressive deepening into code: from the big picture down to
details and back. Every transition between steps goes through the `question`
tool. All explanations include code references (`file:line`).

## 1. Clarify the request

If the request doesn't specify which code and which aspect — gather the
missing details through the `question` tool in a single round: project,
file, or component, and what exactly interests the user (data flow,
architecture, a specific function, lifecycle).

Completion: the request is specific — the code and the aspect are known.

## 2. Choose the immersion format

Ask through the `question` tool:

- **Overview → steps → recap** (recommended) — big picture, then immersion,
  then an enriched recap highlighting what was unclear before.
- **Steps only** — straight into the details.
- **Overview → steps** — big picture, then immersion.
- **Steps → recap** — immersion, then an enriched recap.

Completion: the user has chosen the immersion path.

## 3. Analyze the code

Explore the codebase: find entry points, key functions, data flows,
dependencies.

Completion: all relevant code paths, their connections, and dependencies
are identified.

## 4. Propose an immersion plan

Form a step-by-step plan: which layers or components to walk through, in
order. Show the plan and ask through the `question` tool — proceed or
adjust?

Completion: the user confirmed the plan or provided adjustments that are
incorporated.

## 5. Big picture (if requested)

Give a top-level description: what the code does, key components, how they
connect. Stay high-level — this is the map before the dive.

Completion: the big picture is given — components and connections are named.

## 6. Step-by-step immersion

For each step in the plan:

1. Explain one layer or component.
2. Ask through the `question` tool: move to the next step, or are there
   questions about the current one?
3. If there are questions — answer them, then repeat the transition.

Completion: every step in the plan is explained and confirmed by the user.

## 7. Recap (if requested)

Return to the top-level description, enriched with insights from the
immersion. Highlight what was unclear before the dive and is now clear.

Completion: the recap is given — it covers the original question and
highlights what was clarified.

## 8. Wrap-up

Ask through the `question` tool what's next:

- **All clear** — immersion complete.
- **Need to dig deeper** — return to the details.
- **Run grilling** — if the `grilling` skill is available, offer a deep
  interrogation to stress-test the user's understanding.
- **Save a note** — offer to save a summary with code references for future
  reference without AI. If agreed — compile the summary and offer to save it
  in kb-store or as a local file.

Completion: the user chose next steps or confirmed completion.
