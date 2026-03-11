# Voice Command Mode And Custom Actions

## Goal

Add a dedicated voice command mode that turns spoken phrases into executable actions instead of pasted text.

## Current Implementation Status

Implemented in the current fork:

- dedicated global shortcut for voice command mode
- shared recorder pipeline routing through `OutputMode.voiceCommand`
- local command registry stored in `UserDefaults`
- command matching by exact utterance prefix
- executor support for:
  - Apple Shortcuts
  - local scripts
  - Alfred URL schemes
- no transcript paste on successful command execution
- success and failure notifications

Current first-version limitations:

- command aliases must be configured manually in Settings
- first exact-prefix match wins
- payload is always plain text
- no fuzzy matching or follow-up clarification
- no dedicated standalone command management screen yet; configuration lives inside Settings

User intent:

- press a dedicated shortcut
- speak a command keyword first
- optionally continue with free-form spoken content
- let VoiceInk dispatch the result to a configured action target

The action target must not be limited to Alfred. It should support:

- Alfred workflows
- Apple Shortcuts
- custom shell scripts or local executables

This mode extends VoiceInk from transcription input into a voice-driven action launcher.

## User Flow

1. User presses the dedicated Voice Command Mode shortcut
2. VoiceInk starts recording using the existing recorder flow
3. User speaks a command phrase, for example:
   - “闪念胶囊 这个想法可以做成一个周会模板”
   - “发到收件箱 明天要给客户回电话”
4. VoiceInk transcribes the speech
5. VoiceInk resolves the command keyword from the beginning of the transcript
6. VoiceInk extracts the remaining text as payload
7. VoiceInk routes the command to the configured action executor
8. The executor runs and receives the payload text

Expected first version behavior:

- command keyword must appear at the start of the utterance
- first matched command wins
- payload is plain text

## Trigger

Primary trigger:

- a dedicated global shortcut for Voice Command Mode

Expected behavior:

- this mode is separate from normal transcription mode
- this mode is separate from Translation Mode
- activating it should set the recording session into command-routing behavior before recording starts

Out of scope for the first version:

- command mode activation by spoken wake word
- multi-step interactive command clarification
- fuzzy command disambiguation UI

## Inputs

Primary input:

- spoken utterance containing:
  - command keyword
  - optional payload text

Configuration input:

- a user-defined command registry
- each command entry must define:
  - display name
  - spoken keywords or aliases
  - executor type
  - target identifier or script path
  - argument contract

Recommended first version contract:

- one payload string
- pass the payload as a single text argument to the executor

## Outputs

Primary output:

- successful execution of the selected action

Optional user-visible outputs:

- success toast or status message
- failure message with cause

Default first version behavior:

- do not paste command transcripts into the cursor
- execute the action instead

## Executor Types

### 1. Alfred

Supported patterns:

- `alfred://` URL invocation
- Alfred External Trigger
- workflow keyword fallback only if the first two are not suitable

Preferred first implementation:

- support a stable external invocation path rather than UI automation

Why:

- lower latency
- lower failure rate
- less dependent on Alfred window state

### 2. Apple Shortcuts

Supported pattern:

- `shortcuts run "<name>" --input <text>`

Preferred first implementation:

- pass payload as plain text input

Why:

- native to macOS
- simple contract
- easy for the user to extend outside VoiceInk

### 3. Custom Scripts

Supported patterns:

- shell script
- executable file
- local CLI entrypoint

Preferred first implementation:

- execute a configured local command with payload as argument or stdin

Recommended contract:

- support either:
  - argv mode: payload as the first argument
  - stdin mode: payload through standard input

## Integration Points

### 1. Hotkey layer

Current relevant module:

- [HotkeyManager.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/HotkeyManager.swift)

Needed change:

- add a dedicated shortcut for Voice Command Mode
- route recording startup with a command output mode flag

### 2. Recording / engine mode routing

Current relevant modules:

- [VoiceInk.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/VoiceInk.swift)
- [TranscriptionPipeline.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Whisper/TranscriptionPipeline.swift)

Needed change:

- add a mode path where post-transcription behavior is command dispatch instead of paste
- share the same audio capture and speech-to-text stack with normal mode

Recommended first implementation:

- unify all post-recording behavior under a shared mode enum
- examples:
  - normal transcription
  - translation
  - voice command

### 3. Command parsing layer

New needed module:

- command registry
- command matcher
- payload extractor

Recommended first implementation:

- store commands as explicit user-defined configurations
- match by exact prefix against normalized transcript text
- normalize spaces and punctuation before matching

### 4. Executor layer

New needed module:

- a command executor abstraction with one implementation per target type

Recommended first implementation:

- `ActionExecutor` protocol or equivalent
- concrete executors:
  - `AlfredActionExecutor`
  - `ShortcutsActionExecutor`
  - `ScriptActionExecutor`

### 5. Settings and configuration UI

Needed capability:

- user can create and edit command actions

Each action should allow configuration of:

- command display name
- spoken aliases
- executor type
- target value
- payload passing mode

First version recommendation:

- build the minimal editor needed to register commands
- avoid building advanced workflow debugging UI inside VoiceInk

## Affected Files or Modules

Expected first-wave touch points:

- [HotkeyManager.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/HotkeyManager.swift)
- [VoiceInk.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/VoiceInk.swift)
- [TranscriptionPipeline.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Whisper/TranscriptionPipeline.swift)

Likely new modules:

- command mode enum or shared output mode enum
- command configuration model
- command registry store
- command parser
- action executor abstraction
- Alfred executor
- Shortcuts executor
- script executor

Likely UI additions:

- shortcut settings for command mode
- command registry settings view

## Edge Cases

- no command matched:
  show a visible failure and do not paste text by default
- command matched but payload is empty:
  executor should still run only if the action allows empty payload
- multiple aliases match:
  prefer longest exact prefix match
- transcript has filler words before the keyword:
  first version should not try to solve this with fuzzy NLP
- Alfred not installed or unavailable:
  fail clearly
- Shortcuts command not found:
  fail clearly
- script path missing or not executable:
  fail clearly
- executor returns non-zero exit status:
  capture and surface a concise error
- normal transcription and translation modes:
  must remain behaviorally unchanged

## Testing

Manual checklist for first implementation:

- app builds successfully with `make local`
- normal transcription mode still pastes text correctly
- translation mode still behaves independently
- command mode shortcut starts recording without breaking other shortcuts
- an Alfred command executes with payload
- a Shortcuts command executes with payload
- a local script executes with payload
- unmatched command shows a readable error
- local build still launches from `/Users/geekmai/Downloads/VoiceInk.app`

Suggested validation scenarios:

- command: “闪念胶囊” -> send payload into an inbox workflow
- command: “翻成待办” -> send payload into a Shortcut
- command: “保存片段” -> write payload to a local script target

## Upstream Merge Risk

Risk level: medium to high

Why:

- the feature touches hotkey registration, recording flow, and post-transcription routing
- it introduces new configuration and executor abstractions

How to keep risk lower:

- keep command mode isolated behind a dedicated mode enum
- keep executor implementations modular and separate from core transcription logic
- avoid hardcoding Alfred-specific logic into the generic pipeline
- keep command registry persistence independent from existing transcription history models

## First Implementation Boundary

The first delivery should include only:

- one dedicated global shortcut for command mode
- one command registry with explicit alias matching
- three executor families:
  - Alfred
  - Shortcuts
  - custom script
- one payload text argument
- visible failure when command resolution or execution fails

The first delivery should not include:

- natural-language intent classification
- multi-parameter structured argument extraction
- interactive confirmation dialogs
- cloud command syncing
- embedded workflow editors
