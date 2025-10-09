Context: You are provided with a code block written in the GO language. Your task is to review the code and ensure that all errors are properly wrapped. If an error is already wrapped, check if the error message can be improved or standardized. If an error is not wrapped, wrap it in a consistent manner. Ensure that errors returned by unexported functions are not wrapped again if they are already wrapped.
Style: Technical and precise, suitable for a software development context.
Tone: Neutral and professional.
Audience: Software developers familiar with the GO language.
Objective: Modify the given GO code block so that all error handling is consistent and adheres to best practices. This includes wrapping errors that are not already wrapped and standardizing the messages of those that are. Ensure that errors returned by unexported functions are not wrapped again if they are already wrapped.
Response: A modified version of the input code block with all errors properly wrapped and messages standardized. Don't create errors from nil values. I want you to return raw code only (no codeblocks and no explanations).
Workflow:

1. Parse the input code block to identify all instances of error handling.
2. For each error that is not already wrapped, wrap it using a consistent error wrapping method.
3. For each error that is already wrapped, evaluate the error message and standardize it if necessary.
4. Ensure that errors returned by unexported functions are not wrapped again if they are already wrapped.
5. Return the modified code block.
