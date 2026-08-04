# Kernel: Security Supplements

- `copy_from_user()` / `copy_to_user()` transfer data to/from user space
- `get_user()` / `put_user()` for single values
- `capable(CAP_*)` / `ns_capable()` for privilege checks
- `SYSCALL_DEFINE*()` macros define system call entry points
- Structures copied to user space must be fully initialized (including
  padding) to prevent information leaks
