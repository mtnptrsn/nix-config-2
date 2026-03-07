# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: sync-skills
  description: Sync skills from another repo (e.g. a company plugin) into this repo, adapted for private use. Use when the user wants to import, sync, or copy skills from another project.
  ---

  ## Steps

  ### 1. Get the source repo path

  Use AskUserQuestion to ask for the path to the repo to sync skills from.

  ### 2. Discover skills in both repos

  The source repo may be a Claude plugin (skills at `skills/*/SKILL.md`) or a regular project (skills at `.claude/skills/*/SKILL.md`). Check both locations.

  In this repo, skills are defined as Nix files in `home/modules/claude/skills/`. Each `.nix` file is a multiline Nix string containing the SKILL.md content. Read each `.nix` file there to get the current skill contents.

  For each skill found in both repos, extract the name from the frontmatter.

  ### 3. Compare and present differences

  For each skill in the source repo, determine its "adapted name" by stripping any company-specific prefix (the part before the first hyphen if it looks like a prefix, e.g. "acme-commit" becomes "commit"). Then check if a skill with that adapted name already exists locally:

  - **New** - no local skill with the adapted name exists
  - **Changed** - a local skill exists but the source content (after adaptation) differs
  - **Unchanged** - a local skill exists and content is essentially the same

  Skip unchanged skills. Present the remaining skills to the user using AskUserQuestion with multiSelect, showing the status (new/changed) next to each skill name.

  If there are no new or changed skills, tell the user everything is in sync.

  ### 4. Copy and adapt selected skills

  For each selected skill:

  1. Read the full SKILL.md from the source repo
  2. Adapt it for private/personal use:
     - Remove any company-specific prefixes from the skill name
     - Remove any company-specific references from the description
     - Remove company-specific ID patterns (e.g. ticket ID references, branch name ticket extraction)
     - Keep the core workflow and logic intact - only strip company branding
  3. Write the adapted content as a new `.nix` file in `home/modules/claude/skills/<adapted-name>.nix`, following the same format as the existing skill files (a Nix multiline string with a comment header)
  4. Register the new skill in `home/modules/claude/default.nix` by adding it to the built-in skills attrset, following the existing pattern

  ### 5. Show result

  Summarize what was synced: list the skills copied, where they were written, and any adaptations made.
''
