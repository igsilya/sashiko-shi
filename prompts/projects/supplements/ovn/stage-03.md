# OVN: Execution Flow Supplements

OVN builds on OVS libraries, so the OVS stage supplements also apply.

- Same C conventions as OVS (C99/C11, 4-space indent, no tabs)
- Incremental Processing (I-P) engine: `engine_node` dependencies form a
  DAG; `engine_run()` processes nodes in dependency order
- I-P handler functions return true (handled incrementally) or false
  (needs full recompute); incorrect return value causes stale data
- Missing I-P node dependencies cause silent bugs where changes are not
  propagated
- Logical flow generation in northd: match/action strings must be
  syntactically valid OVN logical flow expressions
