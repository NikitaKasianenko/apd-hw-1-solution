# Agent worklog

Tool used: Claude (chat assistant). No secrets, tokens or private data were shared.
Full prompts are not included; each entry summarizes the task.

---

## Entry 1: Understanding the assignment

### Tool/agent task

Asked Claude to read the template repository (README, TASKS_AND_GRADES, source and tests)
and explain what has to be implemented and what the AI usage rules are.

### Output reviewed

An explanation of tasks 1–6, the bonus, and the disclosure rules in `README.md`.

### Accepted/rejected/revised decision

Accepted as a starting point. Checked it against `README.md` and `TASKS_AND_GRADES.md`.
Noted that the full course handout is not in the repository, so some details
(ordering, "first duplicate") are my interpretation and are listed under Risks in `PLAN.md`.

### Verification command/result

`swift test` on the untouched template: fails at `Implement StudyItem validation`, as expected.

### Artifact links

`PLAN.md` (Risks section).

---

## Entry 2: Explanations and example code for tasks 1–4

### Tool/agent task

Asked Claude to explain, step by step, how to implement:
`StudyItem` validation, custom `init(from:)` decoding, `StudyPlan.init` (duplicates and
title-then-ID sorting), `items(in:)`, `incompleteMinutes()` and `markCompleted(id:)`.

### Output reviewed

Explanations with example snippets for each method in `Sources/StudyPlanner/StudyPlanner.swift`,
including why synthesized `Codable` bypasses validation, how tuple comparison works in `sorted`,
and why `markCompleted` has to create a new `StudyItem` (`isCompleted` is `private(set)`).

### Accepted/rejected/revised decision

Revised. I typed the implementation myself, asked follow-up questions until I understood
each part (especially sorting and `filter`), and used a loop instead of `reduce` in
`incompleteMinutes()`. I chose `decodeIfPresent(...) ?? false` for `isCompleted`.

### Verification command/result

`swift test`: after `StudyItem` validation the run failed at the next placeholder
(`Implement plan validation`), as expected.

### Artifact links

`Sources/StudyPlanner/StudyPlanner.swift`

---

## Entry 3: Review of my implementation

### Tool/agent task

Pasted my own code into Claude and asked it to check whether it is correct.

### Output reviewed

Two bugs were found in my code:

1. `if estimatedMinutes < 0` accepted `0` minutes.
2. The sort compared `($0.title, $0.id) < ($1.id, $1.title)`, i.e. the right side was swapped.

### Accepted/rejected/revised decision

Accepted both findings after checking them by hand. Fixed to `<= 0` and to
`($0.title, $0.id) < ($1.title, $1.id)`. Style suggestions (spacing) were optional.

### Verification command/result

`swift test`: all three starter tests pass after the fixes.

### Artifact links

`PLAN.md` (Risks and `swift test` verification sections).

---

## Entry 4: Student tests

### Tool/agent task

Asked Claude to write at least six meaningful XCTest tests covering tasks 1–4.

### Output reviewed

A test file with 7 tests and two helpers (`makeItem`, `assertPlanError`):
minutes boundary, title-before-minutes precedence, JSON item validation,
keyed plan decoding with first duplicate ID, fixture decoding with ordering and queries,
title-then-ID ordering independent of input order, idempotent completion and unknown ID.

### Accepted/rejected/revised decision

Revised. Renamed the test class to `StudyPlannerPROTests`. Read every test and checked
the expected values against the fixture by hand (sorted IDs; 45 + 90 = 135 incomplete minutes).
The ordering and minutes tests would have caught the two bugs from Entry 3.

### Verification command/result

`swift test`: `Executed 10 tests, with 0 failures` (3 starter + 7 student).

### Artifact links

`artifacts/swift-test-output.txt`

---

## Entry 5: PLAN.md draft

### Tool/agent task

Asked Claude to draft `PLAN.md` based on the work done in this session.

### Output reviewed

Draft with Scope, Acceptance criteria, Implementation steps, Risks and verification notes.

### Accepted/rejected/revised decision

Revised. Asked to replace the verification table with a short list. Checked that the Risks
section matches the real mistakes and decisions from my work.

### Verification command/result

`swift test`: `Executed 10 tests, with 0 failures`.

### Artifact links

`PLAN.md`, `artifacts/swift-test-output.txt`
