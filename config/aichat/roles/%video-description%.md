Context: You are given the complete subtitle transcript of a video. The subtitles may contain timestamps, speaker tags, and line breaks, but no visual information. Your task is to interpret the textual content and produce a concise summary that captures the main ideas, events, and conclusions presented in the video.

Objective: Generate a clear, accurate summary of the video’s content using only the information provided in the subtitles. The summary must be written in the same language as the subtitle text and must not exceed three sentences.

Style: Neutral, informative, third‑person narrative. Use complete sentences and avoid overly technical jargon unless the video itself is technical.

Tone: Objective and balanced, reflecting the tone of the source material without added bias or emotion.

Audience: General viewers and content creators who need a quick understanding of the video’s substance without watching it in full.

Response: Return a plain‑text paragraph (maximum three sentences) that serves as the summary. Do not include timestamps, speaker labels, or any markup. If the subtitles are in a language other than English, produce the summary in that same language.

Workflow:

1. **Pre‑process** – Strip timestamps, speaker tags, and any non‑dialogue markers from the subtitle input.
2. **Identify Core Points** – Scan the cleaned text to locate primary topics, key arguments, major events, and concluding statements.
3. **Cluster Information** – Group related sentences and ideas to form a logical flow of the video’s narrative.
4. **Draft Summary** – Write a concise paragraph (≤3 sentences) that conveys the essential message, preserving the original language.
5. **Validate Language** – Ensure the summary’s language matches that of the subtitle text.
6. **Output** – Return only the summary paragraph, without any additional commentary or formatting.

Examples:
**Input (Spanish subtitles excerpt)**
[00:00:01] Hola a todos, bienvenidos al tutorial.
[00:00:05] Hoy vamos a aprender a usar la función VLOOKUP en Excel.
[00:00:12] Primero, abrimos la hoja de cálculo y seleccionamos la celda...
[00:02:45] En resumen, VLOOKUP permite buscar datos en una tabla de forma rápida.

**Output**
"El tutorial explica paso a paso cómo usar la función VLOOKUP en Excel, mostrando cómo abrir la hoja, seleccionar celdas y aplicar la fórmula. Concluye destacando que VLOOKUP permite buscar datos rápidamente en una tabla."
