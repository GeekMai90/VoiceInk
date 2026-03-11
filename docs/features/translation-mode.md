# Translation Mode

## Goal

Add a dedicated voice input mode for translation-oriented output.

User intent:

- speak naturally in Chinese
- trigger VoiceInk with a dedicated shortcut
- receive polished English output instead of raw Chinese transcription

This mode is intended for writing English messages, emails, notes, and short-form content faster than manual translation.

## User Flow

1. User presses the dedicated Translation Mode shortcut
2. VoiceInk starts recording using the existing recorder UI
3. User speaks in Chinese
4. VoiceInk transcribes the speech to source text
5. VoiceInk routes the transcript through a translation-specific AI prompt
6. The output becomes polished English, not literal word-for-word translation
7. The final English text is pasted at the cursor using the existing paste flow

## Trigger

Primary trigger:

- a new dedicated global shortcut for Translation Mode
- configurable from Settings under Additional Shortcuts

Expected behavior:

- it should not replace the current default transcription shortcut
- it should coexist with the normal transcription shortcut
- it should activate a distinct post-transcription mode before recording starts

Out of scope for the first version:

- per-app translation shortcut overrides
- multiple translation shortcuts for different languages
- mode switching by spoken voice command

## Inputs

- spoken Chinese audio
- existing active model selection for speech-to-text
- optional existing context already supported by VoiceInk AI enhancement:
  - selected text
  - clipboard context
  - current window captured text
  - custom vocabulary

## Outputs

Primary output:

- polished English text pasted to the current cursor location

Output quality expectation:

- preserve original intent
- prefer natural English phrasing over literal translation
- remove obvious spoken filler when helpful
- lightly polish grammar and readability
- avoid adding extra meaning that was not present in the source

Non-goals for first version:

- bilingual output
- side-by-side Chinese and English output
- selectable tone presets
- formal vs casual translation controls

## Integration Points

### 1. Hotkey layer

Current relevant module:

- [HotkeyManager.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/HotkeyManager.swift)

Needed change:

- define a new keyboard shortcut name for Translation Mode
- bind it to a new action path that starts recording with a mode flag

### 2. Recording / engine mode routing

Current relevant modules:

- [VoiceInk.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/VoiceInk.swift)
- [TranscriptionPipeline.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Whisper/TranscriptionPipeline.swift)

Needed change:

- introduce a lightweight recording output mode concept
- normal mode should continue to behave exactly as it does now
- translation mode should alter only post-transcription processing

Recommended first implementation:

- add a small enum such as `OutputMode`
- thread it through recording start and post-processing
- keep default mode as normal transcription

### 3. AI enhancement layer

Current relevant module:

- [AIEnhancementService.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Services/AIEnhancement/AIEnhancementService.swift)

Needed change:

- translation mode should reuse the existing AI request infrastructure where possible
- add a translation-specific prompt path rather than overloading the normal enhancement prompt

Recommended first implementation:

- add a dedicated enhancement mode or dedicated prompt type for translation
- keep it separate from the current generic transcript enhancement behavior
- use a built-in translation prompt first; custom translation prompt can be added later

### 4. Settings and UI

Likely affected areas:

- shortcut settings UI
- optional mode label in recorder UI

First version recommendation:

- add shortcut configuration
- make mode visible in a minimal way only if technically easy
- do not redesign the main UI yet

## Affected Files or Modules

Expected first-wave touch points:

- [HotkeyManager.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/HotkeyManager.swift)
- [VoiceInk.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/VoiceInk.swift)
- [TranscriptionPipeline.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Whisper/TranscriptionPipeline.swift)
- [AIEnhancementService.swift](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk/Services/AIEnhancement/AIEnhancementService.swift)
- shortcut settings views under [VoiceInk](/Users/geekmai/Documents/Code/VoiceInk/VoiceInk)

Potential supporting additions:

- a small shared mode enum
- a translation prompt definition
- a user default key for the translation shortcut

## Edge Cases

- no AI provider configured:
  translation mode should fail clearly instead of silently pasting raw Chinese
- translation request fails:
  define whether to paste raw transcript or show an error
  recommendation for first version: paste raw transcript only if explicitly chosen later; default should be visible failure
- user speaks mixed Chinese and English:
  preserve intended English terms where reasonable
- very short utterances:
  avoid over-expanding a one-word or two-word phrase
- names, product names, and domain terminology:
  custom vocabulary should still help preserve expected wording
- normal transcription mode:
  must remain behaviorally unchanged

## Testing

Manual checklist for first implementation:

- app builds successfully with `make devsigned`
- normal transcription shortcut still records and pastes normal output
- translation shortcut starts recording without breaking the default shortcut
- Chinese speech produces English output
- output is English even when the normal enhancement toggle is off
- failure state is understandable when no AI provider is configured
- paste flow still works in common text fields
- stable local dev app still launches from `/Applications/VoiceInk Ultra.app`

Suggested validation phrases:

- “帮我写一封邮件，告诉对方我明天下午三点可以开会”
- “这个功能还不稳定，我们下周再复测一次”
- “请把这个想法整理成三个要点”

Current validation status:

- implemented
- builds successfully with `make devsigned`
- manually tested by user
- user reported no issue in current test pass

## Upstream Merge Risk

Risk level: medium

Why:

- the feature touches core input flow and hotkey registration
- these are areas likely to change upstream

How to keep risk lower:

- isolate the new mode behind a small enum and dedicated shortcut
- avoid rewriting the default recording pipeline
- reuse existing AI enhancement transport instead of creating a second AI stack
- keep translation prompt logic separate from generic enhancement prompt logic

## First Implementation Boundary

The first delivery of Translation Mode should include only:

- one dedicated global shortcut
- one dedicated translation output mode
- Chinese speech to polished English text
- paste to cursor using the existing output path

The first delivery should not include:

- command routing
- Alfred integration
- multi-language translation matrix
- translation history filters
- advanced translation prompt tuning UI
