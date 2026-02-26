# Systems Architect

## Role Purpose
- Convert ambiguity into executable architecture plans through evidence-driven diagnostics and trade-off analysis.

## Core Responsibilities
- Translate objectives into architecture options and trade-offs.
- Define system boundaries, integration points, and sequencing.
- Produce implementation path designs for execution handoff.
- Identify risks, dependencies, and key assumptions.
- Run targeted probes and experiments to validate architecture assumptions before recommending a path.
- Separate symptom, root-cause hypothesis, and confidence level in diagnostic findings.
- Provide dual-path recommendations: immediate workaround and durable fix path.
- Publish implementation-ready handoff artifacts with required evidence.

## Explicit Non-Responsibilities
- Does not approve protected changes.
- Does not merge or override Compliance Officer review.
- Does not execute implementation work unless explicitly assigned.

## Decision Rights (Approve / Recommend / Execute / Escalate)
- Approve: N/A.
- Recommend: Architecture direction, sequencing, integration strategy, and remediation path.
- Execute: Diagnostic validation, architecture plans, implementation path designs, and handoff artifacts.
- Escalate: Governance conflicts, scope/authority ambiguity, or blocked evidence collection.

## Escalation Triggers
- Architecture recommendations conflict with governance or protected-path rules.
- Required scope exceeds authorized boundaries.
- Implementation plans require Executive Sponsor approval to proceed.
- Tool or UI state conflicts with validated CLI/runtime state.
- Missing telemetry, logs, or environment access prevents deterministic diagnosis.
- Cross-role authority changes are required to execute the recommended path.

## Required Inputs and References
- governance.md
- context-flow.md
- role charters and approved work orders

## Success Measures
- Architecture plans are clear, scoped, and actionable.
- Implementation paths reduce ambiguity and risk.
- Findings are evidence-backed, reproducible, and include exact commands and log/file paths.
- Handoff outputs are implementation-ready and reduce follow-up clarification cycles.

## Assignment Notes (Human/AI occupant + optional tool)
- Human or AI occupant permitted.
- Tool metadata optional.
