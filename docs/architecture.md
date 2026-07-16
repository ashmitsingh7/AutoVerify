# Architecture

AutoVerify is split into three layers that each do one job and talk to the
next one through a narrow, well-defined interface. Nothing "reaches through"
a layer to touch the one behind it.

```
┌─────────────────────────┐
│   Frontend (Next.js)     │  app/, components/, lib/
│   - RTL editor            │
│   - Analyze / Generate UI │
└────────────┬─────────────┘
             │ HTTP / JSON  (NEXT_PUBLIC_API_URL)
             ▼
┌─────────────────────────┐
│   Backend API (FastAPI)  │  backend/app/
│   - request validation    │
│   - job / zip management  │
│   - error -> HTTP mapping │
└────────────┬─────────────┘
             │ subprocess, JSON in/out
             ▼
┌─────────────────────────┐
│  bin/autoverify_bridge.pl │  Perl <-> JSON boundary
└────────────┬─────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│              AutoVerify Core (Perl, lib/AutoVerify/)      │
│                                                             │
│  Parser::parse_file        -> AST                          │
│         │                     (module name, params, ports) │
│         ▼                                                   │
│  Validation::validate(AST) -> diagnostics                  │
│         ▼                                                   │
│  PortClassifier::classify  -> clk/rst, stim/resp/inout      │
│         ▼                                                   │
│  Renderer::Heredoc.render_all -> { filename => content }    │
│         ▼                                                   │
│  Generator -> writes files, returns a summary hash          │
└─────────────────────────────────────────────────────────┘
```

## Why a Perl core behind a Python API

This project grew out of a university course on scripting languages and
verification methodology, where the original testbench generator was written
in Perl - a natural fit for the text-processing-heavy work of parsing
Verilog port lists and stitching together UVM-style templates. Rather than
rewrite that logic, the backend wraps it: FastAPI handles HTTP concerns
(validation, job bookkeeping, CORS, error mapping) and calls the existing
Perl pipeline as a subprocess through `bin/autoverify_bridge.pl`, which
exchanges a single JSON document in and out. The Perl core has no knowledge
of HTTP, and the API layer has no knowledge of Verilog syntax - the bridge
script is the only thing that speaks both.

## Layer responsibilities

| Layer | Location | Responsibility |
|---|---|---|
| Frontend | `frontend/` | Next.js UI for pasting/uploading RTL, viewing analysis results, triggering generation, and downloading the packaged testbench. |
| API | `backend/app/` | FastAPI routes, Pydantic request/response models, job-directory + zip lifecycle, mapping Core exceptions to HTTP status codes. |
| Bridge | `bin/autoverify_bridge.pl` | Thin JSON-in/JSON-out entry point invoked as a subprocess by the API layer. |
| Core | `lib/AutoVerify/` | Parsing, semantic validation, port classification, and template rendering - pure Perl, framework-agnostic, unit-tested independently of the API. |

## Core pipeline (Perl)

| Module | Responsibility |
|---|---|
| `AutoVerify::Parser` | Verilog/SystemVerilog ANSI header → AST. Throws `ParserError` on malformed input. |
| `AutoVerify::Validation` | Semantic checks on the AST. Returns diagnostics, never dies. |
| `AutoVerify::PortClassifier` | Clock/reset auto-detection; splits ports into stimulus/response/inout. |
| `AutoVerify::CodeGen` | The generator functions that produce each output file's content. |
| `AutoVerify::Renderer` (+ `::Heredoc`) | The interface `Generator` depends on, decoupling orchestration from template implementation. |
| `AutoVerify::Generator` | Orchestrates the full pipeline; the single entry point every frontend (CLI or API) calls. |
| `AutoVerify::Config` | Layered option resolution (defaults < caller-supplied options). |
| `AutoVerify::Logger` | Leveled, silent-by-default logging. |
| `AutoVerify::Error` (+ subclasses) | Structured exception hierarchy (`ParserError`, `ValidationError`, `GeneratorError`) so the API layer can map failures to precise HTTP status codes. |
| `AutoVerify::Simulator` (+ `Questa`/`VCS`/`Xcelium`) | Builds compile/run/regress command strings for common simulators. |
| `AutoVerify::Plugin::*` | Interface-only extension points for future parser/generator/renderer/simulator implementations. |

## API layer (FastAPI)

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness check. |
| `POST /validate` | Parses and validates RTL text; returns diagnostics only, writes nothing to disk. |
| `POST /analyze` | Returns module/port/parameter structure for inspection tooling. |
| `POST /generate` | Runs the full pipeline and packages the output as a zip; returns a `job_id`. |
| `POST /download` | Streams the zip for a given `job_id`. |

Each `/generate` call gets its own UUID-named job directory under
`backend/app/jobs/`, holding the input RTL, the generated `.sv` files, and
the packaged zip. Core exceptions map to `422` (the RTL was the problem);
unexpected failures map to `500`; an unknown `job_id` maps to `404`.

## Extension points

- **New HDL dialect** - implement `AutoVerify::Plugin::Parser`.
- **New output artifact** - implement `AutoVerify::Plugin::Generator`.
- **New templating engine** - implement the `Renderer` contract; `Generator.pm` never imports `CodeGen` directly.
- **New simulator** - implement the `Simulator` contract (`name`, `compile_cmd`, `run_cmd`, `regress_cmd`).
- **New frontend** - call `AutoVerify::Generator::generate($file, \%opts)` directly, or go through the FastAPI layer as this repository's frontend does.

## Known limitations

- No authentication or rate-limiting on the API - appropriate for a local/educational deployment, not for public exposure without adding them.
- Job storage is ephemeral (container filesystem); a redeploy drops in-flight job history, which is acceptable for a "generate then download promptly" workflow.
- The Perl bridge subprocess enforces a 30-second timeout per request.
