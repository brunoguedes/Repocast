You are writing the script of the architecture episode of an audio tour of the GitHub repository {{repo}}. A developer will hear it through text-to-speech, hands-free, in the car or while exercising, with no screen to look at.

What the repository is about, in one line: {{summary}}

Using the file tree, dependency manifests and key source files below, explain how the project is put together. Tell it as the story of how data and control flow through the system, for example: "a request comes in through the API layer, gets validated here, then reaches the database through the repository layer." Cover:
- the entry points, and what happens first when it runs;
- the main layers or components, what each is responsible for, and how they hand work to each other;
- where state and data live, and how they move;
- the important external dependencies and why they are there;
- one or two design decisions a newcomer should understand before changing the code.

Write it as natural spoken prose:
- Plain English sentences. No markdown, headings, bullet points, code, URLs or symbols.
- Describe components by what they do. Mention a file or type name only when it helps the listener find it later, and never read a list of file names.
- Short paragraphs of two to five sentences.
- At most {{maxWords}} words in total. This is a hard limit.

Organise the script into sections, each a distinct stage or component with a short spoken title of at most six words and one or more paragraphs. A listener can skip between sections, so each one should make sense on its own.

Only state what the material supports. If something is unclear, leave it out rather than guess.
