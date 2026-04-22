---
name: distill
description: Memory consolidation -- compress old learnings and surface instinct clusters for review
---

# Distill

Invoke the distill skill now. This is the periodic memory consolidation step, triggered by
the ember gate after 5+ sessions and 24+ hours since the last run.

## Purpose

Two jobs:
1. **Compress learnings** -- reduce tagged learning files by merging duplicates and archiving
   superseded entries
2. **Merge instinct clusters** -- surface groups of similar instincts and propose consolidations

Distill does not delete. It archives and consolidates.

## Part 1: Learnings Compression

1. Read `context/learnings-index.md` for the tag list and entry counts.
2. For each tagged file in `context/learnings/` that has entries:
   - Identify near-duplicate entries (same pattern, slightly different wording)
   - Identify superseded entries (a later entry contradicts or replaces an earlier one)
   - Identify entries no longer relevant (project-specific to a project that is no longer active)
3. Present a consolidation proposal to the user -- show exactly what would be merged or archived
   before touching anything.
4. On confirmation, apply changes. Move superseded entries to a `<!-- ARCHIVED -->` block at the
   bottom of each file. Never delete.
5. Update entry counts in `learnings-index.md`.

## Part 2: Instinct Cluster Review

1. Run: `python scripts/continuous-learning-v2/instinct-cli.py list`
2. Identify clusters: instincts in the same domain with overlapping triggers or actions.
3. For each cluster, propose one merged instinct that covers all cases more precisely.
4. Present proposals to user. On confirmation:
   - Add the merged instinct via `instinct-cli.py add`
   - Note the originals as superseded (do not delete -- mark with `instinct-cli.py apply` to
     increase confidence on the merged version)
5. Skip gracefully if `instinct-cli.py` is unavailable -- note what was skipped.

## Part 3: Reset Ember Gate

After completing Parts 1 and 2 (or confirming nothing to do):

1. Delete `context/ember-due` if it exists.
2. Touch `context/ember.lock` to update its mtime: this marks the consolidation timestamp.
3. Reset `context/ember.count` to 0.

Run these regardless of whether there was anything to compress.

## Graceful Degradation

- If `context/learnings/` does not exist: skip Part 1, continue with Part 2.
- If `instinct-cli.py` is unavailable: skip Part 2, complete Part 1 only.
- If both are missing: report nothing to distill, reset ember gate, done.
