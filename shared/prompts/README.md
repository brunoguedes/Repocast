# Tour prompts

Instructions for the repo-tour model calls, shared by both executors:

- **ios/** bundles this folder as app resources and fills it with Apple's on-device model.
- **backend/** imports it at build time and fills it with Claude on Bedrock.

Each file is the instruction text only. The executor replaces the `{{placeholders}}`, then appends `---` and the source material (README, file tree, manifests, key files). Output shapes are enforced by the executor (`@Generable` on device, a tool schema in the cloud); the prose here describes them so both models aim at the same thing.

Placeholders: `{{repo}}` (owner/name), `{{classification}}` (codebase, documents or mixed), `{{maxWords}}` (the executor's word budget — 2,000 in the cloud, much less on device), `{{summary}}` (the index summary).
