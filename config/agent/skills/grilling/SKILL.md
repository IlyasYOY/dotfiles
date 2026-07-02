---
name: grilling
description: Explicit plan and design stress-test interview.
disable-model-invocation: true
---

Grill the plan: interview the user relentlessly until the design is decision
complete.

## Workflow

1. Restate the plan, goal, and visible uncertainty in one short paragraph.
2. Find the highest-impact unresolved decision.
3. If codebase exploration can answer it, inspect the code instead of asking.
4. Ask exactly one question, give the recommended answer, and wait.
5. Repeat until each branch that could change implementation is resolved.

Completion criterion: the remaining plan contains no implementation decision
that depends on unstated user intent.

## Question Rules

- One question at a time. Multiple questions are bewildering.
- Ask about tradeoffs, constraints, success criteria, interfaces, data flow,
  edge cases, rollout, or verification only when the answer changes the plan.
- Do not ask for facts that repository inspection can answer.
- Prefer concrete options, but do not force options when the user must supply
  missing domain context.
