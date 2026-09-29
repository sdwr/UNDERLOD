# Swarmer contact and player survivability

Current baseline: a standard unit's **individual troop** has 125 HP
(`TROOP_HP = 100`, unit multiplier 1.25) and 25 defense, reducing incoming
hits by 20%. This is 156.25 effective HP against unmodified damage. Unit
levels add troops; they do not automatically multiply each troop's health.

## Contact behavior

- Normal, colored, and hunter swarmers survive contact and recoil away.
- Accepted swarmer hits knock the player back through the controlled push helper; extra Box2D contact impulses are suppressed.
- Swarmer contact damage is half the previous value and still scales with
  the enemy's remaining health. Death abilities retain their existing damage.
- Each swarmer can make one contact attack every 0.75 seconds across all troops.
- Each troop accepts at most one swarmer contact hit per 0.35 seconds. This
  does not grant invulnerability against projectiles, special enemies, or bosses.
- Contact recoil cannot trigger enemy collision-chain damage. Other enemies
  retain their existing contact behavior and weapon knockback is unchanged.

## Health and damage audit

Values below use the live stat and armor calculations, no items, no NG+,
full-health attackers, and no healing. A representative special shot is a
sniper projectile or dart explosion dealing the special enemy's normal damage;
individual moves and damage-over-time ticks have their own multipliers.

| Levels | Swarm contact | Special shot | Tank contact | Hits to kill: swarm / special / tank |
| --- | ---: | ---: | ---: | ---: |
| 1–3 | 5 HP | 22.40 HP | 28.00 HP | 25 / 6 / 5 |
| 4–6 | 6 HP | 26.88 HP | 33.60 HP | 21 / 5 / 4 |
| 7–9 | 7 HP | 31.36 HP | 39.20 HP | 18 / 4 / 4 |
| 10–11 | 8 HP | 35.84 HP | 44.80 HP | 16 / 4 / 3 |

Hunter swarmers deal 20% more contact damage than normal swarmers. Wounded
swarmers deal less: a half-health swarmer deals half the listed damage.

Keep the starting health pool at 125 HP. Four to six ordinary special hits
are a credible lethal threat, while swarmers create sustained attrition.
At the swarm grace limit, repeated full-health contacts could kill a troop
in 5.25–8.4 seconds; that is a theoretical bound, not a measured playtest.
Recoil, movement, and killing or wounding enemies provide opportunities to escape.

Vitality no longer appears in shop or reward rolls. Owned copies in old saves
retain their health bonuses. Base troop health remains 125 HP.

## Verification

`luajit tests/swarmer_contact.lua` checks callback order, deferred recoil,
swarm cooldowns, special/boss contact, chain-damage suppression, and the live
HP/armor calculation. Its optional LÖVE path checks actual Box2D player velocity
and swarmer rebound with both body creation orders, including restored player knockback. Existing tiered-weapon,
spawner, mortar, and Stompy regressions also passed. No full-run playtest yet.