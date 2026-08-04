# Kernel: Resource Management Supplements

- `kfree(ptr)` / `kvfree(ptr)` frees memory; any subsequent access is UAF
- `kmalloc()` / `kzalloc()` / `kvmalloc()` allocate memory; check for NULL
  return on allocation failure (except `__GFP_NOFAIL`)
- `kzalloc()` / `kcalloc()` zero-fill; `kmalloc()` does not
- `refcount_inc()` / `refcount_dec_and_test()` for reference counting;
  `refcount_dec_and_test()` returns true ONLY when count reaches zero
- `cancel_work_sync()` / `del_timer_sync()` must precede `kfree()` of the
  containing structure to prevent use-after-free from pending async work
- Async mechanisms: `work_struct` (workqueues), `timer_list` (timers),
  `call_rcu()` (RCU callbacks), `tasklet` (softirq deferred work)
- `kmem_cache_create()` with `init_once()` initializes slab objects on
  first allocation only
- Global and static variables are automatically zero-filled
- `ERR_PTR()` holds an error cast to a pointer; `if (ptr)` is TRUE for
  ERR_PTR values but dereferencing will crash
