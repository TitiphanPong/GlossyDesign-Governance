# GlossyDesign Governance V2

This repository is the versioned owner of the cross-repository Governance V2 documents for GlossyDesign.

The six governed files are:

- `AGENTS.md`
- `ARCHITECTURE.md`
- `DECISIONS.md`
- `PROJECT_RULES.md`
- `TODO.md`
- `WORKFLOW.md`

## Runtime source of truth

The active GlossyDesign workspace keeps working copies of these six files at the workspace root. `workspace-root/TODO.md` is the sole active execution backlog used by the approved Governance V2 TODO Runner. This repository versions that governance state; it must not introduce a second independent queue.

Legacy Frontend Codex queue workflows are disabled and retained only as migration history.

## Sync discipline

When governance changes in the active workspace:

1. update the workspace-root governance file first;
2. copy the six root governance files into this repository;
3. run `powershell -ExecutionPolicy Bypass -File scripts/check-drift.ps1 -WorkspaceRoot <path-to-glossy-design>`;
4. commit and push the governance repository after the report is clean.

The drift script is read-only. It reports file drift and Frontend/Backend SHA drift; it never mutates `TODO.md` or selects work.
