# Dice stickers:

mods are the most game breaking idea I've had for this game. so I want you to plan out EVERYTHING. not only on how you implement it now, but also how to add new features in the future. the Idea is that I create 'stickers' in SVG format and you rotate and add them randomly to the body of the dice (under the actual numbered dots)
For now, each mod, (or lets call them stickers from now on), change the rules of the game for THAT dice specifically.
Each sticker should display if its stackable or not, which will make sense once you read what it does.
Each sticker should be an actual SVG and replace the current DIE MODS that exist. I believe they should deserve their own section in the shop but without a complete overhaul, it would complicate and flutter the UI even more. So they should remain in the RELICS & DIE MODS section, BUT instead of loading text, should have a small popup ON HOVER, that explains and showcases the SVG with a cool hologram effect.
The maximum ammount of DIFFERENT sticker on a die should be 5.
I must still create the cool SVG's but that does not mean you can't create the functionality yet. Here are some examples, and these are subject to change:

## CHANGES (what I would change and why)

- add a generic sticker data format first:
  - `id`, `name`, `description`, `stack_limit`, `stackable`, `rarity`, `svg_path`, `effect_hooks`.
  - why: future stickers become content-only most of the time, not engine rewrites.
- show hover popup with SVG preview + stack info + short rule text.
  - why: needed clarity once rules get weird.
- add global "chaos rules" instead of hard balance caps:
  - infinite/huge scaling is allowed.
  - only stop true degenerate states (example: non-terminating trigger loops or UI lock).
  - bosses should scale up reactively when player enters runaway combo states.
  - why: keep the Hakari fantasy while still protecting run stability.

## All in

applying this sticker means you can ONLY ever have 1 other different sticker on it, but alas unlimited of that specific sticker.(basically removes the X stackable limit, making it infinitely stackable.)
UNSTACKABLE
legendary rarity

## bad luck?

This sticker is a curse contract.
Die containing this sticker x1.5 the base mult.
Starting at round 44, if this die is still in your loadout, each round can instantly end your run.
Death chance formula (per round after round 44):
`deathChancePercent = max(0.1, 50 - (1.111 * stacks))`
The only way out is replacing the die... OR proving luck = skill by stacking more of this curse.
Stacking also stacks the x1.5 base mult.
STACKABLE (45 times)

## lucky streak

If dice containing this sticker rolls the same value twice in a row on this die during this round, it +2 the amount of rerolls and increasing its chance to strike again by 33%.
7x STACKABLE (I think this + jackpot would literally break the game, as 1/6\*1.33^6 =92.2483475628%, which is almost a 100% guarantee and hitting it with a 6 would make it do it twice...)

## momentum

Each time a dice containing this sticker rolls a 1, it x1.2 the mult it gives (standard 2)
11xSTACKABLE

how to calc:

2*((1.2^#of1rolls)*stickers)

## risk/reward

Add +2 to rolls of 1-3, but subtract 1 from rolls of 4-6.
UNSTACKABLE

## jackpot

Rolling a 6 triggers the dice containing this sticker effect twice.
STACKABLE

## reverse

All numerical values on the dice containing this sticker are reversed (1 <-> 6, 2 <->5, 3 <-> 4)
This sticker replaces Mirror Die (remove Mirror Die from dice types).
