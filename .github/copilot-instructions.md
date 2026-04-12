# Project Coding and Refactor Rules

Apply these rules to every code edit and refactor in this workspace.

## 1. Visual Sectioning
- Divide code into logical modules with high-visibility section headers.
- Use this exact separator format:

// ==========================================
// SECTION NAME
// ==========================================

## 2. Logical Organization
Organize code in this order where applicable:
1. Global Constants and Configuration
2. Library and Dependency Imports
3. Utility and Helper Functions
4. Core Business Logic
5. Execution and Initialization

## 3. Human-Centric Documentation
- Add purpose comments before each function or major block.
- Follow the Why Rule: explain decisions and non-obvious logic, not trivial actions.
- Prefer self-documenting names over vague variables.

## 4. Formatting Standards
- Use intentional vertical whitespace between logical steps.
- Keep indentation and style consistent.
- Prioritize readability and maintainability over brevity.

## 5. Refactor Quality Goal
- Make code future-proof for manual updates.
- Keep structure predictable and easy to scan.
- Avoid clever but opaque patterns.

## 6. Maintenance Comment Policy
- Keep comments that help future manual updates and debugging.
- Before complex logic, add short context comments describing intent, assumptions, and side effects.
- When business rules or access rules are enforced, add a brief "why" comment near the rule.
- Update nearby comments when behavior changes so comments never drift from the code.
- Do not add noisy comments for obvious lines; comments must be meaningful and maintenance-oriented.
