========================
sashiko-shi (刺し子師)
========================

An 11-stage agentic code review pipeline for `OpenCode <https://opencode.ai/>`_,
implementing the `Sashiko <https://sashiko.dev/>`_ review protocol.

Mostly for Linux Kernel, but suitable for any other project as well.

**Sashiko** (刺し子, "little stabs") is a form of decorative reinforcement
stitching from Japan.  **Sashiko-shi** (刺し子師) is the artisan who performs
the stitching -- this project is your local sashiko artisan, running a similar
multi-stage review protocol on your machine via OpenCode.


Quick Start
===========

::

    # Clone this repo
    git clone --recursive https://github.com/igsilya/sashiko-shi.git

    # Install into your project (arguments are optional, except the path)
    cd sashiko-shi
    ./install.sh /path/to/project

    # Run OpenCode and review a commit
    cd /path/to/project
    opencode
    /sashiko-shi HEAD

After updating sashiko-shi (``git pull``), re-run ``install.sh`` to update.


Usage
=====

::

    /sashiko-shi HEAD          # review a single commit
    /sashiko-shi HEAD~3        # review the commit at HEAD~3
    /sashiko-shi abc1234       # review a specific commit
    /sashiko-shi -6            # review the last 6 commits (in parallel)
    /sashiko-shi HEAD~6..HEAD  # review a range of commits
    /sashiko-shi -6 --parallel=3   # limit to 3 concurrent reviews
    /sashiko-shi -6 --parallel=1   # sequential (one at a time)

For multi-commit reviews, each commit is reviewed independently through
the full pipeline, then findings are reconciled across the series.
By default, all commits are reviewed in parallel.  Use ``--parallel=N``
to limit concurrency.

Review output is written to ``.sashiko-shi/`` and printed to the
conversation.


What It Does
============

Runs a structured 11-stage review of code patches, where each stage is a
specialized AI agent focusing on a different class of issues:

=====  ===========================  ==========================================
Stage  Name                         Focus
=====  ===========================  ==========================================
1      Commit goal analysis         Architecture, UAPI, backwards compatibility
2      Implementation verification  Code vs. commit message, API contracts
3      Execution flow               Control flow, NULL derefs, error paths
4      Resource management          Leaks, UAF, double free, refcounting
5      Locking & synchronization    Deadlocks, races, RCU violations
6      Security audit               Overflows, TOCTOU, privilege escalation
7      Hardware review              Registers, DMA, IRQ, memory barriers
8      Deduplication                Merge overlapping findings from 1-7
9      Conflict resolution          Reconcile concerns vs. dismissed concerns
10     Verification & severity      Validate against code, assign severity
11     Report generation            Plain-text inline review for mailing lists
=====  ===========================  ==========================================

Stages 1-7 run **in parallel**.  Stages 8-11 run sequentially, with early
exit if no concerns survive.


Supported Projects
==================

The pipeline works with **any project and programming language**.  For
recognized projects, it loads additional domain-specific knowledge:

===============  ========  ====================================
Project          Status    Subsystem Guides
===============  ========  ====================================
Linux kernel     Ready     Full (via review-prompts submodule)
Open vSwitch     Skeleton  Generic + OVS-specific patterns
OVN              Skeleton  Generic + OVN-specific patterns
Any other        Ready     Generic review (auto-detected)
===============  ========  ====================================

Project detection is automatic.  Unrecognized projects use the generic
skill, which provides language-agnostic analysis covering resource
management, concurrency, security, and common bug patterns.


Installation
============

::

    ./install.sh [OPTIONS] <target-repo>

Options:

``--provider=<name>``
    Configure timeouts for the named LLM provider to prevent stream
    hangs that can occur during long multi-commit reviews.  Can be
    specified multiple times.

``--model=<id>``
    Model for analysis stages and series coordination.
    Requires ``--small-model``.

``--small-model=<id>``
    Model for orchestration, pre-screening, and planning.  Using a
    smaller model for these less reasoning-intensive tasks can save
    15-20% on review cost.  Requires ``--model``.

If neither ``--model`` nor ``--small-model`` is given, all agents
inherit the default model.

Examples::

    # Minimal install (no provider config, inherits default model)
    ./install.sh /path/to/project

    # With provider timeouts and cost optimization
    ./install.sh --provider=google-vertex-anthropic \
        --model=google-vertex-anthropic/claude-opus-4-6@default \
        --small-model=google-vertex-anthropic/claude-sonnet-4-6@default \
        /path/to/project

    # Uninstall
    ./uninstall.sh /path/to/project

The installer copies agents, commands, and skills into
``<project>/.opencode/``, sets ``subagent_depth: 3`` in
``opencode.json``, and adds a reference to the sashiko-shi clone.

