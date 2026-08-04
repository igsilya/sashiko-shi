# Kernel: Execution Flow Supplements

- `goto err` / `goto cleanup` / `goto out` patterns are the standard error
  handling idiom in kernel C code
- `CONFIG_*` symbols control conditional compilation via Kconfig; misspelled
  symbols silently compile as disabled
- `IS_ENABLED(CONFIG_FOO)` is a compile-time check that can guard code paths
- Preprocessor macros with `do { ... } while (0)` wrappers are standard
- `unlikely()` / `likely()` are compiler hints, not logic -- don't report
  changes to them unless they introduce logic bugs
