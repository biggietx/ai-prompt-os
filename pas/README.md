# Prompt Architecture System (PAS)

PAS organizes reusable prompt instructions as **modules** composed into **stacks**.

## Structure

```
pas/
  modules/          # Prompt modules organized by Dewey category
    000_core_behavior/
    100_cognitive_controls/
    200_output_structure/
    300_code_policies/
    900_personal_preferences/
  stacks/           # Composable stack definitions
  schemas/          # JSON Schema for modules and stacks
  registry/         # Index files for all modules and stacks
```

## Module Format

Each module is a JSON file in the appropriate Dewey category folder.

```json
{
  "id": "unique-module-id",
  "type": "module",
  "category": "core_behavior",
  "dewey": "001",
  "version": "1.0.0",
  "status": "draft",
  "tags": ["safety", "constraints"],
  "content": "The prompt text content of this module."
}
```

**Required fields:** `id`, `type`, `category`, `dewey`, `version`, `status`, `tags`, `content`.

- `type` must be `"module"`
- `status` must be `"draft"` or `"approved"`
- `dewey` is a Dewey-decimal code (e.g., `"001"`, `"310"`, `"100.10"`)

## Stack Format

A stack composes modules into a single prompt by referencing module IDs.

```json
{
  "id": "STACK-GLOBAL-BASE-001",
  "type": "stack",
  "version": "1.0.0",
  "status": "draft",
  "includes": ["module-a", "module-b", "module-c"],
  "inherits": ["STACK-PARENT-001"],
  "overrides": ["module-x"]
}
```

**Required fields:** `id`, `type`, `version`, `status`, `includes`.

**Optional fields:** `inherits`, `overrides`.

- `includes`: Ordered list of module IDs to compose
- `inherits`: Stack IDs whose modules are prepended (depth-first, left-to-right)
- `overrides`: Module IDs from inherited stacks that are replaced by this stack's version

## Compiling a Stack

```bash
# Output to stdout
./scripts/pas_compile.sh --stack STACK-GLOBAL-BASE-001

# Output to file
./scripts/pas_compile.sh --stack STACK-GLOBAL-BASE-001 --out compiled.txt
```

### Resolution rules

1. **Inheritance** is resolved depth-first, left-to-right. Parent modules are prepended.
2. **Includes** are appended in array order.
3. **Overrides** remove the specified module IDs from inherited stacks so the current stack's version takes precedence.
4. **Deduplication**: if the same module ID appears from both inheritance and includes, the last occurrence wins (current stack takes priority).
5. Cycle detection aborts compilation. Max inheritance depth: 10.

### Output format

```
### MODULE <id> (<category> <dewey>)
<content>

### MODULE <id> (<category> <dewey>)
<content>
```

## Validation

```bash
./scripts/lint_pas.sh
```

Validates all modules and stacks against their JSON schemas, checks for duplicate IDs, and verifies all referenced module IDs exist.
