# Review Report Template
<!-- Derived from kernel/inline-template.md in the review-prompts
     project by Chris Mason (MIT License).  See NOTICE for details. -->

Produce a report of regressions found based on this template.

## Format Rules

- The report must be in plain text only. No markdown, no special
  characters, absolutely and completely plain text suitable for email
  or mailing list submission.

- Any long lines present in the diff should be preserved, but any
  summary, comments or questions you add should be wrapped at 78
  characters.

- Never include bugs filtered out as false positives in the report.

- Always end the report with a blank line.

## Tone and Style

- The report must be conversational with undramatic wording.
- Report must be factual -- just technical observations.
- Report should be framed as questions, not accusations.
- Call issues "regressions" or "concerns", never use the word "critical"
  in the text.
- NEVER EVER USE ALL CAPS.

- Explain the regressions as questions about the code, but do not
  mention the author.
  - don't say: Did you corrupt memory here?
  - instead say: Can this corrupt memory? or Does this code ...

- Vary your question phrasing. Don't start with "Does this code ..."
  every time.

- Ask your question specifically about the sources you're referencing:
  - If the regression is a leak, don't call it a 'resource leak', ask
    specifically about the resource. 'Does this code leak the file
    descriptor?'
  - Don't say: 'Does this loop have a bounds checking issue?' Name the
    variable: "Does this overflow the buffer[]?"

- When the issue is in the commit message itself, quote the exact
  portions that are incorrect, the same way you'd report a bug in
  the diff.

- Do not add additional explanatory content about why something matters
  or what benefits it provides. State the issue and the suggestion,
  nothing more.

- Do not explain why typos or grammar mistakes are a problem. Just point
  them out.

## Quoting Code

- Quote code from the diff using > prefix (plain text quoting)
- Snip irrelevant parts of hunks with [...]
- Never quote line numbers directly; use code snippets
- Keep quotes short and focused on the relevant lines

## Ensure Clear, Concise Paragraphs

Never make long or dense confusing paragraphs. Ask short questions
backed up by code snippets, or call chains if needed. Use blank lines
between logical groups.

## Structure

The report should follow this structure:

1. Start with the commit identifier and author
2. Brief summary of what the patch does (one or two sentences)
3. For each finding, quote the relevant code and ask your question
4. End with a blank line

Example structure:

  commit <sha> ("<subject>")
  Author: <author>

  This patch does X and Y.

  > <quoted code line>
  > <quoted code line>

  Can this leak the allocated buffer when the error path is taken?
  The allocation on the line above doesn't appear to be freed before
  the return here.

  ---

  > <next quoted section>

  <next question>

