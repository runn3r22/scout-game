# Judgement Agent — Memory Index

## Evaluation State (Supabase)
All structured evaluation data lives in Supabase, not here. S0 GP test schema in `supabase/schema.sql`. Three tables:

- `scout_submissions` — every submission attempt: status, snapshot, scoring, decision, points
- `projects` — one row per unique CA: dedup, latest score/action, accumulated notes
- `scout_points` — per-scout flat counters: total_points, submission_count, accepted_count, signal_count, trade_count

S1 will add `agent_memory` (intel summaries) and `token_performance` (FDV tracking) when integrated with main Fair Supabase. See `docs/future-ideas.md`.

## Self-Calibration Notes
Daily notes (`memory/YYYY-MM-DD.md`) for patterns observed across evaluations:
- Scoring calibration observations
- Tool reliability issues
- Narrative/meta trend observations
- Common submission patterns

These notes are for self-improvement between batches, not operational state.
