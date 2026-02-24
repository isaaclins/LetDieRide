# Scoring System

This document covers the multi-hand optimal scoring algorithm, score calculation formula, and hand upgrade mechanics.

**Source files:** `functions/scoring.lua`, `objects/hand.lua`

---

## Multi-Hand Scoring

The scoring system finds the **optimal combination of non-overlapping hands** from the dice pool. Instead of picking a single best hand and ignoring remaining dice, the algorithm partitions your dice into multiple hands that maximize total score.

### Example

With dice `{1,1,1,1,1,2,2,3,3,3}`, the algorithm might find:

```
5 of a Kind (1s): (100 + 5) x 4.0 = 420
Full House (3s, 2s): (40 + 13) x 2.5 = 132
Total hand score: 552
```

This beats any single-hand reading of the same pool.

---

## Core Formula

For each hand in the combination:

```
hand_score = floor( (hand.base_score + sum_of_matched_dice) x hand.multiplier )
```

The total is the sum of all hand scores, then dice abilities and item effects are layered on:

```
total = sum of all hand_scores
total = total + ability_bonuses
total = floor( total x (1 + item_mult_bonus) )
total = floor( total x score_mult )
```

### Example

A **Full House** (three 3s + two 2s) alongside a **Pair** (two 5s):

```
Full House: floor((40 + 3+3+3+2+2) x 2.5) = floor(53 x 2.5) = 132
Pair:       floor((10 + 5+5) x 1.5) = floor(20 x 1.5) = 30
Subtotal:   162

With Even Steven (2 even dice) adding +1.0 mult_bonus:
final_score = floor(162 x (1 + 1.0)) = 324
```

---

## Optimal Combination Algorithm

`Scoring.findOptimalCombination(values, hands_list)` uses:
- **Memoized backtracking** for 12 dice or fewer
- **Greedy extraction** for more than 12 dice

1. Represent the dice pool as a frequency table: `{[1]=count1, [2]=count2, ..., [6]=count6}`
2. Generate all possible hand extractions from the current pool
3. For each extraction, remove the matched dice and recursively solve the remainder
4. Return the partition with the highest total score
5. Memoize results keyed on the counts tuple for efficiency

For large pools (>12 dice), the greedy path favors the current highest immediate-scoring extraction.

### Hand Extraction Rules

| Hand | Extraction |
|------|-----------|
| **X of a Kind** | For each value with count >= 3, extract either 3 dice or all dice of that value |
| **Pair** | Extract 2 dice of any value with count >= 2 |
| **Two Pair** | Extract 2+2 from two different values |
| **Full House** | Extract 3 of one value + 2 of another |
| **Small Straight** | Extract one each of 4 consecutive values |
| **Large Straight** | Extract one each of 5 consecutive values |
| **Full Run** | Extract one each of all values 1-6 |
| **Three Pairs** | Extract 2 each from 3 different values |
| **Two Triplets** | Extract 3 each from 2 different values |
| **Pyramid** | Extract exactly 1x2, 3x4, 5x6 |
| **All Even** | Only if ALL remaining dice are even (5+ dice); extracts all |
| **All Odd** | Only if ALL remaining dice are odd (5+ dice); extracts all |

Unmatched dice (not part of any hand) don't score. If no hand can be formed at all, falls back to **High Roll** (highest single die).

Note: **Full House** is scored as `X-of-a-Kind(3) + Pair + FullHouse base bonus` in extraction logic.

---

## X of a Kind (Dynamic Scaling)

Instead of separate Three/Four/Five/Six/Seven of a Kind hands, there is a single **X of a Kind** hand that scales dynamically with the number of matching dice.

### Scaling Formula

```
base_score(x) = floor(22 + 16 * (x - 3))
multiplier(x) = 1.8 + 0.22 * (x - 3)
```

| X | Base Score | Multiplier |
|---|-----------|-----------|
| 3 | 22 | 1.8 |
| 4 | 38 | 2.02 |
| 5 | 54 | 2.24 |
| 6 | 70 | 2.46 |
| 7 | 86 | 2.68 |
| 8 | 102 | 2.90 |
| 9 | 118 | 3.12 |
| 10 | 134 | 3.34 |

The formula extends naturally to any number of matching dice. Upgrades apply a flat base bonus and flat mult bonus on top of the X-scaling formula.

---

## Hand Upgrade System

Each hand can be upgraded up to **level 5** in the shop.

### Per-Level Bonuses

| Stat | Per Level |
|------|-----------|
| Base score | +30% (compounding): `base = floor(base x 1.3)` |
| Multiplier | +0.5 flat |

For X of a Kind, upgrades add flatter bonuses to the scaling formula:
- Base bonus: +20% (compounding on upgrade bonus state)
- Mult bonus: +0.25 flat per level

### Upgrade Cost Formula

```
cost = 5 + level^2 x 5       (levels 0-4)
cost = 5 + level^2 x 8       (levels 5+)
```

| Upgrade | Cost |
|---------|------|
| 0 -> 1 | $5 |
| 1 -> 2 | $10 |
| 2 -> 3 | $25 |
| 3 -> 4 | $50 |
| 4 -> 5 | $85 |

---

## Complete Hand Table

All 13 hands at level 0:

| # | Hand | Base | Mult | Min Dice | Description |
|---|------|------|------|----------|-------------|
| 13 | Pyramid | 200 | x10 | 9 | 1x two, 3x fours, 5x sixes |
| 12 | Full Run | 110 | x5.2 | 6 | All values 1-6 present |
| 11 | Two Triplets | 88 | x4.4 | 6 | Two sets of three of a kind |
| 10 | Three Pairs | 70 | x3.6 | 6 | Three different pairs |
| 9 | Large Straight | 58 | x3.4 | 5 | Five consecutive values |
| 8 | All Even | 52 | x2.8 | 5 | Every die shows 2/4/6 |
| 7 | All Odd | 52 | x2.8 | 5 | Every die shows 1/3/5 |
| 6 | Full House | 60 | x3.0 | 5 | Three of a kind + a pair |
| 5 | Small Straight | 34 | x2.6 | 4 | Four consecutive values |
| 4 | X of a Kind | 22-134+ | x1.8-3.34+ | 3 | 3+ matching dice, scales with count |
| 3 | Two Pair | 24 | x1.8 | 4 | Two different pairs |
| 2 | Pair | 12 | x1.6 | 2 | Two dice of the same value |
| 1 | High Roll | 5 | x1 | 1 | Highest single die (fallback) |

---

## Visual Feedback

During the **choosing** and **scoring** phases, each die is color-coded by which hand it belongs to in the optimal combination. A palette of 5 distinct colors (gold, teal, blue, purple, coral) cycles across the hands.

The **score preview panel** (left side during choosing) shows all hands in the combination with individual scores. The **scoring popup** displays each hand with its score contribution, followed by the combined total.
