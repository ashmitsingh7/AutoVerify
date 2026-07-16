# AutoVerify Core — Architecture

## Pipeline

```
verilog_file
     |
     v
Parser::parse_file          -> AST (module_name, params, ports, cleaned_source)
     |                            throws ParserError on malformed input
     v
Validation::validate(AST)   -> [ diagnostics ]  (never dies)
     |                            Generator turns severity=error diagnostics
     |                            into a thrown ValidationError; warnings are
     |                            logged and generation proceeds
     v
PortClassifier::classify    -> clk/rst detection, stim/resp/inout split
     |
     v
Renderer::Heredoc.render_all -> { filename => content, ... }
     |                            (Generator depends on the Renderer
     |                             interface only, never on CodeGen directly)
     v
Generator writes files, returns a summary hash
     |
     v
bin/gen_tb.pl prints the human-readable report (unchanged from original)
```

## Module responsibilities

| Module                         | Responsibility                                                        |
|---------------------------------|-------------------------------------------------------------------------|
| `AutoVerify::Parser`            | Verilog/SV ANSI header -> AST. Throws `ParserError`.                    |
| `AutoVerify::Validation`        | Semantic checks on the AST. Returns diagnostics, never dies.             |
| `AutoVerify::PortClassifier`    | clk/rst auto-detect + overrides; stim/resp/inout split.                  |
| `AutoVerify::CodeGen`           | The 9 pure `context -> string` generator functions (unchanged logic).    |
| `AutoVerify::Renderer` (+`::Heredoc`) | Interface Generator depends on; current impl wraps CodeGen.        |
| `AutoVerify::Generator`         | Orchestrates the pipeline above; the one entry point every frontend calls. |
| `AutoVerify::Config`            | Layered option resolution (defaults < caller opts < future config file). |
| `AutoVerify::Logger`            | Leveled, silent-by-default logging; `--verbose` on the CLI raises it.    |
| `AutoVerify::Error` (+ subclasses) | Structured exception hierarchy; every library `die` goes through here. |
| `AutoVerify::Simulator` (+ backends) | Command-string construction for Questa/VCS/Xcelium. Questa's shape is verified against the existing `run_sim.tcl`/`Makefile` flow; VCS/Xcelium are unverified best-effort (no such simulator installed here). |
| `AutoVerify::Plugin::*`         | Interface-only extension points (Parser/Generator/Renderer/Simulator). No implementations exist yet - these exist so a future plugin can be written without editing core files. |
| `bin/gen_tb.pl`                 | Thin CLI: ARGV -> `AutoVerify::Generator::generate()` -> stdout report.  |

## Extension points

- **New HDL dialect** → implement `AutoVerify::Plugin::Parser` (`can_parse`, `parse`).
- **New output artifact** → implement `AutoVerify::Plugin::Generator` (`additional_files`).
- **New templating engine** → implement `AutoVerify::Renderer`'s `render_all(%ctx)` contract and point `Generator.pm` at it (one-line swap; it never imports `CodeGen` directly).
- **New simulator** → implement `AutoVerify::Simulator`'s `name`/`compile_cmd`/`run_cmd`/`regress_cmd` contract.
- **New frontend** (FastAPI, VS Code extension, GitHub Action) → call `AutoVerify::Generator::generate($file, \%opts)` and consume the returned hash (`outdir`, `ast`, `classified`, `files`, `diagnostics`). This is the only integration surface; nothing else in `lib/` is meant to be called directly by a frontend.

## Error handling

All library `die`s are `AutoVerify::Error` objects (or a subclass: `ParserError`, `GeneratorError`, `ValidationError`), each carrying `file`/`line`/`column`/`message`/`suggestion` and stringifying to a single readable line, so `bin/gen_tb.pl`'s existing "just let it propagate and print `$@`" behavior is unchanged for end users, while a future backend can catch by type and return structured JSON instead.

## What Phase 2 deliberately did not do

- **Plugin implementations** — interfaces only, per the brief. No Parser/Generator/Renderer/Simulator plugin exists yet.
- **JSON/YAML config file support** — `Config::resolve` accepts an arbitrary list of hash layers already, so adding a file-backed layer later is additive; wiring an actual file parser wasn't done because there's no consumer for it yet (CLI only).
- **A second Renderer implementation** — the interface exists and `Generator.pm` only depends on it, but writing a Template::Toolkit/Jinja renderer with no frontend to drive it yet would be speculative work with nothing to test it against.
- **Diagram suites / call graphs** — this single markdown file (pipeline diagram + responsibility table + extension points) covers what a contributor actually needs; a project this size doesn't benefit from a separate class-diagram deck.

## Contribution / dev setup

```bash
# no external deps - core Perl only
cd autoverify
perl t/01_parser.t                       # or any t/*.t individually
for f in t/*.t; do perl "$f" || echo "FAILED: $f"; done   # full suite
perl bin/benchmark.pl                    # throughput check
perl bin/gen_tb.pl examples/counter.v --outdir=/tmp/x --verbose
```

Golden-output rule: any change to `CodeGen.pm` or a `Renderer` must keep
`t/03_regression_vs_original.t` passing (byte-identical output against the
`baseline/` captured from the original monolithic script), unless the
change is an intentional, documented output change - in which case that
test's expectations must be updated in the same commit, explaining why.
