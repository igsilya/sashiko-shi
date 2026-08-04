---
name: ovs
description: >
  Open vSwitch review context for sashiko-shi. Auto-loads in OVS trees
  (detected by presence of ofproto/ directory, ovs-vswitchd.c, or
  lib/dpif-netdev.c). Provides OVS-specific review patterns.
---

## Project Configuration

- **project_id**: ovs
- **prompts_dir**: {{SASHIKO_SHI_DIR}}/prompts/projects
- **subsystem_index**: (not yet created -- use generic mode)
- **severity_file**: {{SASHIKO_SHI_DIR}}/prompts/severity.md
- **stage_supplements**:
  - stage-03: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovs/stage-03.md
  - stage-04: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovs/stage-04.md
  - stage-05: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovs/stage-05.md
  - stage-06: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovs/stage-06.md
- **supplementary_files**:
  - shared-context: {{SASHIKO_SHI_DIR}}/prompts/shared-context.md
  - technical-patterns: {{SASHIKO_SHI_DIR}}/prompts/technical-patterns-generic.md
  - callstack: {{SASHIKO_SHI_DIR}}/prompts/callstack-generic.md
  - false-positive-guide: {{SASHIKO_SHI_DIR}}/prompts/false-positive-guide-generic.md
  - inline-template: {{SASHIKO_SHI_DIR}}/prompts/inline-template-generic.md

## Project Context

This is an Open vSwitch tree (C codebase).

Key conventions:
- Thread safety: ovs_mutex, ovs_rwlock, fat_rwlock
- Memory: xmalloc/xzalloc/xrealloc abort on OOM (no NULL checks needed)
- Logging: VLOG_WARN, VLOG_ERR, VLOG_INFO, VLOG_DBG macros
- Reference counting: ovs_refcount_ref/ovs_refcount_unref
- Patches go to dev@openvswitch.org
- Code style follows OVS coding conventions (see CodingStyle.rst)
- Datapath (dp-packet, dpif) is performance-critical
- OpenFlow protocol handling must be version-aware

Note: OVS subsystem guides are not yet created. The review pipeline will
run in generic C code review mode. Contributions to add OVS-specific
subsystem guides are welcome.
