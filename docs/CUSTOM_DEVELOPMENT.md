# VoiceInk Custom Development Guide

This repository is developed as a long-lived fork of the upstream project:

- Fork remote: `origin`
- Upstream remote: `upstream`
- Local customization branch: `codex/custom-init`

The goal is to keep custom features maintainable while still being able to merge important upstream updates from the official VoiceInk project.

## Local Dev App

For day-to-day local development, the customized app should be installed and tested as:

- app name: `VoiceInk Ultra`
- install path: `/Applications/VoiceInk Ultra.app`

Use the stable local dev build target:

```bash
cd /Users/geekmai/Documents/Code/VoiceInk
make devsigned
open "/Applications/VoiceInk Ultra.app"
```

Why this target exists:

- keeps install path stable
- keeps signing identity stable
- reduces repeated re-authorization for Accessibility and Screen Recording permissions

Do not use `make local` as the default install flow when testing permissions-sensitive features.

## Branching Rules

- `main` is reserved for syncing with upstream.
- Do not implement custom features directly on `main`.
- All customization work must happen on a `codex/*` branch.
- Create one focused branch per feature or milestone when the change is non-trivial.

Recommended naming:

- `codex/custom-init`
- `codex/feature-translation-mode`
- `codex/feature-voice-command-router`
- `codex/fix-alfred-integration`

## Upstream Sync Rules

When upstream publishes important updates:

1. Checkout `main`
2. Fetch upstream changes
3. Merge `upstream/main` into local `main`
4. Push updated `main` to `origin`
5. Merge updated `main` into the active customization branch

Reference commands:

```bash
cd /Users/geekmai/Documents/Code/VoiceInk
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

git checkout codex/custom-init
git merge main
```

## Customization Principles

- Prefer the smallest change that cleanly implements the feature.
- Prefer extension points, mode routing, and feature flags over invasive rewrites.
- Avoid changing unrelated upstream code during customization work.
- Keep upstream behavior intact unless the customization explicitly replaces it.
- If a feature is local-only or experimental, guard it behind a dedicated setting or mode.
- Preserve existing names, data models, and app flows where possible to reduce merge conflicts.

## Documentation Rules For Custom Features

Every custom feature must have a corresponding document under `docs/features/`.

Each feature document should describe:

- user problem
- expected trigger or entry point
- input and output behavior
- dependencies and integrations
- affected modules
- edge cases
- testing checklist
- merge risk with upstream

Suggested filenames:

- `docs/features/translation-mode.md`
- `docs/features/voice-command-actions.md`
- `docs/features/custom-actions.md`

## Change Scope Rules

- Product decisions go in feature docs before or alongside implementation.
- Code changes should follow the approved feature scope.
- If implementation reveals a larger architectural change, update the feature doc before expanding the code scope.

## Testing Rules

Before considering a customization ready:

- build the app successfully with `make devsigned`
- verify the feature manually from the actual shortcut flow
- confirm that the normal transcription flow still works
- confirm that the stable local dev app launches from `/Applications/VoiceInk Ultra.app`

## Current Customization Track

The current planned customizations are:

1. Translation mode
   Chinese speech in, polished English text out
2. Voice command mode
   Spoken command word in, action dispatch out
3. Custom action executors
   Alfred, Apple Shortcuts, and local script targets

## Practical Rule For This Fork

If a decision improves short-term speed but makes upstream merging significantly harder, prefer the design that keeps merge risk lower unless the customization cannot be delivered otherwise.
