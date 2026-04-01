## Summary

<!-- What does this PR do? 1-3 bullets. -->

-

## Research Alignment

<!-- Which sources from the research log support these changes? -->

- Source:
- Validated against:

## Checklist

- [ ] CLAUDE.md is under 200 lines
- [ ] All new SKILL.md files have required frontmatter (name, description, version, triggers)
- [ ] All new agent files have required frontmatter (name, description, tools)
- [ ] No hardcoded secrets or credentials
- [ ] CHANGELOG.md updated under [Unreleased]
- [ ] `docs/design-decisions.md` updated if a new architectural decision was made
- [ ] Cowork variant added/updated if the skill has a Cowork use case

## Testing

<!-- How was this tested? -->

- [ ] Loaded in Claude Code — skill activates on trigger phrase
- [ ] Agent spawns correctly
- [ ] Hooks fire as expected
- [ ] Heartbeat + wrap-up run cleanly end-to-end
