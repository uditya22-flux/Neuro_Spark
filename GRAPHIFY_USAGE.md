# Graphify developer workflow

Graphify is development-only. The checked command scans the narrow,
allowlisted DTO source tree and creates its graph under ignored `work/`:

```powershell
graphify extract backend/src/domain --code-only --no-cluster --force --out work/graphify-dto-boundary
graphify path "ChildExperience" "AdultExploratoryNoteDto" --graph work/graphify-dto-boundary/graphify-out/graph.json
```

The expected result is **No path found**. `backend/tests/architecture-boundary.test.ts`
is the automated equivalent. Do not graph a directory that includes data,
intake, telemetry, uploads, secrets, exports, generated graphs, or working
files. Do not commit `graphify-out`.
