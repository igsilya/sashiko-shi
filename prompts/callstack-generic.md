# Callstack Regression Analysis
<!-- Derived from kernel/callstack.md in the review-prompts project
     by Chris Mason (MIT License).  See NOTICE for details. -->

This pattern analyzes functions for regressions within the callstack as a whole.
Changes to a function can introduce bugs not only in the function itself, but in
any function it calls (callees) and any function that calls it (callers). This
analysis traverses the full callstack -- both up and down -- to identify
side effects, unintended consequences, and regressions that would be invisible
when examining modified functions in isolation.

Note: ptr->field dereferences ptr BUT NOT field.

This callstack analysis is required for all non-trivial changes.

Add each Task from this prompt (Task 1,2,3,4,5,6,7,8,9) into a TodoWrite.
The TodoWrite must ensure that you complete every task before completing
this prompt.

---

## CRITICAL: RETRACTION RULE

If during analysis you conclude something IS a bug and later reverse that
conclusion, you must treat the reversal with extreme skepticism. State the
retraction explicitly, re-examine your dismissal reasoning for logical errors,
and apply a higher burden of proof. "Caller should prevent this" or "normally
handled" are not sufficient -- you must prove the triggering condition is
structurally impossible with concrete code references.

## CRITICAL: REACHABILITY DISMISSALS

A code path that can infinite loop, deadlock, crash, or corrupt data is a bug
even if you believe preconditions make it unlikely. Do not dismiss such bugs
by arguing:

- "The caller normally prevents this input"
- "This only happens if [upstream function] fails"
- "The old code had a worse bug in the same path"
- "Extremely unlikely in practice"

Only dismiss if the triggering condition is **structurally impossible** --
meaning the code literally cannot reach that state regardless of timing,
memory pressure, or concurrent operations.

---

## CRITICAL: Batch Tool Calls

Each API turn re-sends conversation history. Batch all lookups.

When looking up multiple function definitions, callers, or call targets:
- Identify ALL items you need to look up FIRST
- Make ALL requests in ONE message, not one at a time
- This applies to grep, read, and any code navigation tools

---

Regression analysis requires understanding both the changes made and all of
the ways those changes impact unmodified code. This part of the prompt gathers
additional context beyond just the modified functions so that we can search
for side effects and unintended consequences that lead to regressions.

Your analysis must search for those side effects, both in modified functions
and up and down the call stack into unmodified code.

# Task 0: Category iteration

CHANGE CATEGORIES should have been loaded into context before calling
callstack analysis. Iterate through all of them if they were provided.
Otherwise, consider the entire unit being analyzed a single change category.

- For EVERY category identified
- Perform Tasks 1-6 separately
- You must fully complete every category
- Output: Category N of M: name, description
  - Output: callers loaded: [ list, with random lines from each function ]
  - Output: callees loaded: [ list, with random lines from each function ]
- Completion of this prompt requires enumeration and completion for every category

## Task 1: **Callee traversal process**:

**BATCH ALL FUNCTION LOOKUPS IN ONE MESSAGE**

- Step callee.1: Identify all direct callees in modified functions
  - We gather the callees because even small changes in functions can
    cause bugs in the functions they call. The only way to know is to
    actually read the functions in the callstack.
  - Use grep/read tools to find callee definitions
  - Record both the callees and the arguments used
  - **List ALL callees first before loading any**
  - Output: names of callees
- Step callee.2: For each callee, load entire function definition
  - **Look up ALL callees in ONE parallel message**
  - Output: The callee function names, and a random line from anywhere
    in each definition (you must prove you read the callee)
- Step callee.3: Trace 2-3 levels deep as needed
  - **Batch additional lookups together**
  - Small changes higher up in the stack can introduce bugs lower down.
    You cannot analyze code effectively without looking at the call stack,
    even for changes that you think you understand.
- Step callee.4: Apply all checks below to each callee in the chain
  - Output: The callee function names, and a random line from each
- Step callee.5: Completing the callee analysis is not sufficient. You must
  also complete caller analysis.

## Task 2: **Caller traversal process:**

**BATCH ALL CALLER LOOKUPS IN ONE MESSAGE**

- For every step, consider both the callers and the arguments used
- step caller.1: Identify all direct callers
  - We gather the callers because even small changes can introduce bugs
    in the functions that call them. The only way to know is to actually
    read the functions in the callstack.
  - Use grep/read tools to find all call sites of modified functions
  - Output: names of callers
- step caller.2: For each caller, load function definition
  - **Look up ALL callers in ONE parallel message**
  - Output: caller name, size in lines
  - Output: The caller function names, and a random line from each
    (you must prove you read the callers)
