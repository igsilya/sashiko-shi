# Technical Deep-dive Patterns
<!-- Derived from kernel/technical-patterns.md in the review-prompts
     project by Chris Mason (MIT License).  See NOTICE for details. -->

## Core instructions

- Trace full execution flow, gather additional context from the call chain
  to make sure you fully understand
- IMPORTANT: never make assumptions based on return types, checks, assertion
  macros, comments, or error handling patterns -- explicitly verify the code
  is correct by tracing concrete execution paths
- IMPORTANT: never assume that changing an assertion (assert, WARN, BUG,
  panic trigger) changes the errors or conditions a function can accept.
  Assertions affect diagnostics and abort behavior, not the control flow of
  surrounding code.
- IMPORTANT: never skip any steps just because you found a bug in a
  previous step.
- IMPORTANT: documentation and comments are sometimes incomplete, outdated,
  or misleading. When relying on documentation or comments:
  - Always read the ACTUAL IMPLEMENTATION, not just the comment
  - Check for conditional compilation branches and platform-specific variants
    -- the same comment may be copy-pasted to multiple implementations with
    different semantics
  - If a function comment says "returns X" but the code shows conditional
    behavior based on configuration or platform, verify which applies
- Never report errors without checking to see if the error is impossible in
  the call path you found.
    - Some call paths might always check feature flags or configuration
      before reaching the affected code
    - It's not enough for the API contract to be unclear, you must prove the
      bug can happen in practice.
    - Do not recommend defensive programming unless it fixes a proven bug.

### Error Handling

**Notes**:
- If code checks for a condition via an assertion macro (assert, WARN, BUG,
  panic), assume that condition will never happen unless you can provide
  concrete evidence of that condition existing via code snippets and call
  traces
- Distinguish between recoverable errors (returned error codes, exceptions)
  and unrecoverable errors (abort, panic, process exit). The handling
  strategy differs.
- In languages with exceptions, check that exception handlers catch the
  correct types and don't accidentally swallow unexpected exceptions.

### Bounds & Validation

**Important**: Never suggest defensive bounds checks unless you can prove
the source is untrusted.

- Array/buffer bounds: verify index is within valid range before access
- String operations: verify destination size is sufficient
- Integer arithmetic: check for overflow/underflow in size calculations,
  especially before memory allocation
- Type conversions: verify narrowing conversions don't truncate significant
  bits (e.g., 64-bit to 32-bit, signed to unsigned)

### Resource Management Knowledge

- Every resource must have balanced lifecycle: acquire -> init -> use ->
  cleanup -> release
- Track resource ownership through function calls: who is responsible for
  releasing a resource after a function returns?
- Reference counting: counters typically cannot be incremented after reaching
  zero (the object may already be freed). Verify the semantics of the
  specific reference counting API used.
- If you find a type mismatch, trace the type fully and check against the
  expected type to make sure you're flagging it correctly
- When freeing/destroying resources referenced by structure fields, ensure
  the fields are cleared (set to NULL/nil/None) to prevent use-after-free
  on reuse if the containing structure is not also immediately freed
  - Exception: if the containing object is also freed immediately after,
    clearing fields is unnecessary
- Resource switching detection:
  - Check every path where a function returns a different resource than it
    was meant to modify
  - Ensure proper synchronization is maintained during the switch
- Caller expectation tracing: what does the caller expect to happen to the
  resources it passed into functions?

### RCU (Read-Copy-Update) Patterns

RCU is a synchronization mechanism that allows lock-free read-side access
to shared data structures. It is used in the Linux kernel, Open vSwitch,
OVN, glibc (via `call_rcu`), userspace-rcu (liburcu), and many other
systems-level projects.

**Core RCU invariant**: The correct sequence is:
1. Remove the object from all lookup structures (lists, hash tables, trees)
2. Wait for all existing readers to finish (grace period)
3. Free the object

**CRITICAL**: When you see deferred-free calls (`call_rcu()`,
`synchronize_rcu()`, `kfree_rcu()`, `ovsrcu_postpone()`, or equivalent):
- Check: does removal from data structures happen BEFORE or AFTER the
  deferred-free call?
- If removal is in the deferred callback -> this is the WRONG pattern,
  flag as use-after-free

