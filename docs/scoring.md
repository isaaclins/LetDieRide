# Scoring System

This document covers the hand detection algorithm, score calculation formula, and hand upgrade mechanics.

**Source files:** `functions/scoring.lua`, `objects/hand.lua`

---

## Core Formula

```
score = floor( (hand.base_score + sum_of_matched_dice) × hand.multiplier )
```

After the base calculation, dice abilities and item effects are layered on:

```
score = score + ability_bonuses
score = floor( score × (1 + item_mult_bonus) )
```

### Example

A **Three of a Kind** with three 5s:

```
base_score  = 30          (Three of a Kind base)
matched sum = 5 + 5 + 5   = 15
multiplier  = 2.0

score = floor((30 + 15) × 2.0) = 90
```

If the player has Even Steven (+0.5 mult per even die) and 2 even dice elsewhere:

```
item_mult_bonus = 2 × 0.5 = 1.0
final_score = floor(90 × (1 + 1.0)) = 180
```

---

## Hand Detection Algorithm

The hand detection runs in `Scoring.detectHand(values)` and follows a priority-ordered evaluation. The first match wins — the algorithm checks the strongest hands first.

### Step 1: Build Frequency Table

```lua
function getCounts(values)
    local counts = {}
    for _, v in ipairs(values) do
        counts[v] = (counts[v] or 0) + 1
    end
    return counts
end
```

This produces a table like `{[3]=2, [5]=3}` for values `{3, 5, 3, 5, 5}`.

### Step 2: Sort Values

```lua
function getSorted(values)
    local s = {}
    for _, v in ipairs(values) do table.insert(s, v) end
    table.sort(s)
    return s
end
```

### Step 3: Consecutive Check

```lua
function hasConsecutive(sorted, n)
    local unique = {}
    local seen = {}
    for _, v in ipairs(sorted) do
        if not seen[v] then
            table.insert(unique, v)
            seen[v] = true
        end
    end
    table.sort(unique)
    if #unique < n then return false end
    for i = 1, #unique - n + 1 do
        local ok = true
        for j = 1, n - 1 do
            if unique[i + j] ~= unique[i] + j then
                ok = false
                break
            end
        end
        if ok then return true end
    end
    return false
end
```

Extracts unique values, sorts them, then checks for any window of `n` consecutive integers.

### Step 4: Detection Order

The algorithm checks hands from strongest to weakest. The first match returns immediately.

```
Pyramid → Seven of a Kind → Six of a Kind → Five of a Kind →
Full Run → Two Triplets → Four of a Kind → Three Pairs →
Large Straight → Full House → All Even → All Odd →
Small Straight → Three of a Kind → Two Pair → Pair → High Roll
```

### Detection Logic per Hand

| Hand | Condition |
|------|-----------|
| **Pyramid** | Exactly counts `{1→2, 3→4, 5→6}` or pattern with 2 of each pair; requires 9+ dice |
| **Seven of a Kind** | Any count ≥ 7 |
| **Six of a Kind** | Any count ≥ 6 |
| **Five of a Kind** | Any count ≥ 5 |
| **Full Run** | All values 1-6 present (6+ dice, 6 unique values) |
| **Two Triplets** | 2+ values with count ≥ 3 (requires 6+ dice) |
| **Four of a Kind** | Any count ≥ 4 |
| **Three Pairs** | 3+ values with count ≥ 2 (requires 6+ dice) |
| **Large Straight** | `hasConsecutive(sorted, 5)` |
| **Full House** | One count ≥ 3 AND a different count ≥ 2 |
| **All Even** | All values are even (requires 5+ dice) |
| **All Odd** | All values are odd (requires 5+ dice) |
| **Small Straight** | `hasConsecutive(sorted, 4)` |
| **Three of a Kind** | Any count ≥ 3 |
| **Two Pair** | 2+ values with count ≥ 2 |
| **Pair** | Any count ≥ 2 |
| **High Roll** | Always matches (fallback) |

