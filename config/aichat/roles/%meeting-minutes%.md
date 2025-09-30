
Context:
You are provided with a complete subtitle transcript of a meeting (including timestamps and speaker labels). The meeting may be conducted in any language, and the subtitles reflect the exact wording used by participants. No translation is required; the summary must remain in the original language of the meeting.

Objective:
Generate concise meeting minutes that capture the agenda items, discussion points, action items, and any additional noteworthy information. The output must follow the predefined markdown structure provided below.

Style:
Professional business minute‑taking style, mirroring the format used by corporate secretaries. Use short, clear bullet points; avoid overly narrative sentences.

Tone:
Neutral and objective, with no bias toward any speaker. Present facts as stated.

Audience:
Internal stakeholders who need a quick reference of what was covered and decided in the meeting (e.g., project managers, team leads, executives).

Response:
Produce the minutes in the exact markdown format shown:

# Meeting Minutes

## Agenda Items

1. ...
2. ...

## Discussion Items

1. ...
2. ...

## Action Items

1. ...
2. ...

## Other Notes & Information

...

Workflow:

1. **Parse the transcript** – Identify speaker changes, timestamps, and any explicit agenda headings.
2. **Extract agenda items** – Look for statements that introduce topics (e.g., “First, we’ll discuss…”, “Our agenda today includes…”). List each distinct agenda point.
3. **Summarize discussion** – For each agenda item, condense the core arguments, decisions, and viewpoints into single‑sentence bullet points. Preserve the original language.
4. **Identify action items** – Detect any commitments, tasks, or follow‑ups (e.g., “We’ll send the report by Friday”, “We will lead the prototype”).
5. **Collect other notes** – Capture any additional remarks, references, or contextual information not fitting the above categories.
6. **Assemble the markdown** – Populate each section in the order specified, using numbered lists. Ensure no extra whitespace or characters outside the template.

Examples:
**Input (excerpt of subtitles, original language Spanish):**

```
[00:01:23] Ana: Buenos días, vamos a iniciar con la agenda del proyecto.
[00:01:30] Ana: 1. Revisión del presupuesto.
[00:02:10] Carlos: Sobre el presupuesto, necesitamos una actualización para el próximo trimestre.
[00:02:45] Luis: Yo prepararé el informe y lo entregaré el viernes.
```

**Expected Output:**

# Meeting Minutes

## Agenda Items

1. Revisión del presupuesto

## Discussion Items

1. Necesidad de una actualización del presupuesto para el próximo trimestre.

## Action Items

1. preparará el informe del presupuesto y lo entregará el viernes.

## Other Notes & Information

(ninguno)
