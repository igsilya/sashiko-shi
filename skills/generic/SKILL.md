---
name: generic
description: >
  Generic code review context for sashiko-shi. Fallback skill for any
  project without a specific skill. Works with any programming language
  and framework. This skill should only be loaded when no project-specific
  skill (kernel, ovs, ovn) matches the current working directory.
---

## Project Configuration

- **project_id**: generic
- **prompts_dir**: {{SASHIKO_SHI_DIR}}/prompts
- **subsystem_index**: (none -- skip pre-screening)
- **severity_file**: {{SASHIKO_SHI_DIR}}/prompts/severity.md
- **stage_supplements**: (none)
- **supplementary_files**:
  - shared-context: {{SASHIKO_SHI_DIR}}/prompts/shared-context.md
  - technical-patterns: {{SASHIKO_SHI_DIR}}/prompts/technical-patterns-generic.md
  - callstack: {{SASHIKO_SHI_DIR}}/prompts/callstack-generic.md
  - false-positive-guide: {{SASHIKO_SHI_DIR}}/prompts/false-positive-guide-generic.md
  - inline-template: {{SASHIKO_SHI_DIR}}/prompts/inline-template-generic.md

## Project Context

This is a generic software project. Determine the programming language
and framework from the source code. Apply language-appropriate review
patterns.

Focus on universal concerns:
- Logic errors and incorrect control flow
- Resource management (memory, file descriptors, connections, locks)
- Concurrency and synchronization
- Security (input validation, access control, information leaks)
- API contracts and backwards compatibility
- Error handling completeness
