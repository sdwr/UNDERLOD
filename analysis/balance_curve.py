"""
UNDERLOD balance curve simulator.

Pulls hard numbers from combat_stats/combat_stats.lua, game_constants.lua and
items/items_v2.lua. Models:

  - Gold income and shop purchases per round
  - Real set bonuses from the actual ITEM_SETS table, via Monte Carlo over
    purchased items (epics roll 2 sets, others 1; sets chosen uniformly
    from the 15 active sets)
  - Resulting effective team DPS for a 3-archer default party
  - Per-round enemy HP burden (everything you must kill to clear)
  - Onscreen HP at a time (worst-case concurrent HP, bounded by the
    MAX_ALIVE caps)

Outputs to ./analysis/:
  - balance_curve_table.txt  (per-round table)
  - balance_curve_*.png      (four full-size plots)
  - balance_curve.html       (report embedding plots + table)

Run:
    python analysis/balance_curve.py
    python analysis/balance_curve.py --buy-rate 0.7
    python analysis/balance_curve.py --trials 2000   # MC samples per round
"""

from __future__ import annotations

import argparse
import os
import random
import sys
from collections import defaultdict
from dataclasses import dataclass

# ===========================================================================
# Constants mirrored from the Lua source
# ===========================================================================

# game_constants.lua
NUMBER_OF_ROUNDS = 11  # game currently ends at L11 (dragon, 2nd boss)
STARTING_GOLD = 9.0
def GOLD_PER_ROUND(level: int) -> int:
    if level <= 5: return 2
    if level <= 10: return 3
    if level <= 15: return 5
    if level <= 20: return 6
    return 8
def GOLD_GAINED_BY_LEVEL(level: int) -> int:
    # Per-round gold from enemy kills (gold_counter.lua now uses kill_quota as
    # the denominator, so the band value ≈ actual round drops).
    if level <= 5: return 2
    if level <= 10: return 3
    if level <= 15: return 4
    if level <= 20: return 5
    return 6
BOSS_ROUNDS = [6, 11, 16, 21, 25]
GOLD_FOR_BOSS_ROUND = {6: 10, 11: 15, 16: 20, 21: 25}  # round 25 unspecified

# combat_stats.lua  -- enemy base stats
REGULAR_ENEMY_HP = 45
SPECIAL_ENEMY_HP = 280
BOSS_HP = 1400
BOSS_HP_MULT_BY_TYPE = {"stompy": 3}
BOSS_TYPE_BY_ROUND = {6: "stompy", 11: "dragon", 16: None, 21: None, 25: None}

ENEMY_SCALE_BY_LEVEL = [
    0, 0, 0, 1, 1, 1,
    2, 2, 2, 3, 3, 3,
    4, 4, 4, 5, 5, 5, 6,
    7, 7, 7, 8, 8, 8,
]
BOSS_SCALE_BY_LEVEL = [
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 2,
    0, 0, 0, 0, 0, 0, 4,
]

# game_constants.lua: alive caps + clump cadence.
MAX_ALIVE_BASICS = 60
MAX_ALIVE_SPECIALS = 20
BASIC_CLUMP_INTERVAL = 6.0
WAVE_KILL_QUOTA_MULTIPLIER = 1.5


def post_boss_hp_mult(level: int) -> int:
    if level >= 12:
        return 4
    if level >= 7:
        return 2
    return 1


def scaled_enemy_hp(level: int, base_hp: int) -> float:
    return (base_hp + base_hp * 0.2 * ENEMY_SCALE_BY_LEVEL[level - 1]) * post_boss_hp_mult(level)


def scaled_boss_hp(level: int, base_hp: int) -> float:
    scale = BOSS_SCALE_BY_LEVEL[level - 1] if level - 1 < len(BOSS_SCALE_BY_LEVEL) else 0
    return (base_hp + base_hp * 0.8 * scale) * post_boss_hp_mult(level)


def swarmers_per_level(level: int) -> int:
    return min(30, 8 + level * 2)


