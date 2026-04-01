---
name: ai-regression-testing
description: Test specifically for AI-introduced regressions that repeat without tests
version: 1.0.0
level: 3
triggers:
  - "regression test"
  - "AI introduced bug"
  - "test for this bug"
  - "prevent this from happening again"
context_files:
  - context/learnings.md
steps:
  - name: Identify Regression Pattern
    description: Classify the bug into one of the four primary AI regression patterns
  - name: Write Focused Test
    description: Create test that would have caught this specific bug
  - name: Verify Test Fails
    description: Confirm test fails against the buggy code
  - name: Fix and Verify Pass
    description: Fix the bug and confirm test now passes
  - name: Document Pattern
    description: Log to learnings.md for future reference
---

# AI Regression Testing Skill

Write tests for bugs that were found, not for code that works.

## What Claude Gets Wrong Without This Skill

AI re-introduces the same bug repeatedly without tests. Real example from ECC research: the same `notification_settings` bug was introduced 4 times in a row before a regression test was added.

Why this happens:
1. AI has no memory of past bugs across sessions
2. AI optimizes for "looks correct" not "is correct"
3. Similar contexts trigger similar mistakes
4. Pattern recognition works both ways (reinforces both correct and incorrect patterns)

The solution: regression tests. Once a bug appears, test it. The test prevents recurrence.

## The Four Primary AI Regression Patterns

### Pattern 1: Sandbox/Production Path Mismatch (#1 most common)

**Symptom**: Works in development, fails in production.

**Cause**: Hardcoded paths, environment assumptions, missing environment variable checks.

**Example**:
```python
# AI writes this in sandbox
data = pd.read_csv('/Users/claude/data/users.csv')

# Fails in production (path doesn't exist)
```

**Test to write**:
```python
def test_data_path_uses_config():
    """Regression: ensure data paths come from config, not hardcoded"""
    from config import get_data_path
    path = get_data_path('users')
    assert not path.startswith('/Users/')
    assert os.path.exists(path)
```

### Pattern 2: SELECT Clause Omission

**Symptom**: Query returns all columns when only specific columns needed.

**Cause**: AI defaults to `SELECT *` for simplicity.

**Example**:
```python
# AI writes this
query = "SELECT * FROM users WHERE active = true"

# Should be (performance issue with 50+ columns)
query = "SELECT id, email, name FROM users WHERE active = true"
```

**Test to write**:
```python
def test_user_query_selects_only_required_columns():
    """Regression: ensure query doesn't SELECT *"""
    query = get_active_users_query()
    assert 'SELECT *' not in query
    assert 'id' in query and 'email' in query
```

### Pattern 3: Error State Leakage

**Symptom**: Errors in one operation affect subsequent operations.

**Cause**: Shared state not cleaned up after exceptions.

**Example**:
```python
# AI writes this
def process_batch(items):
    for item in items:
        cache[item.id] = item  # Sets cache
        process(item)  # May raise exception
    cache.clear()  # Never reached if exception raised
```

**Test to write**:
```python
def test_cache_cleared_even_on_exception():
    """Regression: ensure cache doesn't leak on errors"""
    items = [valid_item, invalid_item, valid_item]
    with pytest.raises(ProcessError):
        process_batch(items)
    assert len(cache) == 0  # Cache must be empty
```

### Pattern 4: Optimistic Update Without Rollback

**Symptom**: UI shows success but backend operation failed.

**Cause**: UI updated before async operation completes.

**Example**:
```javascript
// AI writes this
function deleteUser(id) {
    users = users.filter(u => u.id !== id)  // Update UI immediately
    api.delete(`/users/${id}`)  // May fail, UI not reverted
}
```

**Test to write**:
```javascript
test('user remains in list if delete API fails', async () => {
    // Regression: ensure rollback on API failure
    api.delete.mockRejectedValue(new Error('Network error'))
    await deleteUser(123)
    expect(users.find(u => u.id === 123)).toBeDefined()
})
```

## Strategy: Test Bugs, Not Features

**Wrong approach**: "Let's add tests for the auth module."
- Leads to testing happy paths that already work
- Misses edge cases where bugs actually occur
- Low ROI (writing tests for working code)

**Right approach**: "This auth bug happened. Let's test for it."
- Directly targets actual failure modes
- High ROI (prevents specific regressions)
- Documents the bug in executable form

## When to Write AI Regression Tests

**After every bug fix**: If you fixed it, test it.

**After every "this worked before" incident**: Regression detected. Add test.

**After every repeated mistake**: If the same bug appears twice, add test immediately.

**During code review**: Reviewer sees a pattern. "Have we tested for error case X?"

## Anti-Patterns

**Testing only happy paths**: AI regressions occur in error cases, edge cases, race conditions. Test those.

**Writing tests after the fact**: Test while the bug is fresh. Delay = forgotten context.

**Generic tests for specific bugs**: A test for "auth works" doesn't prevent the specific bug "logout doesn't clear session cookie". Be specific.

**Skipping the "verify failure" step**: Always confirm the test fails before the fix. Otherwise you might have written a test that would never catch the bug.

## Integration with Fix Workflow

1. **Bug reported**: User reports issue or test fails
2. **Reproduce**: Confirm the bug exists
3. **Write regression test**: Test that fails against current code
4. **Fix the bug**: Modify code to pass the test
5. **Verify**: Test now passes, all other tests still pass
6. **Document**: Add entry to learnings.md noting the pattern

This is the `/fix` pipeline. AI regression testing is step 3.

## Test Naming Convention

Use descriptive names that explain the regression:

```python
# Good: Explains what was wrong
def test_logout_clears_session_cookie():
    """Regression: logout was leaving session cookie set"""

# Bad: Generic, doesn't explain the bug
def test_logout():
    """Test logout functionality"""
```

## Documenting in Learnings

After adding a regression test, log to `context/learnings.md`:

```markdown
[2026-03-28] pattern | AI regression: SELECT * query on users table caused performance issue. Added test_user_query_selects_only_required_columns() to prevent recurrence. Pattern: AI defaults to SELECT * for simplicity without considering column count impact.
```

This creates institutional memory. Future sessions can reference these patterns.

## Mandatory Checklist

1. Verify the regression test targets a specific bug that actually occurred (not hypothetical)
2. Verify the test fails against the buggy code before the fix
3. Verify the test passes after the fix is applied
4. Verify the test name clearly describes what regression it prevents
5. Verify the bug pattern matches one of the four primary patterns (or documents a new pattern)
6. Verify the regression is documented in context/learnings.md with the pattern category
7. Verify all existing tests still pass after the fix