- step caller.3: For callers that propagate return values, trace their callers
  - Changes and errors can propagate up in surprising ways. You need to
    read the callers.
  - Search caller for return value propagation higher into the stack
    - If there is potential impact to caller's callers
      - Read caller's callers full definition
      - Output caller's caller names [ list, impacted return statements ]
      - Continue recursively up the chain at most 3 levels
  - Output: caller name, return value line
- step caller.4: Apply all checks in Tasks 3-7 below to every caller
  - Output: The caller function names, and a random line from each
- step caller.5: Continue into lock requirement analysis, even if you think
  you've found enough data to complete the analysis

## Task 3: **Mandatory Lock/synchronization requirements**:

- step lock.1: Verify proper synchronization is maintained in every tracked
  function
  - You MUST include callers of modified functions, even if they were
    not modified
  - You MUST include callees of modified functions, even if they were
    not modified
  - Changes in modified functions often have unintended side effects
    elsewhere in the call stack. Your analysis must search for these.
  - Output: locks/synchronization required
- step lock.1b: Verify lock scope, not just lock presence
  - Do not treat lock acquisition as binary (present/absent). A lock has
    a scope: acquired at one point, released at another. Verify that
    EVERY access to the protected resource falls within that scope.
  - When a function acquires a lock partway through its body, load all
    callees that execute before the acquisition -- any of them may access
    the protected resource outside the lock's scope.
  - Output: for each concurrent function checked, state the exclusion
    point and confirm no shared-resource access precedes it.
- step lock.2: Ensure functions take and release locks as expected by caller
- step lock.3: If locks are changed or dropped during the call, verify code
  properly revalidates state
- step lock.4: Ensure caller provides all locks/synchronization required by
  callees
- step lock.5: Continue into Task 4, even if you think you've found enough
  details
- Output: Category NUMBER [ list of locks/sync primitives checked ]

## Task 4: **Mandatory locking in error path validation**:

- step lock.6: For every lock acquired, trace error paths ensuring locks are
  properly released or handed off
  - You MUST include callers and callees of modified functions, even if
    they were not modified
  - Output: locations of all error paths
- step lock.7: Continue into Task 5
- Output: Category NUMBER [ error path lines ]

## Task 5: **Mandatory resource propagation validation**:

- Notes on tracking allocations:
  - Consider every pointer/handle assignment a potential resource acquisition
  - Track ownership transfers: who is responsible for releasing the resource?
  - This includes opaque handles, file descriptors, connection objects,
    and any type that wraps a resource
  - Output: at least 3 resources assigned in modified functions, w/line of code

- step resource.1: Trace resource ownership through function boundaries
  - You MUST include callers and callees of modified functions
  - When resources are acquired, make sure they are somehow returned or
    consumed before they are overwritten
- step resource.2: For allocations:
  - Check if the size parameter can be zero and whether that causes issues
  - Check for integer overflow in size calculations
- step resource.3: For multiple references to same resource: track how
  modifications through one affect others
  - Use this to understand the relationship between the objects being
    manipulated and the references being used
  - Output: list of references you found for the same resource
- step resource.4: Verify resources are properly initialized, synchronized,
  and released
- step resource.5: Continue into Task 5B
- Output: Category NUMBER [ list of resources checked: line of code where
  each was assigned ]

## Task 5B: **Mandatory concurrent data structure validation**:

**CRITICAL**: This task catches use-after-free and data corruption bugs in
concurrently accessed data structures.

RCU (Read-Copy-Update) is the most common lock-free read pattern. It is
used in the Linux kernel, Open vSwitch, OVN, glibc, and liburcu-based
projects. Other patterns include hazard pointers, epoch-based reclamation,
and copy-on-write. All share the same core invariant: removal from lookup
structures must happen BEFORE deferred reclamation.

If the project uses any of these patterns:

- step concurrent.1: Identify the pattern used and its API
  - RCU: `call_rcu()`, `synchronize_rcu()`, `kfree_rcu()`,
    `ovsrcu_postpone()`, `urcu_call_rcu()`, or equivalent
  - Read-side: `rcu_read_lock()`/`rcu_read_unlock()`, or equivalent
  - Output: "Concurrent access pattern: [ name / API calls found ]"
- step concurrent.2: Identify what data structures the object is part of
  (hash tables, linked lists, trees, etc.)
  - Output: "Object in data structures: [ list ]"
- step concurrent.3: Verify removal from ALL lookup structures happens
  BEFORE the deferred-free call
  - Check: is removal done before or after `call_rcu()` / equivalent?
  - Output: "Removal location: [ before deferred-free / after / in callback ]"
- step concurrent.4: If removal is in the deferred callback:
  - This is the WRONG pattern -- flag as use-after-free
  - Readers can find the object via the lookup structure after the grace
    period starts but before removal, then the callback frees while
    readers are still accessing
  - Output: "RCU VIOLATION: removal in callback at [location]"