def num_specials_per_level(level: int) -> int:
    if level <= 2:
        return 0
    if level in (3, 4):
        return 2
    if level == 5:
        return 3
    last_boss = max((b for b in BOSS_ROUNDS if b <= level), default=0)
    adjusted = level - last_boss
    if adjusted <= 0:
        return 0
    return {1: 4, 2: 4, 3: 5, 4: 5, 5: 5}.get(adjusted, 5)


def round_enemy_hp(level: int) -> float:
    """Total HP the player must clear in a round (sum-of-kills)."""
    swarmers = swarmers_per_level(level)
    specials = num_specials_per_level(level)
    s_hp = scaled_enemy_hp(level, REGULAR_ENEMY_HP)
    sp_hp = scaled_enemy_hp(level, SPECIAL_ENEMY_HP)
    wave_hp = (swarmers * s_hp + specials * sp_hp) * WAVE_KILL_QUOTA_MULTIPLIER
    if level in BOSS_ROUNDS:
        boss_type = BOSS_TYPE_BY_ROUND.get(level)
        boss_mult = BOSS_HP_MULT_BY_TYPE.get(boss_type, 1)
        wave_hp += scaled_boss_hp(level, BOSS_HP) * boss_mult
    return wave_hp


def onscreen_hp_estimate(level: int, team_dps_value: float) -> tuple[float, float]:
    """
    Returns (burst_hp, cap_hp).
      burst_hp: typical worst-case standing HP onscreen, modelling one fresh
        clump of swarmers + the specials that have spawned and not died yet,
        adjusted by player DPS draining the field between clumps.
      cap_hp: hard ceiling if every alive-cap slot is full.
    """
    s_hp = scaled_enemy_hp(level, REGULAR_ENEMY_HP)
    sp_hp = scaled_enemy_hp(level, SPECIAL_ENEMY_HP)

    swarmers = swarmers_per_level(level)
    clump_hp = swarmers * s_hp
    # HP added to the field per second by the swarmer clump cadence.
    spawn_rate = clump_hp / BASIC_CLUMP_INTERVAL
    # How much the player drains between clumps. If draining < spawn, leftover
    # accumulates. If draining >= spawn, only one clump's worth lingers max.
    drain_per_interval = team_dps_value * BASIC_CLUMP_INTERVAL
    if drain_per_interval >= clump_hp:
        leftover_swarmer_hp = clump_hp  # one fresh clump, drained by next tick
    else:
        # Each interval, (clump_hp - drain) HP accumulates. Steady state would
        # diverge -> in practice it caps at MAX_ALIVE_BASICS * regular_hp.
        leftover_swarmer_hp = min(MAX_ALIVE_BASICS * s_hp,
                                  clump_hp * (clump_hp / max(drain_per_interval, 1e-6)))

    # Specials trickle in; assume up to ~half of round specials are alive at the
    # peak crunch, bounded by MAX_ALIVE_SPECIALS.
    expected_specials_alive = min(MAX_ALIVE_SPECIALS, num_specials_per_level(level) / 2)
    specials_hp = expected_specials_alive * sp_hp

    # Boss adds its own HP on boss rounds (it's onscreen the whole fight).
    boss_hp = 0.0
    if level in BOSS_ROUNDS:
        boss_type = BOSS_TYPE_BY_ROUND.get(level)
        boss_mult = BOSS_HP_MULT_BY_TYPE.get(boss_type, 1)
        boss_hp = scaled_boss_hp(level, BOSS_HP) * boss_mult

    burst = leftover_swarmer_hp + specials_hp + boss_hp
    cap = MAX_ALIVE_BASICS * s_hp + MAX_ALIVE_SPECIALS * sp_hp + boss_hp
    return burst, cap


# ===========================================================================
# Shop / purchase model
# ===========================================================================

# items_v2.lua
ITEM_COST_BY_RARITY = {"common": 2, "rare": 4, "epic": 6, "legendary": 10}

