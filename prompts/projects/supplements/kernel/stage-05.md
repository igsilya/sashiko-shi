# Kernel: Locking & Synchronization Supplements

- Sleeping operations: `kmalloc(GFP_KERNEL)`, `mutex_lock()`, `msleep()`,
  `copy_to_user()` / `copy_from_user()`, `wait_event()`
- Non-blocking locks: `spin_lock()`, `spin_lock_bh()`, `spin_lock_irq()`,
  `spin_lock_irqsave()`
- `spin_lock()` does not mask softirqs or hardirqs
- `spin_lock_bh()` disables softirqs
- `spin_lock_irq()` / `spin_lock_irqsave()` disables interrupts
- `mutex` / `rwsem` can sleep; must not be held in interrupt context
- Interrupt contexts: IRQ handlers (hardirq), softirq, tasklets
- RCU read-side: `rcu_read_lock()` / `rcu_read_unlock()` bracket critical
  sections; `rcu_dereference()` required to access RCU-protected pointers
  inside read-side critical sections
- RCU write-side: remove from data structure FIRST, then `call_rcu()` or
  `synchronize_rcu()`, then free in callback
- `READ_ONCE()` / `WRITE_ONCE()` for data races; `READ_ONCE()` not required
  when protected by a held lock
- `preempt_disable()` / `preempt_enable()` bracket preemption-disabled
  sections; per-cpu variables require preemption or migration disabled
