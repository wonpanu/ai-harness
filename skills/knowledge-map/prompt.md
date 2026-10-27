# Repository mapping run

You are mapping ONE repository, the current working directory, for a machine-local knowledge map that other sessions read before they plan a change. This is a read-only, single-pass job.

Rules for this run:

- Skip harness-mode, playbooks, todo lists and every other workflow skill. Do not ask questions. Do not stop early for permission.
- Read only. Never edit, create or delete a file. Never run a build, a test suite, a package manager or a network call.
- Use the repository's own `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `README*`, `docs/` and `CONVENTIONS*` as input first, then confirm against the code, manifests, Dockerfiles, CI, infrastructure and config files. Package manifests, env examples, queue and table names, URLs and deploy descriptors are where the edges to other systems are.
- Tag every claim: `(observation)` when you saw it in a file, `(inference)` when you deduced it, `(unknown)` when you could not tell. Cite `path:line` for every dependency line and every edge.
- A vendored binary, minified bundle, generated client or anything without source goes under `## Unknowns` with its path. Do not try to reverse engineer it in this run.

Output: markdown only, no preamble, no closing remarks, starting with the first heading. Use exactly these sections in this order:

```
## What it is
One paragraph: purpose, who calls it or uses it, where it runs.

## Stack and entry points
Language, framework, runtime, how it starts (main files, handlers, cron, Lambda, CLI), cited.

## Depends on
One line per external thing this repo needs at runtime or build time: other repos or services it calls, queues or topics it consumes, databases, tables, buckets, third-party APIs, shared libraries. Each line cites `path:line` and carries a tag.

## Provides
One line per thing other systems take from this repo: HTTP or gRPC endpoints, events it publishes, tables it owns, libraries it exports, images or artifacts it builds. Cited and tagged.

## Config that names other systems
Env vars, config keys and infrastructure resources whose value is another system (a URL, a queue name, a table, a bucket, a secret name). One line each, cited.

## Unknowns
What you could not determine and why, including paths of vendored or generated code.

## Flow

## Edges
```

The `## Flow` section holds exactly one fenced ```json block containing an object `{"components": [...], "flows": [...]}`, and nothing else. It is the inside of this repository: which runnable parts exist and how data moves between them, the queues and stores they touch, and the systems outside the repo.

- `components`: one object per runnable part. `id` is its directory relative to the repo root (`worker/spider`, `service/idaccount`, `bff`; `.` for a single-program repo). `kind` is one of `web`, `bff`, `service`, `worker`, `cron`, `lambda`, `lib`. `entry` is the main file as `path:line`. `does` is one short clause.
- `flows`: one object per hop. `from` and `to` are a component id or a resource id in the same vocabulary as Edges (`rabbitmq:spider:messages`, `mongo:influencer-directory.posts`, `api:gemini`, a sibling repository's basename). Direction is the direction the data moves: a queue a component consumes goes `from` the queue `to` the component; a queue it publishes goes `from` the component `to` the queue; a store it reads is the `from`; a store it writes is the `to`; an HTTP or gRPC call goes `from` the caller `to` the callee. `kind` is one of `consumes`, `publishes`, `reads`, `writes`, `calls`. `via` is the env var or config key whose value names the queue, table or URL. `evidence` is `path:line`.
- Take queue, exchange, topic, table, bucket and URL names from where they are set: `.env*` files, config defaults, Helm or Kubernetes manifests, Terraform, SAM or serverless templates. When a publisher and a consumer inside this repo name the same queue, both hops use the same resource id so the chain reads end to end.
- A single-program repo still lists one component. Only hops you can cite go here; a hop you suspect goes under `## Unknowns`.

The `## Edges` section holds exactly one fenced ```json block containing a JSON array of edge objects, and nothing else. Each object has these keys:

- `from`: this repository's directory basename, always.
- `to`: the other repository's directory basename when you can tell it is a sibling repository on this machine (match the name used in its README, go.mod, package.json or deploy descriptor); otherwise a stable external id such as `sqs:order-events`, `postgres:projects`, `s3:assets-bucket`, `api:zocialeye`.
- `kind`: one of `calls`, `publishes`, `consumes`, `reads`, `writes`, `deploys`.
- `via`: the queue, topic, table, URL, env var or resource name that carries the relationship.
- `evidence`: `relative/path:line` of the strongest citation.

An empty array `[]` is a valid answer for a repository with no outward relationships. Keep the whole output under 320 lines; the Flow block is the part that may grow.
