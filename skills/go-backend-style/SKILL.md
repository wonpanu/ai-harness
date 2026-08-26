---
name: go-backend-style
description: Go backend code-style rules distilled from production BFF services — guard-clause error ladders, descriptive naming, initialism casing, layering, why-comments. Use when writing or reviewing Go code: services, handlers, usecases, repos, or any .go file.
---

# Go backend style

Project CLAUDE.md/CONVENTIONS.md wins over anything here.

Concrete avoid/prefer code for every rule: see [EXAMPLES.md](EXAMPLES.md) — read it when a rule alone is ambiguous or before reviewing unfamiliar code.

## Control flow

- Guard clauses + early return; never `else` after a returning branch.
- Error handling is a flat ladder of independent `if` guards (transport err → 404 → non-200 → nil body), each returning immediately, never nested.
- Precompute a named boolean (`isExpress := ...`) and branch on it; never re-test the condition inline.

## Naming

- Descriptive, unabbreviated names even when long (`maximumRefundAmount`, not `maxAmt`).
- Short names only for tight scope: loop vars, single-letter receivers (`h` handler, `u` usecase, `r` repo).
- Go initialism casing: `ID`, `URL`, `API`. Exception: wire-mirror structs match upstream JSON casing verbatim.
- Mappers on the response type: `ToXxxEntity` / `ToXxxEntities`.

## Layering

- Strict one-direction flow (e.g. handler → usecase → repo); DI through constructors wired in `main`.
- Handler: param extraction + validation + status mapping. Usecase: business rules + entity mapping. Repo: transport + status classification only.
- Constructors `NewXxx` return the interface, not the struct; concrete impls unexported.
- One file per method for large types; repo splits `_request.go` / `_response.go` / impl.

## Errors & observability

- Follow the project's error-value pattern (typed error codes, compare helpers) — don't invent `fmt.Errorf("%w")` chains where the codebase uses coded errors.
- Every method opens with the project's tracing boilerplate (span named `Type/Method`) when the codebase does; every error branch records to the span.
- Handlers respond only through the shared response helpers, never hand-rolled payloads.

## Comments & tests

- Comments explain why (rationale, workaround, constraint) in lowercase fragments — never what the next line does.
- Godoc only on exported symbols whose rule isn't visible in the signature.
- Tests: external test package, `t.Run("should …")` subtests, Arrange/Act/Assert markers, tiny local helpers (`intPtr`) over inline noise.