**Correct pattern**:
```
  remove_from_list(obj);     /* readers can no longer find obj */
  call_rcu(&obj->rcu, free_callback);  /* free after grace period */
```

**WRONG pattern** (use-after-free):
```
  call_rcu(&obj->rcu, callback);
  /* In callback: */
  void callback(...) {
      remove_from_list(obj);  /* WRONG: too late! */
      free(obj);
  }
```

**Read-side rules**:
- Read-side critical sections must be bracketed by the appropriate API
  (e.g., `rcu_read_lock()`/`rcu_read_unlock()` in kernel,
  `rcu_read_lock()`/`rcu_read_unlock()` in liburcu)
- Pointers to RCU-protected objects must be accessed through special
  accessors (e.g., `rcu_dereference()`) inside read-side critical sections
- Do NOT hold references to RCU-protected objects after exiting the
  read-side critical section unless a reference count was acquired

**Grace period considerations**:
- `synchronize_rcu()` blocks until all pre-existing read-side critical
  sections complete -- safe but expensive
- `call_rcu()` defers the callback until after the grace period -- async,
  no blocking
- Objects must not be accessed between removal from lookup structures and
  the completion of the grace period, except through existing read-side
  references

### Loop Patterns

- `for(init; condition; advance) { body }` -- checks 'condition' BEFORE
  executing 'body'
- `for(init; condition; advance) { body }` -- 'advance' only runs AFTER
  'body'
- Iterator invalidation: modifying a collection while iterating may
  invalidate the iterator (language-dependent -- check the specific
  container's rules)
- Off-by-one: verify loop bounds include/exclude the boundary correctly
- Infinite loops: verify every loop has a reachable exit condition
- Global arrays with MAX_FOO: check if it is possible to create more than
  MAX_FOO elements

### NULL / Nil / None Dereference Analysis

Review the examples carefully before analyzing null dereferences.
Misunderstanding what constitutes a dereference causes false positives.

For pointer-based languages (C, C++, Go, Rust raw pointers):

**Dereference Types** (C/C++ examples, analogous in other languages):
```
- val = *foo dereferences foo
  - if (foo) val = *foo is safe
- val = foo[var] dereferences foo but only reads var without dereference
  - if (foo) val = foo[var] is safe
- val = foo->ptr dereferences foo but only reads ptr without dereference
  - if (foo) val = foo->ptr is safe
- val = *foo->ptr dereferences foo and ptr.
  - if (foo && foo->ptr) val = *foo->ptr is safe
- val = foo->ptr->something dereferences foo and ptr but only reads something
  - if (foo && foo->ptr) val = foo->ptr->something is safe
```

**Key Points**:
1. **Reading a field is not the same as dereferencing it**
   - `ptr = foo->bar` dereferences `foo`, reads `bar`, but does NOT
     dereference `bar`
   - The dereference happens when you later USE `ptr`

2. **Check where the reference is actually used**
   - If `ptr = foo->bar` and `bar` can be NULL, the problem occurs when
     `ptr` is dereferenced
   - Example: `ptr->field` or `*ptr` or `ptr[0]` or passing `ptr` to a
     function that dereferences it

3. **NULL checks protect the reference being checked**
   - `if (foo)` protects dereferencing `foo`
   - `if (foo && foo->bar)` protects dereferencing both `foo` and `foo->bar`

For languages with optional/nullable types (Go, Rust Option, Java, Python):
- Go: check for `nil` before dereferencing interface values and pointers
- Rust: `Option::unwrap()` panics on `None`; prefer `match` or `if let`
- Java/Python: `NullPointerException` / `AttributeError` on null access
- The same dereference analysis applies: trace where the value came from
  and whether null/nil/None is possible at each use point

### Error Return Value Patterns

Different languages use different error signaling:
- C: return codes (0 = success, negative = error), errno, NULL on failure
- C++: exceptions, std::optional, error codes
- Go: multiple return values `(result, error)`, nil checks
- Rust: `Result<T, E>`, `Option<T>`, `?` operator
- Python/Java: exceptions, None returns
- For each language, verify the error signaling convention is followed
  consistently and that callers handle error returns appropriately
