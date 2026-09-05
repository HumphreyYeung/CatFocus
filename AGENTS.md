# Repository Guidelines

This file gives AI agents project-specific operating instructions.
Prefer existing project conventions over generic advice.

## Mission

Help maintain and improve this repository with small, reviewable, high-quality changes.

Read the relevant files before editing. Keep changes scoped to the task. Do not perform unrelated refactors.

For independent product projects, optimize for:

- Fast iteration
- Clear user value
- Simple architecture
- Polished UX
- Maintainable code
- Small reversible changes

## Autonomy

You may:

- Read and modify source, documentation, tests, prompts, skills, and local tooling related to the task
- Run local checks, tests, builds, linters, formatters, and smoke tests
- Add focused tests or docs when they reduce risk
- Use available local tools, MCP services, browser automation, Figma, Mobbin, Feishu/Lark CLI, GitHub, and simulator tooling when useful

Ask before:

- Committing
- Pushing
- Pulling or rebasing
- Changing CI/CD
- Adding major dependencies
- Performing broad refactors
- Deleting files or tests
- Touching secrets, credentials, environment files, or production configuration

Never:

- Hardcode tokens, API keys, passwords, or private credentials
- Expose secrets in chat, logs, commits, or generated files
- Overwrite user changes
- Modify `.env*`, `LICENSE`, or sensitive config unless explicitly requested

## Project Shape

Describe this repository here in 5-10 lines.

Example:

- `App/`: main application code
- `Tests/`: unit and integration tests
- `docs/`: product, architecture, and implementation notes
- `scripts/`: local automation and validation scripts
- `tools/`: project-specific utilities and external integrations
- `assets/`: images, animation files, fixtures, and other static assets

Keep this section short. Put long directory maps in `README.md` or dedicated docs.

## Common Commands

List only commands that actually exist in this repo.

```bash
make help
make lint
make test
make build
```

For iOS projects, replace or extend with the real project commands:

```bash
xcodebuild -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Validation Rules

Run the smallest relevant check after changes.

- Documentation changes: run Markdown lint or relevant docs checks
- Script/tool changes: run the changed tool or its tests
- Frontend changes: run lint/build and inspect the UI in a browser or screenshot when practical
- iOS changes: build the app and use the simulator for meaningful UI or behavior changes when feasible
- AI feature changes: test prompts, failure states, and privacy-sensitive flows
- Broad changes: run the full local test or build command

If a command cannot be run, explain why and describe the remaining risk.

## Coding Rules

Follow existing style, naming, architecture, and folder boundaries.

Prefer:

- Simple explicit code
- Small functions
- Clear names
- Minimal dependencies
- Tests for behavior changes
- Existing local patterns over new abstractions

Avoid:

- Clever abstractions
- Large speculative rewrites
- Formatting churn
- Moving files without need
- Adding dependencies for small problems

Fix root causes where practical. If a quick workaround is chosen, explain the tradeoff.

## Product And UX Rules

Build the actual usable product experience, not a marketing page, unless explicitly asked.

Prioritize:

- Clear user flows
- Empty, loading, and error states
- Responsive layout
- Accessibility
- Polished typography and spacing
- Native platform conventions
- Useful micro-interactions

When requirements are unclear, make reasonable assumptions and proceed. Call out tradeoffs that affect UX, scope, cost, privacy, security, or long-term maintenance.

## iOS Notes

Use this section when the repository is an iOS app.

Prefer SwiftUI unless the project already uses UIKit or a different architecture.

Pay attention to:

- Navigation structure
- State ownership
- Loading, empty, and error states
- Accessibility
- Dynamic Type
- Animation performance
- Simulator verification

Use existing Xcode schemes, bundle IDs, project settings, and architecture. Do not introduce a new app architecture unless the task clearly requires it.

## AI Feature Notes

Use this section only when the project includes LLM or AI-powered functionality.

Do not add AI features unless they directly serve the product goal.

For AI changes, consider:

- User value before model choice
- Privacy and data handling
- Cost and latency
- Prompt quality
- Evaluation or regression examples
- Failure states
- Non-AI fallback behavior when appropriate

Never log private user input, tokens, API keys, or model credentials.

Prefer official provider docs for current model, SDK, pricing, and API behavior.

## Motion And Rive Notes

Use this section when the project uses Rive or similar motion tooling.

Treat animation as product behavior, not decoration.

Prefer:

- Clear state machine names
- Understandable bindings
- Simple triggers
- Documented UI-state-to-animation-state mapping when not obvious
- Simulator or device checks for performance-sensitive motion

Do not introduce Rive unless the product benefits from expressive motion or the project already uses it.

## External Tools

Use external tools when they improve speed or quality.

Examples:

- Figma for design context and design-to-code
- Mobbin for mobile product references
- Feishu/Lark CLI for docs, tasks, messages, calendars, or team workflows
- GitHub for PRs, issues, and CI context
- Browser automation for local web app testing
- iOS simulator tooling for app verification

Keep tool usage scoped to the task. Do not expose private credentials or private workspace data.

## Documentation Rules

When behavior, commands, configuration, user flows, or directory structure changes, update the relevant docs.

Do not guess uncertain facts. Mark them as TODO or ask.

Keep project-level `AGENTS.md` concise. Move long explanations, full directory maps, and background material to `README.md` or `docs/`.

## Git Rules

Do not run `git pull`, `git rebase`, `git commit`, or `git push` unless explicitly asked.

Before committing, summarize:

- Changed files
- Purpose
- Validation run
- Remaining risk

Use concise Conventional Commit style when asked to commit:

```text
feat|fix|docs|chore|refactor|test: scope - summary
```

## Project-Specific Notes

Add repo-specific rules here:

- Architecture constraints
- Domain concepts
- Important files
- Known pitfalls
- External services
- Deployment notes
- Required local environment
- Release checklist