- step concurrent.5: Check for data accesses between lookup and reference
  acquisition
  - If there are field accesses before a reference count increment, these
    may NOT be protected against concurrent deletion
  - Output: "Accesses before refcount: [ list of field accesses ]"
- step concurrent.6: Verify read-side critical sections are properly
  bracketed
  - Are RCU-protected pointers accessed through the correct accessors
    (e.g., `rcu_dereference()`) inside read-side critical sections?
  - Are references held after exiting the read-side critical section
    only if a refcount was taken?
  - Output: "Read-side sections: [ correct / violation at location ]"
- step concurrent.7: Continue into Task 6a

If the project does NOT use lock-free patterns, skip to Task 6a.

## Task 5C: Consider caller/callee arguments:

- Some bugs are eliminated or triggered only with specific arguments
- How do the arguments used change any possible bugs?

## Task 6a: Loop control analysis

- Carefully examine loop control flow, especially when multiple loops are
  nested together
- Also consider goto/break/continue targets that alter loop flow
- Identify variables that control loop flow
- Identify inner loops that modify these variables
- Identify conditions that allow the loop to exit normally
- Identify functions not yet in context that control loop iteration and exit
  - Add to TodoWrite
  - **IMPORTANT** You will want to skip this step. Skipping this step will
    cause you to miss critical information that is needed to properly judge
    the safety of loop exit criteria. DO NOT SKIP THIS STEP.
- Pay extremely careful attention to conditions that restart or alter loop flow
  Example:
  ```
  start = some_val;
  while (current < limit) {
      current++;
      for (i = 0; i < SOME_COUNT; i++) {
          if (func())
              current = start;
      }
  }
  ```
- Output:
```
<FILENAME>:<FUNCTION> <loop description>
control variables
Additional functions identified for context reading [ list ]
exit conditions
```

- Load all functions added into TodoWrite that were not yet in context

## Task 6b: **Mandatory loop control flow validation**:

- step loop.1: Track what happens to resource-holding variables across loop
  iterations
- step loop.2: Assume all loops iterate multiple times, check pointer/handle
  assignments for leaks and logic errors
  - Pay attention to both outer and inner loops, make sure you trace both
- step loop.3: If references are reassigned without consuming/releasing the
  previous value, carefully consider potential leaks
  - Check the entire function context when references are reassigned,
    not just inner loops
- step loop.4: Compare loop exit conditions across parallel code paths
  (debug vs non-debug, error vs success) for consistency
  - Finding a single break inside a conditional path is not the same as
    checking all paths
- step loop.5: Continue into Task 7

## Task 7: **Initialization validation**

Step init.1:
  - For every function loaded into context, even if not changed by the patch
  - You MUST include callers and callees of modified functions
  - Output function name, random line
  - Check for variables and objects accessed without initialization
- Output: Category NUMBER [ list of variables properly initialized ]

## Task 8: Code Quality Checks

**MANDATORY - DO NOT SKIP THIS TASK**

1. Verify every comment in the diff matches actual behavior
   - Check EVERY comment for logic inversions (e.g., comment says "if true"
     but code checks "if !true")
   - Check EVERY comment for correct condition descriptions
   - Flag any mismatch between comment and code as a regression
2. Verify commit message claims are accurate
3. Question all design decisions -- require proof of correctness
4. Check naming conventions for new APIs
5. Check against language best practices and project conventions
6. Dead code and unused variables/functions are issues that should be reported
7. Check spelling and grammar in comments and commit messages
  - Don't flag capitalization unless it changes meaning
  - Only flag spelling or grammar mistakes that make sentences difficult
    to understand
8. If project-specific style guidelines are loaded, check added or modified
   code against those rules. Only flag new or modified lines, not
   pre-existing code.

## Task 9

Output: a one line description of potential regressions you found and ruled out.
For every potential regression ruled out:

```
Ruled out regression N: Task N <one sentence description>
```

Think about potential regressions that you found and ruled out, and consider
them against the RETRACTION RULE and REACHABILITY DISMISSAL sections at
the top of this prompt. Was it wrong to exclude them?

### Forward search for latent issues

For any ruled-out regression dismissed because the code path "isn't reachable
yet" or "no callers exist yet": patch series often add infrastructure in one
commit and wire it up later. A bug in the infrastructure is still a bug.

If a git range was provided, search forward in the series for commits that
enable the dismissed code path. If found, **reinstate the issue as confirmed**.

If no git range was provided, report the issue and note that a subsequent
commit may enable it. Do NOT dismiss solely because the current commit
doesn't trigger it.

While you were processing these potential bugs, did you ignore other
possible problems? Reconsider issues that might have been hidden by
focusing too heavily on issues you later ruled out.

- Did you fully analyze and complete Tasks 1-9 for every category? y/n
- Did you batch all tool calls to minimize API turns? y/n

This is a deep analysis, and correctness matters more than speed. Make sure
every step was fully executed.
