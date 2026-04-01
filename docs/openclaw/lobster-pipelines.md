# Lobster — OpenClaw's Deterministic Pipeline Engine

> Source: dev.to/ggondim — deterministic multi-agent dev pipeline

---

## What is Lobster

Lobster is OpenClaw's declarative pipeline runtime for **deterministic execution**. Steps run sequentially and data flows as JSON between them. Unlike LLM-driven agent decisions, Lobster steps are predictable shell commands.

Use case for Judgement Agent: **Step 1 (Structural Filter)** is pure conditional logic — no LLM needed. Perfect for Lobster.

---

## Basic YAML Structure

```yaml
name: workflow-id
steps:
  - id: step-name
    command: shell-command
```

---

## OpenClaw Tool Invocation from Pipeline

```yaml
- id: notify-agent
  command: >
    openclaw.invoke --tool agent-send --args-json '{
      "agentId": "reviewer",
      "message": "Please review",
      "sessionKey": "pipeline:project-a:reviewer"
    }'
```

---

## Sub-Workflow Steps with Loop Support

```yaml
- id: code-review-loop
  lobster: ./code-review.lobster
  args:
    project: ${project}
    task: ${task}
  loop:
    maxIterations: 3
    condition: '! echo "$LOBSTER_LOOP_JSON" | jq -e ".approved"'
```

Loop environment variables: `LOBSTER_LOOP_STDOUT`, `LOBSTER_LOOP_JSON`, `LOBSTER_LOOP_ITERATION`.
Exit code 0 continues looping; non-zero exits.

---

## Data Flow Between Steps

```yaml
stdin: $previous-step.stdout
condition: $parse.json.approved == true
```

---

## LLM Task Integration with JSON Schema Validation

```yaml
- id: parse-review
  command: >
    openclaw.invoke --tool llm-task --action json --args-json '{
      "prompt": "Extract approval decision",
      "schema": {
        "type": "object",
        "properties": {
          "approved": {"type": "boolean"},
          "feedback": {"type": "string"}
        },
        "required": ["approved", "feedback"]
      }
    }'
```

---

## Conditional Execution with Approval Gates

```yaml
condition: $code-review-loop.json.approved == true
approval: required
```

---

## Multi-Agent Session Routing

```yaml
sessionKey: pipeline:${project}:${agent-role}
```

---

## Application to Judgement Agent Pipeline

```yaml
name: scout-evaluate
steps:
  # Step 1: Structural filter (no LLM)
  - id: structural-filter
    command: >
      node scripts/structural-filter.js
      --ca "${token.ca}"
      --tweet-length "${submission.tweet_text_length}"
      --scout-submissions "${scout.submissions_today}"
      --snapshot-exists "${snapshot.exists}"
      --is-banned "${scout.is_banned}"

  # Step 2: Thesis Quality Gate (Sonnet — single model for GP test)
  - id: thesis-quality-gate
    condition: $structural-filter.json.passed == true
    command: >
      openclaw.invoke --tool llm-task --action json
      --model sonnet
      --args-json '{
        "prompt": "Score this scout thesis 1-10...",
        "schema": { "type": "object", "properties": { "thesis_score": {"type": "number"} } }
      }'

  # Step 3-6: Deep Analysis (Sonnet — only for passed submissions)
  - id: deep-analysis
    condition: $quick-judge.json.thesis_score >= 4
    command: >
      openclaw.invoke --tool agent-send --args-json '{
        "agentId": "judgement-agent",
        "message": "Deep analysis for ${token.ca}",
        "sessionKey": "pipeline:scout:deep-${submission.id}"
      }'
```

This is a sketch — actual implementation depends on your tool setup and OpenClaw version.
