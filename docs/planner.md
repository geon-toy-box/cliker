---
project: cliker
package: cliker
org: com.secondsyndrome
created: 2026-06-22
status: planning
tags: [toybox, project, planner]
---

# cliker — Planner

> Master plan owned by the **Planner**. This is the single source of truth for
> what the product is and what work remains. Workers never edit this file; they
> write `docs/tasks/<id>/{dev,qa}.md`, and the Planner reflects verified results
> back here. Every status here must trace to evidence in a task's `evidence/`.

## Product vision
<!-- Filled via tiki-taka with the user. What are we selling, to whom, why? -->
LED 키보드 스트레스 해소 클릭커 키캡 앱 — 화면 속 기계식 키캡을 눌러 타건음·진동·LED로 스트레스를 해소하는 Android 앱

## Definition of "shippable"
<!-- The bar this product must clear before it can go to the store. -->
- [ ] Core user journey works end-to-end on a real Android device (smoke evidence)
- [ ] No crash on cold start, no network, denied permission, rotation
- [ ] Static analysis clean, test pyramid green, coverage ≥ threshold
- [ ] Store assets ready (icon, screenshots, listing copy)

## Milestones
| # | Milestone | Goal | Status |
|---|-----------|------|--------|
| M1 | <name> | <what "done" means> | TODO |

## Task backlog
> Statuses: TODO · IN_PROGRESS · BLOCKED · NEEDS_FIX · VERIFIED · DONE
> A task may only become VERIFIED via QA, and DONE only with a commit hash.

| id | title | milestone | depends on | status | verified-by |
|----|-------|-----------|------------|--------|-------------|
| T001 | <title> | M1 | — | TODO | — |

## Decisions log
<!-- Architecture/product decisions, dated, with the reasoning. Prevents re-litigating. -->
- 2026-06-22: Stack = Flutter (Android-only) + Riverpod. State mgmt chosen for testability and compile-time safety.

## Open questions (for the user)
<!-- Things the Planner needs the user to decide. Resolve via tiki-taka, then move to Decisions. -->
-

## Reflected results
<!-- Append-only. Each entry is the Planner's audited summary of a completed task,
     citing the qa.md verdict and commit it trusts. -->