# combat_stats.lua  TIER_TO_ITEM_RARITY_WEIGHTS (C, R, E, L)
RARITY_WEIGHTS_BY_TIER = {
    1.0: (0.70, 0.30, 0.00, 0.00),
    1.5: (0.35, 0.50, 0.15, 0.00),
    2.0: (0.20, 0.40, 0.30, 0.10),
    2.5: (0.00, 0.25, 0.50, 0.25),
}


def level_to_tier(level: int) -> float:
    if level <= 5:
        return 1.0
    if level <= 10:
        return 1.5
    if level <= 15:
        return 2.0
    return 2.5


SHOP_SLOTS = 3
RARITIES_ORDERED = ("common", "rare", "epic", "legendary")


def shop_rarity_weights(level: int) -> tuple[float, float, float, float]:
    return RARITY_WEIGHTS_BY_TIER[level_to_tier(level)]


def expected_shop_cost(level: int) -> float:
    weights = shop_rarity_weights(level)
    return sum(w * ITEM_COST_BY_RARITY[r] for w, r in zip(weights, RARITIES_ORDERED))


# ===========================================================================
# Real ITEM_SETS bonuses (from items_v2.lua, only active/uncommented sets)
# Stat values are RAW stat numbers; multiply by ITEM_STATS increment to get
# the in-game multiplier. CUMULATIVE per piece count (Lua iterates each tier
# whose required-count <= owned count and adds them all).
# ===========================================================================

# Per-stat increments from ITEM_STATS in items_v2.lua.
STAT_INCREMENT = {
    "dmg": 0.10,
    "aspd": 0.05,
    "crit_chance": 0.10,
    "repeat_attack_chance": 0.20,
    "fire_damage": 0.10,
    "lightning_damage": 0.10,
    "cold_damage": 0.10,
    "range": 0.05,
}

# Each set: per-piece-count tier gives (stats_dict_added, list_of_procs_added).
# A unit owning N pieces gets the SUM of every tier where required <= N.
ACTIVE_SETS = {
    "cold": [
        ({"cold_damage": 1}, []),
        ({"cold_damage": 1}, ["frostfield"]),
        ({"cold_damage": 2}, ["shatterlance"]),
    ],
    "frost_nova": [({}, ["frostnova"])],
    "fire": [
        ({"fire_damage": 1}, ["burnexplode"]),
        ({"fire_damage": 1}, []),
        ({"fire_damage": 2}, ["volcano"]),
    ],
    "meteor": [
        ({}, ["meteor"]),
        ({}, ["meteorSizeBoost"]),
        ({}, ["meteorDamageBoost"]),
    ],
    "shock": [
        ({"lightning_damage": 1}, []),
        ({"lightning_damage": 1}, ["shock"]),
        ({"lightning_damage": 2}, []),
    ],
    "lightning_ball": [({}, ["lightningball"])],
    "curse": [({}, ["curse"])],
    "bloodlust": [
        ({}, ["bloodlust"]),
        ({}, ["bloodlustSpeedBoost"]),
    ],
    "splash": [
        ({}, ["splash"]),
        ({}, ["splashSizeBoost"]),
    ],
    "damage": [
        ({"dmg": 1}, []),
        ({"dmg": 2}, []),
        ({"dmg": 4}, []),
    ],
    "aspd": [
        ({"aspd": 1}, []),
        ({"aspd": 2}, []),
        ({"aspd": 4}, []),
    ],
    "range": [
        ({"range": 1}, []),
        ({"range": 2}, []),
        ({"range": 4}, []),
    ],
    "crit": [
        ({"crit_chance": 1}, []),
        ({"crit_chance": 2}, []),
        ({"crit_chance": 4}, []),
    ],
    "shield": [({}, ["shield", "radiance"])],
    "repeat": [
        ({"repeat_attack_chance": 1}, []),
        ({"repeat_attack_chance": 2}, []),
        ({"repeat_attack_chance": 4}, []),
    ],
    "multi_shot": [
        ({}, ["multishot"]),
        ({}, ["multishotFullDamage"]),
        ({}, ["extraMultishot"]),
    ],
}
ACTIVE_SET_NAMES = list(ACTIVE_SETS.keys())

