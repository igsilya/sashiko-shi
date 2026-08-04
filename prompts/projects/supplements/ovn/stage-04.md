# OVN: Resource Management Supplements

OVN builds on OVS libraries, so the OVS stage supplements also apply.

- Same allocators as OVS: `xmalloc()`, `xzalloc()`, etc. (abort on OOM)
- OVSDB IDL row pointers are invalidated after `ovsdb_idl_run()`;
  stale row pointers are a common source of use-after-free
- `hmap` / `smap` / `shash` containers: iteration with `_SAFE` variants
  required when removing during iteration
- `ovn_lflow` and related objects have complex lifecycles tied to I-P
  engine recomputation
