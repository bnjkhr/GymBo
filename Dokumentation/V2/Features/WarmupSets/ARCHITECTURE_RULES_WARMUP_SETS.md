# 🏛️ Architecture Rules: Warmup Sets & OrderIndex

**Document Type:** Technical Architecture Guidelines  
**Status:** 🔴 **MANDATORY** - Must be followed for all future development  
**Last Updated:** 2025-10-30

---

## 📜 Core Principles

### Rule #1: ALWAYS Use `isWarmup` for Logical Filtering ⚠️ CRITICAL

**The Golden Rule:**
> **NEVER filter or group sets by `orderIndex` alone. ALWAYS check `isWarmup` flag.**

#### ❌ WRONG Examples

```swift
// ❌ BAD: Assumes first 3 sets are warmup
let warmupSets = exercise.sets.prefix(3)

// ❌ BAD: Assumes orderIndex < 3 means warmup
let warmupSets = exercise.sets.filter { $0.orderIndex < 3 }

// ❌ BAD: Assumes warmup come before working
let firstWorkingSet = exercise.sets.first(where: { $0.orderIndex >= 3 })
```

**Why This Fails:**
- User might delete warmup sets → orderIndex gets reindexed
- User might add sets after deletion → orderIndex no longer correlates with set type
- Future refactoring might change ordering logic
- **Result:** Working sets treated as warmup, stats become incorrect

#### ✅ CORRECT Examples

```swift
// ✅ GOOD: Explicit isWarmup check
let warmupSets = exercise.sets.filter { $0.isWarmup }
let workingSets = exercise.sets.filter { !$0.isWarmup }

// ✅ GOOD: Find first working set by flag
let firstWorkingSet = exercise.sets.first(where: { !$0.isWarmup })

// ✅ GOOD: Count warmup sets explicitly
let warmupCount = exercise.sets.filter { $0.isWarmup }.count
```

---

### Rule #2: OrderIndex is ONLY for Display Order ⚠️ CRITICAL

**Purpose of `orderIndex`:**
- ✅ Sorting for display (`sets.sorted { $0.orderIndex < $1.orderIndex }`)
- ✅ Maintaining user-defined order
- ✅ Preserving warmup → working sequence

**NOT for:**
- ❌ Identifying set type (use `isWarmup` instead)
- ❌ Filtering sets (use `isWarmup` instead)
- ❌ Counting sets (use `.filter { $0.isWarmup }.count` instead)

---

### Rule #3: Reindex After Every Deletion ⚠️ CRITICAL

**Requirement:**
> After removing ANY set, ALL remaining sets MUST be reindexed to maintain sequential order (0, 1, 2, 3, ...).

**Implementation:**
```swift
// Remove set
exercise.sets.remove(at: setIndex)

// ⚠️ MANDATORY: Reindex remaining sets
exercise.sets.sort { $0.orderIndex < $1.orderIndex }
for (newIndex, _) in exercise.sets.enumerated() {
    exercise.sets[newIndex].orderIndex = newIndex
}
```

**File:** `RemoveSetUseCase.swift:92-100`

**Why This Matters:**
- Prevents gaps in orderIndex (e.g., 0, 1, 3, 5)
- Ensures `max(orderIndex) + 1` works correctly in AddSetUseCase
- Maintains data integrity

---

### Rule #4: New Sets Must Use `max(orderIndex) + 1` ⚠️ CRITICAL

**Requirement:**
> When adding a new set, NEVER use `array.count`. ALWAYS use `max(orderIndex) + 1`.

**Implementation:**
```swift
// ❌ WRONG
let orderIndex = exercise.sets.count  // Fails with gaps

// ✅ CORRECT
let maxOrderIndex = exercise.sets.map { $0.orderIndex }.max() ?? -1
let orderIndex = maxOrderIndex + 1
```

**File:** `AddSetUseCase.swift:99-108`

**Why This Matters:**
- Array count doesn't account for deleted sets
- Max orderIndex guarantees new set is added at end
- Preserves warmup → working order

---

### Rule #5: Prevent Duplicate Warmup Sets ⚠️ CRITICAL

**Requirement:**
> Before adding warmup sets, ALWAYS check if warmup sets already exist.

**Implementation:**
```swift
// ⚠️ SAFETY: Check if warmup sets already exist
if exercise.sets.contains(where: { $0.isWarmup }) {
    print("⚠️ Warmup sets already exist. Skipping.")
    return  // or throw error
}

// Proceed with adding warmup sets...
```