# Estimated multiplicative DPS contribution per proc. These are NOT in the
# Lua source - they're scoping assumptions, clearly factored so you can tune.
# Each value is "this proc multiplies team DPS by 1 + value" while present.
PROC_DPS_MULTIPLIER = {
    # Damage-on-attack procs (proportional bonuses)
    "burnexplode":         0.10,   # burning enemies explode for chip
    "frostfield":          0.05,   # AoE slow + minor damage
    "shatterlance":        0.15,   # heavy nuke on frozen
    "volcano":             0.20,   # AoE area damage on death
    "shock":               0.10,   # shocked enemies take +X% damage
    "lightningball":       0.10,   # periodic AoE
    "frostnova":           0.05,   # crowd control
    "curse":               0.10,   # cursed enemies take more damage
    "meteor":              0.10,
    "meteorSizeBoost":     0.05,
    "meteorDamageBoost":   0.15,
    "bloodlust":           0.10,   # snowballing aspd on kill
    "bloodlustSpeedBoost": 0.02,
    "splash":              0.20,   # ranged AoE on every hit
    "splashSizeBoost":     0.05,
    "multishot":           0.25,   # extra shots @ 25% damage = +25%
    "multishotFullDamage": 0.25,   # multishot now full damage (extra +25%)
    "extraMultishot":      0.50,   # two more shots (= +50% if full damage)
    "shield":              0.0,    # defensive
    "radiance":            0.05,   # passive aura
}


# Estimated relative DPS gain for default crit_dmg=2x. Each 1% crit chance
# adds ~1% effective DPS.
def crit_to_dps_mult(crit_chance_frac: float) -> float:
    crit_chance_frac = max(0.0, min(1.0, crit_chance_frac))
    crit_dmg_mult = 2.0
    return 1 + crit_chance_frac * (crit_dmg_mult - 1)


# ===========================================================================
# Player base DPS
# ===========================================================================

TROOP_DAMAGE = 11
NUM_TROOPS = 3
# Archer default class: dmg mult 1.5, attack cooldown 'fast' = 1.1s.
BASE_DMG_PER_TROOP = TROOP_DAMAGE * 1.5
BASE_ATTACK_COOLDOWN = 1.1


def compute_team_dps(item_rarity_history: list[str]) -> tuple[float, dict]:
    """
    Sample a single item-set-roll outcome from the rarity history and compute
    effective team DPS. Returns (dps, debug_stats).
    """
    pieces_by_set: dict[str, int] = defaultdict(int)
    for rarity in item_rarity_history:
        set_count = 2 if rarity == "epic" else 1
        # Sample without replacement so an epic doesn't roll the same set twice.
        sets_for_item = random.sample(ACTIVE_SET_NAMES, k=set_count)
        for s in sets_for_item:
            pieces_by_set[s] += 1

    stat_totals: dict[str, float] = defaultdict(float)
    procs_active: set[str] = set()
    for set_name, count in pieces_by_set.items():
        tiers = ACTIVE_SETS[set_name]
        # Cumulative: apply every tier whose required-count (1,2,3) <= count.
        for tier_index, (stats, procs) in enumerate(tiers, start=1):
            if count >= tier_index:
                for stat, raw in stats.items():
                    inc = STAT_INCREMENT.get(stat, 0.0)
                    stat_totals[stat] += raw * inc
                for p in procs:
                    procs_active.add(p)

    dmg_m = stat_totals.get("dmg", 0.0)
    aspd_m = stat_totals.get("aspd", 0.0)
    crit_frac = stat_totals.get("crit_chance", 0.0)
    repeat_frac = min(1.0, stat_totals.get("repeat_attack_chance", 0.0))
    # Per helper/helper_damage.lua:367, each elemental damage stat is a
    # MULTIPLIER on the physical hit: every attack spawns an extra hit of
    # (actual_damage * fire_damage_stat) as fire, same for cold/lightning.
    # So total per-attack damage = physical * (1 + fire + cold + lightning).
    fire_mult = stat_totals.get("fire_damage", 0.0)
    cold_mult = stat_totals.get("cold_damage", 0.0)
    lightning_mult = stat_totals.get("lightning_damage", 0.0)
    elemental_mult = fire_mult + cold_mult + lightning_mult

    physical_per_hit = BASE_DMG_PER_TROOP * (1 + dmg_m)
    eff_damage = physical_per_hit * (1 + elemental_mult)
    eff_cd = BASE_ATTACK_COOLDOWN / max(0.05, 1 + aspd_m)
    proc_dps_mult = 1.0
    for p in procs_active:
        proc_dps_mult *= 1 + PROC_DPS_MULTIPLIER.get(p, 0.0)
    crit_mult = crit_to_dps_mult(crit_frac)
    repeat_mult = 1 + repeat_frac

    per_troop_dps = (eff_damage / eff_cd) * crit_mult * repeat_mult * proc_dps_mult
    team_dps_value = NUM_TROOPS * per_troop_dps

    debug = {
        "dmg_m": dmg_m, "aspd_m": aspd_m,
        "crit": crit_frac, "repeat": repeat_frac,
        "elem": elemental_mult,
        "procs": len(procs_active),
    }
    return team_dps_value, debug


