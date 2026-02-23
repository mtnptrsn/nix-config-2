---
name: create-pr
description: Create a pull request with a well-crafted title and description. Use when the user asks to create, draft, or prepare a pull request.
---

## Context

- Current branch: !`git branch --show-current`
- Commits since base branch: !`git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline`
- Uncommitted changes: !`git status --short`

## Steps

### 1. Gather context

Run these in parallel:

- Get the diff against the base branch (typically `main` or `master`) using `git diff <base>...HEAD`
- Get the commit log since diverging from the base branch using `git log <base>..HEAD --oneline`
- Check if there are uncommitted changes via `git status`

### 2. Determine the FINCH ID

Extract the FINCH ID from the branch name (look for a pattern like `FINCH-1234`, `finch-1234`, or just a number that likely represents a ticket ID).

If no ID can be found in the branch name, ask the user for the FINCH ticket ID before proceeding.

### 3. Build the PR title

Format: `FINCH-{id}: {concise title}`

The title should be:

- Short and descriptive (under 72 characters total)
- Based on the branch name, commits, and diff - pick the phrasing that best summarizes the overall change
- Written in imperative mood (e.g. "Add", "Fix", "Update", "Remove")

### 4. Build the PR description

Use this structure:

```
## Background

{1-3 sentences explaining why this PR exists. What problem does it solve? What's the intent? Mention any limitations or trade-offs the reviewer should know about. Infer this from the commits and diff.}

## Changes

{Bullet point list of the meaningful changes. Group related changes together. Add a brief explanation for non-obvious changes. Don't list every single file - focus on what matters to a reviewer.}

## How to test

{If testing steps can be reasonably inferred from the changes (e.g. "run the test suite", "visit /settings and toggle X"), include them. Otherwise, write "TODO" so the author can fill this in.}
```

### 5. Tone and style

- Keep language normal - not too formal, not too casual
- Be concise but informative
- Prioritize making the reviewer's life easier
- Don't use em dashes
- Don't use emojis

### 6. Output

Do NOT push, create the PR, or run any git commands that modify state. Just output the final title and description as a single copyable markdown block that the user can paste into their PR themselves.
