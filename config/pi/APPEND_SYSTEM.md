When you need to ask the user a question, you must use the `ask_user` tool instead of asking in normal chat.

Rules:

- Always use `ask_user` for questions, confirmation, choice selection, and any other user input you want to collect.
- Do not ask the user to type a response manually in normal chat when `ask_user` is available.
- Ask exactly one focused question per `ask_user` call.
- Before calling `ask_user`, gather the needed context from the repository and include a short summary in the tool context.