The generated files contain absolute paths and should not be committed
to git.  Add to your ``.gitignore``::

    .opencode/agents/sashiko-shi*.md
    .opencode/commands/sashiko-shi.md
    .opencode/skills/kernel/
    .opencode/skills/ovs/
    .opencode/skills/ovn/
    .opencode/skills/generic/
    .sashiko-shi/


How It Works
============

The pipeline is implemented as a set of OpenCode agents:

- ``sashiko-shi`` -- series coordinator, enumerates commits and invokes
  the orchestrator for each one individually
- ``sashiko-shi-orchestrator`` -- single-commit pipeline, invokes stage agents
- ``sashiko-shi-prescreen`` -- selects relevant subsystem guides
- ``sashiko-shi-planner`` -- determines which stages 4-7 to run
- ``sashiko-shi-stage-01`` through ``sashiko-shi-stage-11`` -- the stages

For each commit, the orchestrator invokes stages 1-7 in parallel (multiple
Task tool calls in one message), then stages 8-11 sequentially.  Each stage
returns structured JSON.  The final stage produces a plain-text review report.

For multi-commit series, each commit is reviewed in a separate orchestrator
session to prevent batching.  After all commits are reviewed, the series
coordinator performs lightweight reconciliation: bugs introduced by individual
commits are always retained, while pre-existing or style issues fixed by later
commits in the series may be dismissed.


Output
======

All output is written to the ``.sashiko-shi/`` directory in your project root:

``review-inline-<sha>.txt``
    Per-commit review report, formatted as a mailing list reply with
    inline code comments.

``review-metadata-<sha>.json``
    Per-commit machine-readable metadata (severity, issue count, commit info).


Cost Report
===========

A script is included to report token usage and cost for review sessions::

    python3 ~/sashiko-shi/scripts/cost-report.py

    # Specific session
    python3 ~/sashiko-shi/scripts/cost-report.py <session-id>

    # Last 3 sessions
    python3 ~/sashiko-shi/scripts/cost-report.py --last 3

The report shows total cost, cost by level (coordinator, orchestrators,
stages), and cost per commit with duration and issue count.

Note: this script queries OpenCode's internal SQLite database directly.
The database schema is not a public API and may change between OpenCode
versions, which could break the script.


Adding a New Project
====================

1. Create a skill file at ``skills/<project>/SKILL.md`` with project detection
   triggers and configuration paths.

2. Optionally create subsystem guides in ``prompts/projects/`` following the
   same format as the kernel guides in
   ``third_party/review-prompts/kernel/subsystem/``.

3. Re-run ``./install.sh <target-repo>`` to pick up the new skill.

See ``skills/ovs/SKILL.md`` for a skeleton example.


Repository Structure
====================

::

    sashiko-shi/
    +-- agents/              # OpenCode agent definitions (stages + main)
    +-- commands/            # /sashiko-shi slash command
    +-- skills/              # Project skills (kernel, ovs, ovn, generic)
    +-- prompts/             # Shared prompt files
    |   +-- shared-context.md
    |   +-- severity.md
    |   +-- technical-patterns-generic.md
    |   +-- callstack-generic.md
    |   +-- false-positive-guide-generic.md
    |   +-- inline-template-generic.md
    |   +-- projects/        # Project-specific supplements
    +-- third_party/
    |   +-- review-prompts/  # Git submodule: masoncl/review-prompts
    +-- scripts/
    |   +-- cost-report.py   # Token usage and cost reporting
    +-- install.sh
    +-- uninstall.sh
    +-- LICENSE              # Apache 2.0
    +-- NOTICE               # Attribution for Sashiko and review-prompts
    +-- AUTHORS              # Project contributors
    +-- README.rst


Attribution
===========

This project implements a review protocol derived from the
`Sashiko <https://github.com/sashiko-dev/sashiko>`__ project, an agentic Linux
kernel code review system created by the Linux Foundation and its contributors.
The 11-stage protocol, concern/dismissed-concern architecture, severity
calibration, and report format are adapted from Sashiko's review pipeline.
Sashiko is licensed under the Apache License, Version 2.0.

Per-subsystem review prompts are provided by Chris Mason's
`review-prompts <https://github.com/masoncl/review-prompts>`_ project, included
as a Git submodule.  The generic review guides (technical-patterns, callstack
analysis, false-positive verification, and report formatting) are derived from
the kernel-specific originals in review-prompts.  review-prompts is licensed
under the MIT License.

See `NOTICE <NOTICE>`_ for full attribution details.


License
=======

Licensed under the Apache License, Version 2.0.  See `LICENSE <LICENSE>`_.
