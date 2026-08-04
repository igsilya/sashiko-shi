# False Positive Verification Guide
<!-- Derived from kernel/false-positive-guide.md in the review-prompts
     project by Chris Mason (MIT License).  See NOTICE for details. -->

## Core Principle

Only report issues with concrete proof that at least one execution path
can trigger them. Speculation is not enough.

## Verification Checklist

Before reporting any concern as a finding, verify ALL of the following:

1. **Path execution proof**: Can you trace a concrete call chain from an
   entry point to the bug? Name the functions and conditions.

2. **Structural possibility**: Is it structurally possible for the
   condition to arise? Check type constraints, value ranges, and
   invariants maintained by the surrounding code.

3. **Full context**: Did you read the complete function, not just the
   diff hunk? The fix or guard might be in the unchanged code above
   or below the diff.

4. **Correctness of your reasoning**: Re-read your reasoning. Did you
   confuse two variables? Misread operator precedence? Assume a function
   does something it doesn't?

5. **Commit message vs. code**: If you think the commit message is wrong,
   verify by reading the code. If the code does what the commit message
   says, there is no bug even if the wording is imprecise.

6. **Multi-step conditions**: If the bug requires multiple conditions to
   be true simultaneously, verify that this combination is possible.
   Don't assume independence.

7. **Hallucination check**: Re-read the actual code. Did you invent a
   function, variable, or behavior that doesn't exist in the source?

8. **Forward search**: Check if a later commit in the same series fixes
   the issue you found. If so, it may be an intermediate state that gets
   resolved.

9. **Comment and documentation accuracy**: If your concern is based on a
   comment being wrong, verify the actual behavior. Wrong comments are
   worth noting but are low severity.

10. **Self-debate**: Argue against your own finding. If you can construct
    a plausible defense, the finding may be a false positive.

## Common False Positive Patterns

### 1. Defensive programming suggestions

Suggesting additional checks or error handling where the existing code
already prevents the issue through upstream validation, type constraints,
or API contracts. Do not recommend defensive programming unless it fixes
a proven bug.

### 2. Misunderstood API contracts

Assuming a function can fail or return a special value when its contract
guarantees otherwise (e.g., allocators that abort on failure, iterators
that guarantee valid elements).

### 3. Incomplete context

Finding a "bug" in a diff hunk that is actually handled by surrounding
code not shown in the diff. Always read the full function.

### 4. Comment-based reasoning

Assuming behavior from comments without verifying the actual code.
Comments may be outdated, aspirational, or simply wrong.

### 5. Conditional compilation

Reporting bugs in code that is conditionally compiled out for the
configuration or platform being discussed.

### 6. Error path resource tracking

Reporting a leak on an error path where the resource is actually cleaned
up by a different mechanism (error callback, container destructor,
scope-based cleanup, garbage collection).

### 7. Test code leniency

Report all bugs in test code (leaks, crashes, resource issues) -- do
NOT discard them.  Classify them at reduced severity (e.g., medium
instead of high) since their impact is limited to test infrastructure.

This leniency only applies to dedicated test files (under tests/,
test/, or following \*_test.\* naming conventions).  Production code,
stubs, dummy implementations, and example code in library or
application directories are NOT test code and follow normal severity
rules.

New bugs introduced by the patch are always reported regardless of
where they occur.  If the patch changes an API and misses updating
a test caller, that is a regression.

### 8. Reverts and rollbacks

A revert restoring previous behavior is not introducing a new bug, even
if the previous behavior was suboptimal.

### 9. Intermediate patch states

In a patch series, an intermediate patch may introduce a temporary state
that the next patch resolves. Check the full series context.

### 10. Performance suggestions without proof

Suggesting performance improvements without concrete evidence of a
performance problem. Do not report unless the regression is measurable
and significant.

## Final Filter

Before including a finding in your output, answer these four questions:

1. Can I name the specific execution path that triggers this?
2. Is there a concrete code-level reason this is wrong, not just "it
   could theoretically be a problem"?
3. Have I verified my understanding against the actual source code?
4. Would an experienced maintainer of this project agree this is a real
   concern?

If ANY answer is NO, discard the finding.
