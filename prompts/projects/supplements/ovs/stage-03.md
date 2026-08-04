# OVS: Execution Flow Supplements

- OVS uses C99/C11 with 4-space indentation, no tabs
- Error codes use positive errno values, not negative kernel-style returns
- `ovs_fatal()` / `ovs_abort()` terminate the process; these are
  unrecoverable errors
- `OVS_NOT_REACHED()` marks unreachable code paths
- `ovs_assert()` is the standard assertion macro
