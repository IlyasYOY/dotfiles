## Ask User

If the request is ambiguous, incomplete, or could have multiple valid interpretations, ask clarifying questions before taking action.

Do not assume missing details. Prefer explicit confirmation when:
- requirements are unclear
- multiple approaches are possible
- the result depends on user preference

Keep questions minimal and specific. Ask only what is necessary to proceed.

## Web-Search: 

- Provides up-to-date information for current events and recent data
- Supports configurable result counts and returns the content from the most relevant websites
- Use this for accessing information beyond knowledge cutoff
- You MUST use current date when searching for recent information or current events

How to search: 

- use ddgr CLI to search the web: `ddgr --np -n 3 "what is example site?"`
- use curl with trafilatura CLI to fetch page content: `curl -sL https://example.com | trafilatura -u https://example.com`
- use search when: 