### Matched Dice Selection

When a hand is detected, only the **matched dice** contribute to the sum:

- **N of a Kind**: Only `n` dice of the matching value (e.g., Three of a Kind uses 3 dice)
- **Straight**: The dice forming the consecutive sequence
- **Full House**: The 3+2 dice used
- **Pairs**: Only the paired dice
- **High Roll**: Only the single highest die

The `getMatchedDice(hand_name, values, counts)` function returns which dice values are included in the sum.

---

## Best Hand Selection

`Scoring.findBestHand(values, player_hands)` doesn't just detect the hand type — it also looks up the player's upgraded version of that hand to get the current base score and multiplier.

```lua
function Scoring.findBestHand(values, player_hands)
    local detected = Scoring.detectHand(values)
    for _, hand in ipairs(player_hands) do
        if hand.name == detected.name then
            return hand, detected.matched
        end
    end
    return detected, detected.matched
end
```

---

## Hand Upgrade System

Each hand can be upgraded up to **level 5** in the shop.

### Per-Level Bonuses

| Stat | Per Level |
|------|-----------|
| Base score | +30% (compounding): `base = floor(base × 1.3)` |
| Multiplier | +0.5 flat |

### Upgrade Cost Formula

```
cost = 5 + level² × 5
```

Where `level` is the current level (before upgrading).

| Upgrade | Cost |
|---------|------|
| 0 → 1 | $5 |
| 1 → 2 | $10 |
| 2 → 3 | $25 |
| 3 → 4 | $50 |
| 4 → 5 | $85 |

**Total cost to max a hand: $175**

### Upgrade Example: Pair

| Level | Base Score | Multiplier | Score (two 6s) |
|-------|-----------|------------|----------------|
| 0 | 10 | ×1.5 | (10+12)×1.5 = 33 |
| 1 | 13 | ×2.0 | (13+12)×2.0 = 50 |
| 2 | 16 | ×2.5 | (16+12)×2.5 = 70 |
| 3 | 20 | ×3.0 | (20+12)×3.0 = 96 |
| 4 | 26 | ×3.5 | (26+12)×3.5 = 133 |
| 5 | 33 | ×4.0 | (33+12)×4.0 = 180 |

A max-level Pair scores over **5× more** than a level-0 Pair.

---

## Complete Hand Table

All 17 hands at level 0:

| # | Hand | Base | Mult | Min Dice | Effective Range |
|---|------|------|------|----------|-----------------|
| 17 | Pyramid | 200 | ×10 | 9 | 2000+ |
| 16 | Seven of a Kind | 175 | ×8 | 7 | 1400+ |
| 15 | Six of a Kind | 130 | ×6 | 6 | 780+ |
| 14 | Five of a Kind | 100 | ×5 | 5 | 500+ |
| 13 | Full Run | 80 | ×4.5 | 6 | 454+ |
| 12 | Two Triplets | 65 | ×4 | 6 | 260+ |
| 11 | Four of a Kind | 60 | ×3.5 | 4 | 210+ |
| 10 | Three Pairs | 50 | ×3 | 6 | 150+ |
| 9 | Large Straight | 45 | ×3 | 5 | 195+ |
| 8 | Full House | 40 | ×2.5 | 5 | 100+ |
| 7 | All Even | 40 | ×3 | 5 | 150+ |
| 6 | All Odd | 40 | ×3 | 5 | 120+ |
| 5 | Small Straight | 30 | ×2.5 | 4 | 105+ |
| 4 | Three of a Kind | 30 | ×2 | 3 | 60+ |
| 3 | Two Pair | 20 | ×1.5 | 4 | 30+ |
| 2 | Pair | 10 | ×1.5 | 2 | 15+ |
| 1 | High Roll | 5 | ×1 | 1 | 5-11 |

"Effective Range" shows the approximate score range at level 0 without any bonuses.
