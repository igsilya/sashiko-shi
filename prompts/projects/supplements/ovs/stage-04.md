# OVS: Resource Management Supplements

- `xmalloc()` / `xzalloc()` / `xrealloc()` / `xcalloc()` abort on OOM;
  no NULL return checks needed (they never return NULL)
- `xstrdup()` / `xmemdup()` also abort on OOM
- `free()` frees memory; any subsequent access is use-after-free
- `ovs_refcount_ref()` / `ovs_refcount_unref()` for reference counting;
  `ovs_refcount_unref()` returns the old value (check for 1 meaning
  "last reference was just released")
- `ovsrcu_postpone()` defers freeing until RCU grace period; similar to
  kernel's `call_rcu()` but OVS-specific implementation
- `dp_packet` objects: `dp_packet_delete()` frees; watch for ownership
  transfers in the datapath pipeline