**Files:** 
- `SessionStore.swift:533-543` (single exercise)
- `SessionStore.swift:614-620` (batch)

**Why This Matters:**
- Prevents accidental duplicate warmup sets
- Protects against UI bugs or race conditions
- Maintains data consistency

---

## 🔍 Code Audit Checklist

When reviewing code that touches `orderIndex` or `isWarmup`, verify:

### ✅ Sorting
- [ ] Uses `sorted { $0.orderIndex < $1.orderIndex }` ✅
- [ ] Does NOT assume warmup/working by index position ✅

### ✅ Filtering
- [ ] Uses `filter { $0.isWarmup }` or `filter { !$0.isWarmup }` ✅
- [ ] Does NOT use `filter { $0.orderIndex < X }` ❌

### ✅ Adding Sets
- [ ] Uses `max(orderIndex) + 1` for new orderIndex ✅
- [ ] Sets `isWarmup = false` for working sets ✅
- [ ] Sets `isWarmup = true` for warmup sets ✅

### ✅ Removing Sets
- [ ] Reindexes remaining sets after deletion ✅
- [ ] Sorts by orderIndex before reindexing ✅
- [ ] Assigns sequential indices (0, 1, 2, ...) ✅

### ✅ Warmup Creation
- [ ] Checks if warmup sets already exist ✅
- [ ] Skips or throws error if duplicates detected ✅
- [ ] Uses `first(where: { !$0.isWarmup })` to find working set ✅

---

## 🚨 Common Pitfalls

### Pitfall #1: Assuming OrderIndex = Set Type
```swift
// ❌ WRONG: Assumes first 3 are warmup
let warmup = sets.prefix(3)

// ✅ CORRECT: Use isWarmup flag
let warmup = sets.filter { $0.isWarmup }
```

### Pitfall #2: Using Array Count for OrderIndex
```swift
// ❌ WRONG: Breaks with gaps
let newSet = DomainSessionSet(orderIndex: sets.count)

// ✅ CORRECT: Use max + 1
let maxIndex = sets.map { $0.orderIndex }.max() ?? -1
let newSet = DomainSessionSet(orderIndex: maxIndex + 1)
```

### Pitfall #3: Forgetting to Reindex After Deletion
```swift
// ❌ WRONG: Leaves gaps
sets.remove(at: index)
// No reindexing!

// ✅ CORRECT: Reindex immediately
sets.remove(at: index)
sets.sort { $0.orderIndex < $1.orderIndex }
for (i, _) in sets.enumerated() {
    sets[i].orderIndex = i
}
```

### Pitfall #4: Not Checking for Duplicate Warmups
```swift
// ❌ WRONG: Blindly adds warmup
addWarmupSets(exercise, warmupSets)

// ✅ CORRECT: Check first
if !exercise.sets.contains(where: { $0.isWarmup }) {
    addWarmupSets(exercise, warmupSets)
}
```

---

## 📊 Impact Analysis

### What Happens If Rules Are Broken?

| Rule Broken | Immediate Impact | Long-term Impact | Severity |
|-------------|------------------|------------------|----------|
| #1: Not using `isWarmup` | Incorrect stats | Warmup counted as working sets | 🔴 Critical |
| #2: Using orderIndex for logic | Wrong sets selected | Data corruption on reorder | 🔴 Critical |
| #3: No reindex after delete | Gaps in orderIndex | AddSet uses wrong index | 🔴 Critical |
| #4: Using array.count | Set added in wrong position | Warmup/working mix | 🔴 Critical |
| #5: No duplicate check | Duplicate warmup sets | User confusion, wasted storage | 🟡 Medium |

---

## 🧪 Test Scenarios

### Scenario 1: Delete Warmup, Add Working Set
```swift
// Initial state
sets = [warmup(0), warmup(1), warmup(2), working(3), working(4)]

// User deletes warmup set #1 (orderIndex 1)
removeSet(1)  // Must reindex!

// After deletion + reindex
sets = [warmup(0), warmup(1), working(2), working(3)]

// User adds new set
addSet()  // Must use max(orderIndex) + 1 = 4

// Final state
sets = [warmup(0), warmup(1), working(2), working(3), working(4)]
```

**Verification:**
- ✅ OrderIndex is sequential: 0, 1, 2, 3, 4
- ✅ Warmup sets come first (orderIndex 0, 1)
- ✅ Working sets come after (orderIndex 2, 3, 4)
- ✅ `isWarmup` flag is correct

