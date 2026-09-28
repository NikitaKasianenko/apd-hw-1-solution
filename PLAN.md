# Plan

## Scope

Implement the domain logic of the `StudyPlanner` package in
`Sources/StudyPlanner/StudyPlanner.swift`, replacing every `fatalError` placeholder.

In scope:

- `StudyItem` validation in `init` and in JSON decoding.
- `StudyPlan` validation (duplicate IDs) and deterministic ordering.
- JSON decoding of a keyed plan (`{"items": [...]}`) and of a top-level array.
- Queries: `items(in:)`, `incompleteMinutes()`.
- Mutation: `markCompleted(id:)`.
- At least six student tests in a separate test file.
- Optional bonus: `importMerging(_:)`.

Out of scope / constraints:

- The public API (type names, method signatures, error cases) stays unchanged.
- `Tests/StudyPlannerTests/StudyPlannerPublicTests.swift` stays unchanged.
- No new dependencies.

## Acceptance criteria

Validation (`StudyItem.init`):

- A title that is empty or whitespace/newlines only (`""`, `"  \n"`) throws `.blankTitle`.
- `estimatedMinutes` of `0` or less throws `.nonPositiveEstimatedMinutes`; `1` is accepted.
- If both title and minutes are invalid, `.blankTitle` is thrown (title is checked first).
- A valid title is stored unchanged (no trimming of the stored value).

Codable boundaries:

- Decoding a `StudyItem` from JSON runs the same validation as `init`.
- Decoding a `StudyPlan` from `{"items": [...]}` runs plan validation and ordering.
- `StudyPlan.decode(from:)` decodes a top-level JSON array (the fixture file) with the same validation.

Duplicates and ordering (`StudyPlan.init`):

- The first ID that repeats while scanning the input throws `.duplicateID(id)`.
  Example: IDs `a, b, a, b` → `.duplicateID("a")`.
- Items are sorted by `title`, then by `id` when titles are equal.
- The same set of items in any input order produces an equal plan.

Queries and completion:

- `items(in:)` returns only items of the given category, in plan order.
- `incompleteMinutes()` sums minutes of items where `isCompleted == false`
  (fixture: 45 + 90 = 135).
- `markCompleted(id:)` with an unknown ID throws `.unknownID(id)` and leaves the plan unchanged.
- Calling `markCompleted(id:)` twice for the same ID does not throw and does not change the plan.

Optional bonus (`importMerging`):

- Duplicate IDs inside the imported array throw and leave the plan unchanged.
- Existing IDs are replaced at their current positions.
- New IDs are appended in ascending ID order.
- The operation is atomic: on any error the plan is unchanged.

## Implementation steps

Each step: write or run a test, implement, run `swift test`, commit.

1. `StudyItem.init`: title check, then minutes check, then assign fields.
   File: `Sources/StudyPlanner/StudyPlanner.swift`.
2. `StudyPlan.init(items:)`: scan IDs with a `Set` to find the first duplicate,
   then sort by `(title, id)`.
3. `StudyItem.init(from:)` and `StudyPlan.init(from:)`: decode fields, then delegate
   to the validating initializers so decoding cannot bypass validation.
4. `StudyPlan.decode(from:)`: decode `[StudyItem]`, then call `StudyPlan(items:)`.
5. `items(in:)` with `filter`; `incompleteMinutes()` with a loop over incomplete items.
6. `markCompleted(id:)`: find the index with `firstIndex(where:)`, throw `unknownID` if missing,
   return early if already completed, otherwise replace the item with a copy where
   `isCompleted == true`.
7. Student tests in `Tests/StudyPlannerTests/StudyPlannerStudentTests.swift`.
8. Evidence: `swift test` output saved to `artifacts/`, `AGENT_WORKLOG.md` updated.
9. Optional: `importMerging(_:)`.

## Risks

- **Boundary at 0 minutes.** "Non-positive" includes `0`. An early version used `< 0`
  and accepted `0`; fixed to `<= 0` and covered by a test.
- **Decoding bypassing validation.** Synthesized `Codable` writes fields directly and skips
  `init`. Mitigation: custom `init(from:)` that delegates to the validating initializers.
- **Missing `isCompleted` in JSON.** Decision: `decodeIfPresent(...) ?? false`, matching the
  default value of `init`. The requirements do not state this explicitly.
- **Sorting details.** String comparison is case-sensitive (uppercase before lowercase,
  e.g. `"Zoo" < "apple"`). An early version compared `(title, id)` with `(id, title)`;
  fixed and covered by an ordering test.
- **Meaning of "first duplicate".** Interpreted as the first ID whose repeat is found while
  scanning the input from the start. Tests use `a, b, a, b`, where the expected result is `"a"`.
- **`isCompleted` has `private(set)`.** `StudyPlan` cannot set it directly, so completion
  creates a new `StudyItem` with the same values and `isCompleted: true`. The API stays unchanged.
- **Bonus vs. ordering.** The bonus keeps replaced items at their positions and appends new
  ones by ID, which does not match the title-then-ID ordering of `init`.
  Decision: TODO (record the chosen behavior here if the bonus is implemented).

## `swift test` verification

Command used for every run: `swift test`

- **2026-09-28, starter template:** fails at `Implement StudyItem validation`, as expected.
- **2026-09-28, after `StudyItem` validation:** fails at the next placeholder,
  `Implement plan validation`. Review found that `estimatedMinutes < 0` accepted `0`;
  changed to `<= 0`.
- **2026-09-28, after `StudyPlan.init`, Codable, queries and completion:** the three starter
  tests pass. Review found that the sort compared `(title, id)` with `(id, title)`;
  fixed to compare `(title, id)` on both sides.
- **2026-09-28, after adding student tests:** 10 tests (3 starter + 7 student), 0 failures.
  Output saved to `artifacts/swift-test-output.txt`.