def expected_team_dps(item_rarity_history: list[str], trials: int) -> tuple[float, dict]:
    if not item_rarity_history:
        # No items: only base.
        eff_damage = BASE_DMG_PER_TROOP
        eff_cd = BASE_ATTACK_COOLDOWN
        base_dps = NUM_TROOPS * eff_damage / eff_cd
        return base_dps, {"dmg_m": 0, "aspd_m": 0, "crit": 0,
                          "repeat": 0, "elem": 0, "procs": 0}

    total_dps = 0.0
    sums = defaultdict(float)
    for _ in range(trials):
        dps, dbg = compute_team_dps(item_rarity_history)
        total_dps += dps
        for k, v in dbg.items():
            sums[k] += v
    n = trials
    return total_dps / n, {k: sums[k] / n for k in sums}


# ===========================================================================
# Per-round simulator
# ===========================================================================


@dataclass
class RoundState:
    level: int
    gold_start: float
    income: float
    spent: float
    items_bought: int
    cumulative_items: int
    dmg_m: float
    aspd_m: float
    crit: float
    repeat_chance: float
    elem: float
    dps: float
    enemy_hp_total: float
    onscreen_burst: float
    onscreen_cap: float
    clear_time: float
    gold_end: float


@dataclass
class SimConfig:
    buy_rate: float = 1.0
    starting_gold: float = STARTING_GOLD
    trials: int = 500
    seed: int = 1


def expected_rarity_for_purchase(level: int) -> str:
    """
    Greedy purchase: the AVERAGE rarity rolled in this level's shop, sampled
    proportionally to the shop weights. The player effectively buys whichever
    is affordable; over many rounds the rarity distribution = shop weights.
    """
    weights = shop_rarity_weights(level)
    return random.choices(RARITIES_ORDERED, weights=list(weights))[0]


