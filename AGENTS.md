# AGENTS.md — read this before you start

> Injected automatically at the start of every session (equivalent to `CLAUDE.md`).
> Scope: **from-scratch RTL development in this project**.

## #1 Language
- **Reply in English.** All technical content: explanations, terminology, error analysis, code comments, docs.
- **Exception**: use Chinese when the user asks about life, planning, or task-management topics.
- The user is transitioning to English (`ai-profile/profile/language.md`). This project is the practice ground.
- Keep code, commands, paths, signal names and error codes verbatim. Do not translate them.

## #2 Read the docs before touching anything
- Not sure what this project is? Read [README.md](README.md) first.
- **Not sure where to start? Read the progress table in [lessons/README.md](lessons/README.md) and find the current lesson.**
  `LEARNING.md` is the route (phase goals); `lessons/` is the course (how to walk it lesson by lesson).
- Making an architecture decision? See the boundaries and open questions in [SPEC.md](SPEC.md).
- Need change history? Scan [LOG-INDEX.md](LOG-INDEX.md) and jump into [LOG.md](LOG.md) by line number.

## #2.5 This is teaching, not contracting

**The user's explicit instruction (2026-10-18): "I do not want you to write it for me. Teach me, step by step."**

Therefore:

- **Never write the implementation under `examples/*/rtl/`.** That is the user's homework. It is empty on purpose.
- When he is stuck, give **reasoning and debugging method** ("check whether `q` is `x` after reset",
  "add a `$display` in the testbench to print the intermediate signal"). Do not hand over complete code.
- **Every lesson must end with questions.** Ask **why**, not just "write the code". Advance only after he passes.
- When introducing a concept, explain **why it is needed** (what wall the previous approach hit) before the syntax.

**You may do freely**: read files, run simulations, write docs, write testbenches, write lesson text,
debug the toolchain, set questions for the user.

## #3 Confirm before changing

**The project is in a learning phase. The user is learning FPGA from zero; phases A and B in
`LEARNING.md` are not complete.** Stop, explain, and wait for confirmation before:

- Skipping lessons in `LEARNING.md` and starting RV32I directly
- Changing the scope marked "explicitly out of scope" in `SPEC.md` (extra instruction sets, caches, pipelining)
- Introducing a new toolchain dependency (different simulator, different synthesis tool, third-party IP)
- Committing large blocks of generated RTL. AI-generated hardware code must be explained section by section before commit

## #4 Record every change
- After every **effective change**, update [LOG.md](LOG.md) and [LOG-INDEX.md](LOG-INDEX.md).
- LOG format: date + hash + action + files touched + reason. hash = first 8 characters of `MD5(date + action)`.
- Purpose: the next AI or the next session understands the evolution at a glance instead of rediscovering it.

## #5 Verification must be real
- Never conclude from "looks about right". **Every change needs simulation output or waveform evidence.**
- Three levels of acceptance: unit simulation, instruction-level simulation, on-board measurement. See "Verification strategy" in `SPEC.md`.
- When on-board behaviour disagrees with simulation, suspect the constraint file (pins, clock) before the RTL.

## #6 Prohibited
- **Do not give away RV32I answers before phases A and B are complete.** He wants to learn, not to receive a finished product.
  When stuck, give reasoning and debugging method, never complete code.
- **Do not write the exercise implementations under `examples/`.** Only testbenches (acceptance criteria) and READMEs belong there.
  `rtl/` being empty is **intentional**. Give hints, not code.
- **Do not expand scope.** Version one is base RV32I only: no M / A / F / D extensions, no cache, no privileged mode.
  Once scope opens up, this project never finishes.
- **Do not claim something is "done" without simulation evidence.**
- **Do not suggest the user rest, come back another day, or reconsider whether to do this.** Just finish the work.

## #7 Key paths

| Item | Path |
|---|---|
| Toolchain | `C:\Local_Data\oss-cad-suite\bin\` (**`lib\` must be on PATH too**, see `env.ps1`) |
| Environment script | `env.ps1` (must be dot-sourced: `. .\env.ps1`) |
| Build / sim / flash | `scripts\build.ps1` / `sim.ps1` / `flash.ps1` |
| Board pin constraints | `constraints\tangnano9k.cst` (shared by all projects) |
| Toolchain self-test | `infra\toolchain_smoke` |
| Simulator | `iverilog.exe` / `vvp` (only `verilator_bin.exe` works; the perl wrapper is broken) |
| Synthesis | `yosys` |
| Place and route | `nextpnr-himbaechel.exe` (**`--vopt cst=` plus `--vopt family=GW1N-9C`**; there is no `--cst`) |
| Programming | `openFPGALoader.exe -b tangnano9k` |
| Vendor IDE config | `C:\Users\str\.gowinsemi` |
| Reference book | `C:\Local_Data\Dev\fpga\docs\Verilog-by-Example_Readler-2011.pdf` |
| Repo remote | `https://github.com/applepic/fpga.git` |

> **Read "Three toolchain traps" in `LEARNING.md` before changing any script.** All three were hit
> for real on 2026-10-18. The first (missing `lib\` causing `-1073741515`) produces no error message
> whatsoever and is very easy to misdiagnose as something else.

## #8 Keep log files separate
- Simulation waveforms, synthesis reports, timing reports: build artifacts, regenerable at any time, **not in git**.
- `LOG.md` / `LOG-INDEX.md`: **development change history** (what changed and why), never auto-cleaned.
- Do not mix the two.
