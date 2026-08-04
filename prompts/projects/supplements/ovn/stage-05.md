# OVN: Locking & Synchronization Supplements

OVN builds on OVS libraries, so the OVS stage supplements also apply.

- Same primitives as OVS: `ovs_mutex`, `ovs_rwlock`, `fat_rwlock`
- northd is single-threaded; concurrency concerns are mainly between
  ovn-controller threads
- ovn-controller uses the OVS main loop model: single main thread with
  periodic `run()` calls, plus auxiliary threads for specific tasks
- I-P engine processing is single-threaded within a given `run()` cycle