def simulate(cfg: SimConfig) -> list[RoundState]:
    random.seed(cfg.seed)
    gold = cfg.starting_gold
    item_history: list[str] = []
    rows: list[RoundState] = []

    for level in range(1, NUMBER_OF_ROUNDS + 1):
        # Boss rounds use their fixed bonus AND still drop per-kill gold;
        # non-boss rounds sum the end-of-round constant + kill drops.
        income = GOLD_FOR_BOSS_ROUND.get(level, GOLD_PER_ROUND(level)) + GOLD_GAINED_BY_LEVEL(level)
        gold_at_shop = gold + income

        avg_cost = expected_shop_cost(level)
        max_affordable = int(gold_at_shop // avg_cost) if avg_cost > 0 else 0
        max_buyable = min(max_affordable, SHOP_SLOTS)
        items_bought = int(round(max_buyable * cfg.buy_rate))
        spent = items_bought * avg_cost
        gold_after = gold_at_shop - spent

        for _ in range(items_bought):
            item_history.append(expected_rarity_for_purchase(level))

        dps, dbg = expected_team_dps(item_history, cfg.trials)
        e_hp_total = round_enemy_hp(level)
        burst, cap = onscreen_hp_estimate(level, dps)
        clear = e_hp_total / dps if dps > 0 else float("inf")

        rows.append(RoundState(
            level=level, gold_start=gold_at_shop, income=income, spent=spent,
            items_bought=items_bought, cumulative_items=len(item_history),
            dmg_m=dbg["dmg_m"], aspd_m=dbg["aspd_m"],
            crit=dbg["crit"], repeat_chance=dbg["repeat"],
            elem=dbg.get("elem", 0.0),
            dps=dps, enemy_hp_total=e_hp_total,
            onscreen_burst=burst, onscreen_cap=cap,
            clear_time=clear, gold_end=gold_after,
        ))
        gold = gold_after

    return rows


# ===========================================================================
# Rendering
# ===========================================================================


def format_table(rows: list[RoundState], cfg: SimConfig) -> str:
    out = []
    out.append(f"UNDERLOD balance curve  (buy_rate={cfg.buy_rate}, trials={cfg.trials})")
    out.append("")
    header = (
        f"{'L':>3} {'tier':>5} {'gold':>6} {'inc':>4} {'spent':>6} "
        f"{'buy':>4} {'cum':>4} {'dmgM':>5} {'aspM':>5} {'crit':>5} "
        f"{'rep':>5} {'elem':>5} {'DPS':>7} {'totHP':>9} {'burst':>9} {'cap':>9} {'clr(s)':>7}"
    )
    out.append(header)
    out.append("-" * len(header))
    for r in rows:
        boss = "*" if r.level in BOSS_ROUNDS else " "
        out.append(
            f"{r.level:>3}{boss}{level_to_tier(r.level):>4.1f} "
            f"{r.gold_start:>6.1f} {r.income:>4} {r.spent:>6.1f} "
            f"{r.items_bought:>4} {r.cumulative_items:>4} "
            f"{r.dmg_m:>5.2f} {r.aspd_m:>5.2f} {r.crit:>5.2f} {r.repeat_chance:>5.2f} "
            f"{r.elem:>5.2f} {r.dps:>7.1f} {r.enemy_hp_total:>9.0f} {r.onscreen_burst:>9.0f} "
            f"{r.onscreen_cap:>9.0f} {r.clear_time:>7.1f}"
        )
    out.append("")
    out.append("* = boss round | totHP = sum HP to clear | burst = expected peak HP onscreen")
    return "\n".join(out)


def render_plots(rows, cfg, out_dir):
    import matplotlib.pyplot as plt

    levels = [r.level for r in rows]

    def boss_lines(ax):
        for b in BOSS_ROUNDS:
            ax.axvline(b, color="grey", alpha=0.25, linestyle="--")

    files = {}

    # 1. Gold flow
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(levels, [r.gold_start for r in rows], "-o", label="gold at shop")
    ax.plot(levels, [r.spent for r in rows], "-s", label="gold spent")
    ax.plot(levels, [r.gold_end for r in rows], "-^", label="gold remaining")
    boss_lines(ax)
    ax.set_title("Gold per round")
    ax.set_xlabel("Round"); ax.set_ylabel("Gold")
    ax.legend(); ax.grid(alpha=0.3)
    p = os.path.join(out_dir, "balance_curve_1_gold.png")
    fig.tight_layout(); fig.savefig(p, dpi=140); plt.close(fig)
    files["gold"] = os.path.basename(p)

    # 2. Items + multipliers
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(levels, [r.cumulative_items for r in rows], "-o",
            color="tab:purple", label="cum items")
    ax.set_xlabel("Round")
    ax.set_ylabel("Cumulative items", color="tab:purple")
    ax2 = ax.twinx()
    ax2.plot(levels, [r.dmg_m for r in rows], "-s", color="tab:red", label="dmg_m")
    ax2.plot(levels, [r.aspd_m for r in rows], "-^", color="tab:orange", label="aspd_m")
    ax2.plot(levels, [r.crit for r in rows], "-d", color="tab:cyan", label="crit %")
    ax2.plot(levels, [r.repeat_chance for r in rows], "-v", color="tab:green",
             label="repeat %")
    ax2.plot(levels, [r.elem for r in rows], "-x", color="tab:brown",
             label="elem mult (sum)")
    ax2.set_ylabel("Multiplier / chance")
    boss_lines(ax)
    ax.set_title("Cumulative items + expected stat multipliers (MC averaged)")
    lines1, labels1 = ax.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax.legend(lines1 + lines2, labels1 + labels2, loc="upper left")
    ax.grid(alpha=0.3)
    p = os.path.join(out_dir, "balance_curve_2_items.png")
    fig.tight_layout(); fig.savefig(p, dpi=140); plt.close(fig)
    files["items"] = os.path.basename(p)

    # 3. DPS vs HP (total per round) — log scale
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(levels, [r.dps for r in rows], "-o", color="tab:blue", label="team DPS")
    ax.plot(levels, [r.enemy_hp_total for r in rows], "-s", color="tab:red",
            label="round HP burden (total kill)")
    ax.plot(levels, [r.onscreen_burst for r in rows], "-^", color="tab:orange",
            label="HP onscreen (expected burst)")
    ax.plot(levels, [r.onscreen_cap for r in rows], "--", color="tab:pink",
            alpha=0.6, label="HP onscreen (cap)")
    boss_lines(ax)
    ax.set_yscale("log")
    ax.set_title("Player DPS vs enemy HP (log scale)")
    ax.set_xlabel("Round"); ax.set_ylabel("value (log)")
    ax.legend(); ax.grid(alpha=0.3, which="both")
    p = os.path.join(out_dir, "balance_curve_3_dps_vs_hp.png")
    fig.tight_layout(); fig.savefig(p, dpi=140); plt.close(fig)
    files["dps_hp"] = os.path.basename(p)

    # 4. Clear time
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(levels, [r.clear_time for r in rows], "-o", color="tab:green")
    boss_lines(ax)
    ax.set_title("Seconds-to-clear proxy  =  total HP / team DPS")
    ax.set_xlabel("Round"); ax.set_ylabel("Seconds")
    ax.grid(alpha=0.3)
    p = os.path.join(out_dir, "balance_curve_4_clear_time.png")
    fig.tight_layout(); fig.savefig(p, dpi=140); plt.close(fig)
    files["clear"] = os.path.basename(p)

    return files


def render_html(rows, cfg, files, out_dir, table_text):
    rows_html = []
    for r in rows:
        boss_class = ' class="boss"' if r.level in BOSS_ROUNDS else ""
        rows_html.append(
            f'<tr{boss_class}>'
            f'<td>{r.level}</td><td>{level_to_tier(r.level):.1f}</td>'
            f'<td>{r.gold_start:.1f}</td><td>{r.income}</td>'
            f'<td>{r.spent:.1f}</td><td>{r.items_bought}</td>'
            f'<td>{r.cumulative_items}</td>'
            f'<td>{r.dmg_m:.2f}</td><td>{r.aspd_m:.2f}</td>'
            f'<td>{r.crit:.2f}</td><td>{r.repeat_chance:.2f}</td>'
            f'<td>{r.elem:.2f}</td>'
            f'<td>{r.dps:.1f}</td>'
            f'<td>{r.enemy_hp_total:.0f}</td>'
            f'<td>{r.onscreen_burst:.0f}</td>'
            f'<td>{r.onscreen_cap:.0f}</td>'
            f'<td>{r.clear_time:.1f}</td></tr>'
        )

    html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>UNDERLOD balance curve</title>
<style>
body {{ font-family: system-ui, sans-serif; max-width: 1200px; margin: 24px auto;
       padding: 0 16px; background: #f8f8fa; color: #222; }}
h1 {{ margin-top: 0; }}
.meta {{ color: #666; margin-bottom: 24px; }}
img {{ width: 100%; max-width: 1100px; display: block; margin: 16px 0; border: 1px solid #ddd; background: white; }}
table {{ border-collapse: collapse; width: 100%; font-size: 13px; margin-top: 24px; }}
th, td {{ border: 1px solid #ddd; padding: 4px 8px; text-align: right; }}
th {{ background: #eef; }}
tr.boss td {{ background: #fff6e0; font-weight: 600; }}
.legend {{ color: #555; font-size: 13px; margin: 8px 0 20px; }}
</style></head><body>
<h1>UNDERLOD balance curve</h1>
<div class="meta">buy_rate={cfg.buy_rate} &middot; trials={cfg.trials} &middot;
  starting_gold={cfg.starting_gold} &middot; rounds={NUMBER_OF_ROUNDS}</div>

<h2>1. Gold flow</h2>
<img src="{files['gold']}" alt="gold flow">

<h2>2. Items and stat multipliers (Monte Carlo averaged)</h2>
<div class="legend">Per round, MC=trials samples of how the items-so-far roll their sets are taken; we average the resulting dmg/aspd/crit/repeat across samples. So these curves are <em>expected</em> values given the actual ITEM_SETS data, not best-case or worst-case.</div>
<img src="{files['items']}" alt="items">

<h2>3. Player DPS vs enemy HP per round</h2>
<div class="legend">"Total kill HP" = every enemy you have to kill in the round (sum). "Onscreen burst" = expected peak HP you'll see at once (clump-cadence model). "Onscreen cap" = theoretical max bounded by MAX_ALIVE caps.</div>
<img src="{files['dps_hp']}" alt="dps vs hp">

<h2>4. Clear time proxy</h2>
<img src="{files['clear']}" alt="clear time">

<h2>Per-round table</h2>
<table>
<thead><tr>
<th>L</th><th>tier</th><th>gold</th><th>inc</th><th>spent</th>
<th>buy</th><th>cum</th><th>dmgM</th><th>aspM</th><th>crit</th>
<th>rep</th><th>elem</th><th>DPS</th><th>totHP</th><th>burst</th><th>cap</th><th>clr(s)</th>
</tr></thead>
<tbody>
{''.join(rows_html)}
</tbody></table>

<details style="margin-top: 24px"><summary>Raw text table</summary>
<pre style="background:#fff;padding:12px;overflow:auto">{table_text}</pre>
</details>
</body></html>
"""
    path = os.path.join(out_dir, "balance_curve.html")
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    return path


# ===========================================================================


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--buy-rate", type=float, default=1.0)
    p.add_argument("--starting-gold", type=float, default=STARTING_GOLD)
    p.add_argument("--trials", type=int, default=500,
                   help="Monte Carlo samples per round (higher = smoother curves)")
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--out-dir", default="analysis")
    args = p.parse_args()

    cfg = SimConfig(
        buy_rate=args.buy_rate, starting_gold=args.starting_gold,
        trials=args.trials, seed=args.seed,
    )
    rows = simulate(cfg)
    table = format_table(rows, cfg)
    print(table)

    os.makedirs(args.out_dir, exist_ok=True)
    with open(os.path.join(args.out_dir, "balance_curve_table.txt"), "w", encoding="utf-8") as f:
        f.write(table)

    files = render_plots(rows, cfg, args.out_dir)
    html_path = render_html(rows, cfg, files, args.out_dir, table)
    print(f"\nWrote:")
    for k, v in files.items():
        print(f"  {os.path.join(args.out_dir, v)}")
    print(f"  {html_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
