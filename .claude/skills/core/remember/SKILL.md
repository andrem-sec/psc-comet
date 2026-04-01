---
name: remember
description: In-session memory tagging — mark content for recall later in the same session
version: 0.1.0
level: 1
triggers:
  - "remember this"
  - "keep this in mind"
  - "<remember>"
context_files: []
steps:
  - name: Tag
    description: Wrap the content in <remember> tags and state it back to confirm
  - name: Categorize
    description: Label it — decision / constraint / blocker / context / preference
  - name: Recall
    description: When the tagged content becomes relevant later, surface it proactively
---

# Remember Skill

In-session memory tagging. Use `<remember>` tags to mark content Claude should actively recall later in the same session.

## What Claude Gets Wrong Without This Skill

Claude processes context sequentially. Important constraints or decisions stated early in a session get deprioritized as new content fills the context window. By the time they are relevant, they are buried. The user has to repeat themselves.

`<remember>` tags are a signal to treat the tagged content as active working memory rather than archived history.

## Usage

The user or Claude can invoke remember:

```
<remember>
We decided to use UUIDs not auto-increment IDs for this table.
The reason: cross-service portability.
</remember>
```

Or by invoking the skill:
```
Remember this: the auth service returns 429 instead of 401 on rate-limit — this is intentional.
```

## Categories

| Category | What It Is |
|----------|-----------|
| `decision` | A choice made that affects downstream work |
| `constraint` | A limit that cannot be changed during this session |
| `blocker` | Something that will stop progress unless resolved |
| `context` | Background that makes a later question clearer |
| `preference` | User preference stated once that should persist |

## Recall Behavior

When a remembered item becomes relevant to current work, surface it proactively:

```
Recall [decision]: We decided UUIDs not auto-increment. This affects the migration schema.
```

Do not wait for the user to re-state it.

## Scope

`<remember>` tags are session-scoped. They do not persist to context/learnings.md unless explicitly promoted via lesson-gen or wrap-up.

## Anti-Patterns

Do not tag everything as memorable. Overuse makes the signal meaningless.

Do not surface remembered items when they are not relevant — that is noise.

## Mandatory Checklist

1. Verify the tagged content was stated back to confirm it was captured
2. Verify a category was assigned
3. Verify the item will be surfaced proactively when relevant (not waiting to be asked)
