---
name: ovn
description: >
  OVN review context for sashiko-shi. Auto-loads in OVN trees (detected by
  presence of northd/ directory, ovn-northd.c, or ovn-controller.c).
  Provides OVN-specific review patterns.
---

## Project Configuration

- **project_id**: ovn
- **prompts_dir**: {{SASHIKO_SHI_DIR}}/prompts/projects
- **subsystem_index**: (not yet created -- use generic mode)
- **severity_file**: {{SASHIKO_SHI_DIR}}/prompts/severity.md
- **stage_supplements**:
  - stage-03: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovn/stage-03.md
  - stage-04: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovn/stage-04.md
  - stage-05: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovn/stage-05.md
  - stage-06: {{SASHIKO_SHI_DIR}}/prompts/projects/supplements/ovn/stage-06.md
- **supplementary_files**:
  - shared-context: {{SASHIKO_SHI_DIR}}/prompts/shared-context.md
  - technical-patterns: {{SASHIKO_SHI_DIR}}/prompts/technical-patterns-generic.md
  - callstack: {{SASHIKO_SHI_DIR}}/prompts/callstack-generic.md
  - false-positive-guide: {{SASHIKO_SHI_DIR}}/prompts/false-positive-guide-generic.md
  - inline-template: {{SASHIKO_SHI_DIR}}/prompts/inline-template-generic.md

## Project Context

This is an OVN tree (C codebase, builds on top of OVS libraries).

Key conventions:
- Thread safety: same primitives as OVS (ovs_mutex, ovs_rwlock)
- Memory: xmalloc/xzalloc/xrealloc abort on OOM
- Logging: VLOG_* macros (same as OVS)
- Components: northd (centralized), ovn-controller (per-hypervisor)
- Schema: OVN_Northbound and OVN_Southbound OVSDB schemas
- Logical flows: northd translates NB schema to logical flows in SB
- ovn-controller translates logical flows to OpenFlow rules
- Incremental Processing (I-P): engine nodes for efficient recomputation
- Patches go to dev@openvswitch.org

Note: OVN subsystem guides are not yet created. The review pipeline will
run in generic C code review mode. Contributions to add OVN-specific
subsystem guides are welcome.
