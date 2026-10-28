# AGENTS.md — read this before you start

> Injected automatically at the start of every session (equivalent to `CLAUDE.md`).
> Scope: **from-scratch RTL development in this project**.

## #1 Language
- **Reply in English.** All technical content: explanations, terminology, error analysis, code comments, docs.
- **Exception**: use Chinese when the user asks about life, planning, or task-management topics.
- The user is transitioning to English (`ai-profile/profile/language.md`). This project is the practice ground.
- Keep code, commands, paths, signal names and error codes verbatim. Do not translate them.

**Course text is bilingual (2026-10-28).** Lesson files under `lessons/` carry English as the primary
text with Chinese following each paragraph as a blockquote. When writing or editing a lesson:
- English first and complete on its own; Chinese is a per-paragraph translation, not a summary
- Do not translate code, signal names, commands, error messages or file paths
- Tables may carry both languages in one cell, separated by `/`
- Docs outside `lessons/` (SPEC, LEARNING, AGENTS, README, LOG) stay **English only**

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

### #2.6 He has zero PowerShell background (2026-10-28)

Every command shown to him must be **split into command and arguments, with one line saying what it
does**. Do not paste a bare command block and assume it is self-explanatory.

- Name the command and say what kind of thing it is: `New-Item` is the command, `-ItemType Directory`
  is a parameter telling it to make a folder, the path is the target
- Give the Unix equivalent when one exists (`New-Item -ItemType Directory` = `mkdir`, `. .\x.ps1` =
  `source`), because that is the vocabulary he will meet in EEC 170/180
- If a command has a non-obvious piece of syntax, explain that piece. `. .\env.ps1` has two dots and
  they are **not** a pair: the first is the dot-source operator, the second is part of `.\`

**The project uses PowerShell only. Do not tell him to use Git Bash** for project work. Git for
Windows ships an MSYS2 bash (`C:\Program Files\Git\bin\bash.exe`) but it has no `make`, and mixing
two environments produces "command not found" noise unrelated to the circuit he is writing.

### #2.7 Where his questions live and how to answer them (2026-10-28)

**The lesson text he actually reads is the vault copy, not the repo copy.**

| Copy | Path | Role |
|---|---|---|
| Repo | `lessons/NN_*.md` | Source of truth for the course structure |
| Vault | `C:\Local_Data\Obsidian\01_Projects\FPGA\Lesson-NN-*.md` | The copy he reads and writes questions into |

**Read the whole vault file every turn, not just the tail.** On 2026-10-28 he inserted ten questions
mid-document and only the bottom one was answered, because only the tail was read. He had to point
this out twice.

Answers are inserted **in place**, in a folded callout, in this shape:

```markdown
> [!question]- 提问 · one-line summary
> **原话**
> his exact words, copied unchanged
>
> **整理**
> a cleaned-up restatement with the symbols fixed
>
> **回答**
> the answer
```

- **原话 is copied verbatim**, including profanity and full-width punctuation. Editing it destroys
  the record of where he actually got stuck
- **整理 fixes symbols and wording, not meaning**: `！v` becomes `!v`, `这个4'` becomes `4'b1100`,
  `一个v` becomes 一个 `.v` 文件
- **整理's language follows 原话.** Mixed-in English means an English restatement; pure Chinese means
  a Chinese restatement. Never translate an English technical term into Chinese
- **The answer stays where the question is.** Do not collect them into a summary section at the end

**When a question exposes a defect in the lesson, fix the lesson and say so in the answer.** Two
examples from 2026-10-28: the "numbers carry their width" section sat *after* the operator table that
used `4'b1100`, and the phrase "the lesson text warns about this" was left with nothing to point at.
Both were admitted as my errors in the answer, and the section order was corrected.

**Also append a `LOG.md` row for every effective change made in response**, following #4.

## #3 Confirm before changing

**The project is in a learning phase. The user is learning FPGA from zero; phases A and B in
`LEARNING.md` are not complete.** Stop, explain, and wait for confirmation before:

- Skipping lessons in `LEARNING.md` and starting RV32I directly
- Changing the scope marked "explicitly out of scope" in `SPEC.md` (extra instruction sets, caches,
  privileged mode, branch prediction, CSR file)
- Introducing a new toolchain dependency (different simulator, different synthesis tool, third-party IP).
  **There is no cross compiler and no C in this project by design** (decided 2026-10-28): test
  programs are written in a small assembly language and translated by a Python assembler the user
  writes. Do not propose installing `riscv-none-elf-gcc` or writing C without asking first
- Committing large blocks of generated RTL. AI-generated hardware code must be explained section by section before commit

> **Pipelining is no longer an open boundary.** It was confirmed with the user on 2026-10-28 and is
> now phase D in `SPEC.md` and `LEARNING.md`. What is still out of scope inside phase D: dynamic
> branch prediction, CSR, interrupts, and chasing Fmax past the target.

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
- **Do not expand scope.** The scope is base RV32I (40 encodings, 38 implemented behaviours) as a
  single-cycle core and then a five-stage pipeline. No M / A / F / D extensions, no cache, no
  privileged mode, no CSR, no branch prediction, no interrupts.
  Once scope opens up, this project never finishes.
- **Do not write phase D before phase C passes in simulation.** The single-cycle core is the oracle;
  without it there is nothing to compare the pipeline against.
- **Do not claim something is "done" without simulation evidence.**
- **Do not suggest the user rest, come back another day, or reconsider whether to do this.** Just finish the work.

## #7 Key paths

| Item | Path |
|---|---|
| Toolchain | `C:\Local_Data\oss-cad-suite\bin\` (**`lib\` must be on PATH too**, see `env.ps1`) |
| Environment script | `env.ps1` (`. .\env.ps1`; the dot is recommended, **not** required for PATH. See the file header for the measured reason) |
| Build / sim / flash | `scripts\build.ps1` / `sim.ps1` / `flash.ps1` |
| Formal proof | `scripts\formal.ps1` (**reads `formal\props_*.v` + `rtl\*.v`, writes `build\formal\`**) |
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
