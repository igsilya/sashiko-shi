# OVN: Security Supplements

OVN builds on OVS libraries, so the OVS stage supplements also apply.

- OVN Northbound API is accessible to CMS (cloud management system);
  input validation is important for tenant isolation
- Logical flow match/action expressions are compiled and executed in the
  datapath; injection attacks via crafted logical flows are possible if
  input is not properly escaped
- ACL rules translate to logical flows; incorrect translation can create
  security policy bypasses