---

### Scenario 2: Delete All Warmup, Re-Add Warmup
```swift
// Initial state
sets = [warmup(0), warmup(1), warmup(2), working(3), working(4)]

// User deletes ALL warmup sets
removeSet(0)  // Must reindex!
removeSet(0)  // Must reindex!
removeSet(0)  // Must reindex!

// After deletions + reindex
sets = [working(0), working(1)]

// User tries to add warmup again
addWarmupSets()  // Must check: no existing warmup

// Warmup sets are added
// After adding
sets = [warmup(0), warmup(1), warmup(2), working(3), working(4)]
```

**Verification:**
- ✅ No duplicate warmup check passed (no existing warmup)
- ✅ New warmup sets have orderIndex 0, 1, 2
- ✅ Working sets shifted to 3, 4
- ✅ `isWarmup` flag is correct

---

### Scenario 3: Attempt Duplicate Warmup
```swift
// Initial state
sets = [warmup(0), warmup(1), warmup(2), working(3), working(4)]

// User accidentally tries to add warmup again
addWarmupSets()  // Must be blocked!

// After check
// ⚠️ Warmup sets already exist. Skipping.

// Final state (unchanged)
sets = [warmup(0), warmup(1), warmup(2), working(3), working(4)]
```

**Verification:**
- ✅ Duplicate check prevented addition
- ✅ No duplicate warmup sets
- ✅ Existing sets unchanged

---

## 📝 Documentation Standards

### When Adding New Features

If your feature involves **sets** (adding, removing, reordering), you MUST:

1. **Read this document** completely
2. **Verify** you're using `isWarmup` for filtering
3. **Verify** you're using `max(orderIndex) + 1` for adding
4. **Verify** you're reindexing after deletion
5. **Add tests** for warmup + working set scenarios
6. **Update this document** if rules change

### Code Review Checklist

Reviewers MUST verify:
- [ ] No `filter { $0.orderIndex < X }` patterns
- [ ] No `sets.count` used for orderIndex
- [ ] Reindexing after deletions
- [ ] `isWarmup` flag used for logic
- [ ] Duplicate warmup checks in place

---

## 🎓 Training Materials

### For New Developers

**Required Reading:**
1. This document (ARCHITECTURE_RULES_WARMUP_SETS.md)
2. WARMUP_CRITICAL_FIXES.md (bug examples)
3. WARMUP_SETS_FINAL_REPORT.md (feature overview)

**Code Examples to Study:**
- `AddSetUseCase.swift` - Correct orderIndex calculation
- `RemoveSetUseCase.swift` - Reindexing pattern
- `SessionStore.addWarmupSetsBatch()` - Duplicate prevention

**Anti-Patterns to Avoid:**
- Using orderIndex for filtering
- Using array.count for orderIndex
- Not reindexing after deletion

---

## 🔄 Migration Path

### If You Find Violations

1. **Document** the violation (file, line, issue)
2. **Create** a ticket/issue
3. **Fix** using correct pattern from this doc
4. **Add test** to prevent regression
5. **Update** this doc if needed

### Example Violation Fix

**Before (WRONG):**
```swift
let warmupSets = exercise.sets.prefix(3)
```

**After (CORRECT):**
```swift
let warmupSets = exercise.sets.filter { $0.isWarmup }
```

**Verification:**
```swift
// Test with various scenarios
// 1. No warmup: returns []
// 2. With warmup: returns only warmup sets
// 3. After deletion: still correct
```

---

## ✅ Compliance Statement

**By following these rules, we ensure:**
- ✅ Data integrity across all operations
- ✅ Correct statistics calculations
- ✅ No warmup/working set confusion
- ✅ Robust handling of edge cases
- ✅ Future-proof architecture

**Breaking these rules will result in:**
- ❌ Incorrect statistics
- ❌ Data corruption
- ❌ User confusion
- ❌ Production bugs

---

## 📞 Questions?

If you're unsure about:
- Whether to use `orderIndex` or `isWarmup`
- How to handle a specific edge case
- Whether a pattern violates these rules

**Always err on the side of using `isWarmup`!**

When in doubt:
1. Check this document
2. Review existing correct implementations
3. Ask for architecture review
4. Add tests before committing

---

**Document Version:** 1.0  
**Status:** 🔴 MANDATORY  
**Last Reviewed:** 2025-10-30  
**Next Review:** Before any set-related feature changes
