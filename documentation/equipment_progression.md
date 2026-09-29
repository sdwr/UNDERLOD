# Equipment progression

## Economy

- Start with 10 gold. Every unit costs 4 and includes Archer I.
- Normal round income: 4 gold on levels 1–3, 5 on 4–6, 6 on 7–11.
- Boss rounds pay the existing 6-gold boss reward instead.
- Selling equipment still grants 2 unit XP, never gold. Unit levels add troops.
- Tier I / II / III stat items cost 2 / 3 / 4 gold; weapons cost 3 / 5 / 7.
- The opening can buy two units and one tier-I stat item.

## Shop

Every shop has two stat-item slots and one weapon slot. Each slot rolls its
own tier. Identical offers are excluded; different tiers of a family are
separate items. Locked refills retain their slot type. Floor reward batches
use the same composition and level-based odds.

| Upcoming level | Tier I | Tier II | Tier III |
| --- | ---: | ---: | ---: |
| 1–3 | 100% | 0% | 0% |
| 4 | 65% | 35% | 0% |
| 5 | 45% | 55% | 0% |
| 6 | 25% | 75% | 0% |
| 7 | 15% | 65% | 20% |
| 8 | 10% | 55% | 35% |
| 9 | 5% | 45% | 50% |
| 10–11 | 0% | 30% | 70% |

Within a tier, eligible families/weapons have equal weight. Area starts at
level 4, including its tier-I version. Locked items can be carried into a
later shop even if their tier is no longer rolled there.

## Stat items

Bonuses below are per copy, additive across copies and tiers. Different tiers
occupy separate inventory entries. Same-tier copies stack to three, using
one entry. The unit still has six distinct inventory entries including weapons.
A family contributes its meta color once per unit, regardless of tier/copies.

| Family | Stat | I | II | III |
| --- | --- | ---: | ---: | ---: |
| Power | Damage | +20% | +35% | +50% |
| Swift | Attack speed | +10% | +18% | +25% |
| Precision | Crit chance | +10% | +18% | +25% |
| Reach | Range | +10% | +18% | +25% |
| Area | Area size | +15% | +25% | +40% |

Vitality and Mobility are retired from shop and reward rolls; owned copies remain valid in old saves.

These bonuses apply to the unit and its entire loadout. Crit chance uses the
existing cap of 100%. Area affects blast radii, aura radius, orb size, lightning
zap radius, and laser width. Reach changes target range, laser length, aura
radius, and orbit distance. Attack speed changes firing/pulse/contact frequency.

## Weapons

| Tier | Weapon | Behavior |
| --- | --- | --- |
| I | Archer | Fast homing arrows |
| I | Shotgun | Five close-range pellets |
| I | Crossbow | Heavy homing bolts; travel straight after impact and pierce two extra enemies; 1.5-second base reload |
| II | Cannon | Shell travels to the aimed position and explodes |
| II | Radiance | Close-range damaging pulses that ignite enemies; works while moving |
| II | Orbit | Two persistent rotating orbs with per-target contact cooldowns; works while moving |
| III | Laser | Powerful finite-range beam with no damage falloff through enemies |
| III | Lightning | Moving lightning ball that repeatedly zaps up to three nearby enemies |
| III | Meteor | Delayed, telegraphed blast at the aimed position |

All weapons scale with unit damage, attack speed, and range. Every weapon's
direct damage can crit, including its area/contact damage. Weapon copies keep
the existing 1x / 1.6x / 2.2x damage progression. Archer and Crossbow are separate
purchases; there is no automatic evolution. Selling Archer grants XP to the unit.
The last weapon cannot be sold until a replacement has been equipped.

## Removed shop items and compatibility

The previous proc-item pool is disabled: Storm, Lightning, Ricochet, Repeat,
Frost Nova, Orbit, Radiance, Meteor, Focus, Splash, Multi-Shot, Pierce, Garrison,
Bloodlust, Recoil, Resonance, Skirmisher, and Mend. Older disabled definitions
also remain disabled. New copies of Power/Swift/Precision use the tiered family
keys instead of the old set keys.

Owned legacy items retain their effects. Saved pending offers from the old
shop format are regenerated into the new composition on entry. Existing
weapon copies retain ownership while their names, tiers, and prices refresh.
Unit level and XP are preserved.

## Validation

- `luajit tests/item_sets.lua`: tier odds, slot types, duplicate exclusion,
  locked-style refills, shared stat aggregation, tier stacking, and migration.
- `luajit tests/item_stacking.lua`: capacity, last-weapon protection, and stacking.
- `luajit tests/tiered_weapons.lua`: production weapon scheduling, shared stats,
  crits, contact cooldowns, delayed impacts, laser damage, and effect cleanup.

These are focused Lua regressions, not a full combat balance playthrough.
