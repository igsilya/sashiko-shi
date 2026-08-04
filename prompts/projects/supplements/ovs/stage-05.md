# OVS: Locking & Synchronization Supplements

- `ovs_mutex` -- thin wrapper around `pthread_mutex_t`; can sleep
- `ovs_rwlock` -- thin wrapper around `pthread_rwlock_t`
- `fat_rwlock` -- reader-optimized lock using per-thread read-side locks;
  readers call `fat_rwlock_rdlock()` / `fat_rwlock_rdunlock()`;
  writer calls `fat_rwlock_wrlock()` / `fat_rwlock_wrunlock()`
- OVS RCU: `ovsrcu_quiesce()` marks a quiescent state;
  `ovsrcu_synchronize()` waits for all readers to pass a quiescent point
- Datapath fast path is designed to be lockless where possible;
  `dp-packet` processing typically runs without locks
- `seq` (sequence numbers) used for change notification; `seq_change()`
  signals, `seq_read()` / `seq_wait()` consume
