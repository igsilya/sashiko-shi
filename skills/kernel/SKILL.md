---
name: kernel
description: >
  Linux kernel review context for sashiko-shi. Auto-loads in kernel trees
  (detected by presence of MAINTAINERS file, kernel Makefile with VERSION/
  PATCHLEVEL, or arch/ and include/linux/ directories). Provides subsystem
  guides and technical patterns for the review pipeline.
---

## Project Configuration

- **project_id**: kernel
- **prompts_dir**: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel
- **subsystem_index**: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/subsystem/subsystem.md
- **severity_file**: {{SASHIKO_SHI_DIR}}/prompts/severity.md
- **stage_supplements**:
  - stage-03: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/kernel/stage-03.md
  - stage-04: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/kernel/stage-04.md
  - stage-05: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/kernel/stage-05.md
  - stage-06: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/kernel/stage-06.md
  - stage-07: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/kernel/stage-07.md
- **supplementary_files**:
  - shared-context: {{SASHIKO_SHI_DIR}}/prompts/shared-context.md
  - technical-patterns: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/technical-patterns.md
  - callstack: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/callstack.md
  - false-positive-guide: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/false-positive-guide.md
  - inline-template: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/inline-template.md
  - locking: {{SASHIKO_SHI_DIR}}/third_party/review-prompts/kernel/subsystem/locking.md

## Project Context

This is a Linux kernel tree. Reviews follow Linux Kernel Mailing List (LKML)
conventions.

Key conventions:
- Patches are reviewed for regressions, not style
- Commit messages must accurately describe the change
- Fixes: tags are expected for bug fixes (except in the networking subsystem)
- BPF subsystem: DO require Fixes: tags for major bug fixes
- The inline review format follows LKML email reply conventions
- No markdown in review output; plain text only, wrapped at 78 characters
