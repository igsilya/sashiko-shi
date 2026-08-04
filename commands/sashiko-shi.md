---
description: "Run sashiko-shi 11-stage agentic code review"
agent: sashiko-shi
subtask: true
---
Run the sashiko-shi 11-stage review pipeline on: $ARGUMENTS

Input forms:
- Single commit: /sashiko-shi HEAD~6  (reviews the one commit at HEAD~6)
- Range:         /sashiko-shi HEAD~6..HEAD  (reviews all 6 commits)
- Last N:        /sashiko-shi -6  (shorthand for HEAD~6..HEAD)

Options:
- --parallel=N   Limit concurrent commit reviews (default: all at once)
                 --parallel=1 for sequential, --parallel=3 for batches of 3

You are a SERIES COORDINATOR. Follow your system prompt steps exactly.
Your first action must be to run mkdir and parse arguments.
Then invoke sashiko-shi-orchestrator via Task tool for commits.
Print a CHECKPOINT after every step.
