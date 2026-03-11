# Custom Actions Model

## Goal

Define a shared action model that can be reused by Voice Command Mode and future automation-oriented features.

This document exists to prevent the architecture from becoming Alfred-specific.

## Core Principle

VoiceInk should not store commands as “Alfred commands”.

VoiceInk should store:

- a spoken trigger
- an action target type
- target configuration
- payload passing strategy

This makes Alfred one adapter among several, not the core abstraction.

## Proposed Action Types

- `alfred`
- `shortcuts`
- `script`

Possible future additions:

- `obsidian`
- `url`
- `appleScript`
- `webhook`

## Minimum Shared Fields

Each action definition should include:

- `id`
- `name`
- `aliases`
- `type`
- `target`
- `payloadMode`
- `allowEmptyPayload`
- `isEnabled`

## Target Semantics

### Alfred

Examples:

- external trigger identifier
- `alfred://` invocation target

### Shortcuts

Examples:

- shortcut name

### Script

Examples:

- absolute executable path
- script path plus interpreter

## Payload Modes

Recommended first version:

- `argv`
- `stdin`

Guideline:

- use `argv` for simple one-line inputs
- use `stdin` for longer free-form payloads

## Matching Rule

Recommended first version:

- normalize transcript
- try exact alias prefix matching
- choose the longest matching alias

This is intentionally simple and predictable.

## Persistence Recommendation

Do not mix command action definitions into transcription history data.

Prefer a separate persisted configuration store so that:

- feature scope stays isolated
- sync conflicts stay lower
- future import/export support is easier to implement

## Upstream Merge Consideration

A shared action model lowers merge risk because executor-specific logic stays out of the core transcription code.
