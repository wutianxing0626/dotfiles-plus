---
name: handoff
description: Generate a compact-style pre-context document (a handoff / pre_context file) so a fresh Codex session in another directory can continue work from a previous discussion. Use when a conversation concludes with a decided approach and the user says they want to continue in a new directory (for example, "我们去一个新目录继续" or "let's continue in a new folder"), when the user asks for a handoff, pre_context, or pre_plan document, or when a long discussion should be preserved as a one-shot summary for a new session.
---

# Handoff

Create a self-contained handoff document that another Codex
session can read once and continue from. It is the manual equivalent of conversation
compaction, but for cross-directory handoff: conclusions and paths must be explicit,
because the new session has no access to this conversation's history.

## Procedure

1. Determine the task name; default the document name to `handoff.md`.
2. Copy `assets/handoff-template.md` into the current task subdirectory and fill it in
   from the conversation. Keep it to one page: conclusions over reasoning, absolute
   paths over descriptions.
3. Write the document in the language of the conversation.
4. If the directory is a git repository (or has a `.gitignore`), append the handoff
   document's path (e.g. `handoff.md`) and the archive directory (`temp/`) to the
   directory's `.gitignore`, creating it if absent, so the document and its archive
   copies are never committed.
5. Ask the user whether to create the target directory (for example
   `~/<new-directory>`) and migrate the relevant files there, including the handoff
   document; only create directories or move files after the user agrees.
6. In your final response, give the handoff document's absolute path (after any
   migration) and the exact first message for the new session: open the target folder
   in the editor, then send "Read `<absolute path>` first, then continue according to
   the plan." Also tell the new session to archive the document after reading it
   (see step 7).
7. After the new session reads the document and continues, archive it: move it to
   `./temp/handoff_archive/<task-name>-handoff-<YYYY-MM-DD>.md`, creating the directory
   if needed. Archive means move; never delete.

Do not include CLI or setup instructions: the user starts the new session by opening the
target folder in their editor.
