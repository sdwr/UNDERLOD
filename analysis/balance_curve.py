"""
UNDERLOD balance curve simulator.

Pulls hard numbers from combat_stats/combat_stats.lua and game_constants.lua,
models an "average" player's gold income, shop purchases, and resulting
damage multiplier, and renders curves of:

  - gold income vs cumulative spend
  - cumulative items bought
  - expected player effective DPS
  - per-round enemy HP burden
  - "rounds-to-clear" proxy = HP_burden / DPS

The point is to see the SHAPE: does player power keep pace with enemy HP, or
does one snowball away from the other? Numbers here are deliberately
deterministic-average (no RNG variance) so the curve is readable.

Run:
    python analysis/balance_curve.py                # prints table + saves PNG
    python analysis/balance_curve.py --no-plot      # table only
    python analysis/balance_curve.py --buy-rate 0.7 # buy 70% of affordable
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Constants mirrored from the Lua source
# ---------------------------------------------------------------------------

# game_constants.lua
NUMBER_OF_ROUNDS = 25
STARTING_GOLD = 9.0
GOLD_PER_ROUND = 6
BOSS_ROUNDS = [6, 11, 16, 21, 25]
GOLD_FOR_BOSS_ROUND = {6: 10, 11: 15, 16: 20, 21: 25}  # round 25 has no bonus
REROLL_COST = 1

# combat_stats.lua  -- enemy base stats
REGULAR_ENEMY_HP = 45
SPECIAL_ENEMY_HP = 280
MINIBOSS_HP = 400
BOSS_HP = 1400
BOSS_HP_MULT_BY_TYPE = {"stompy": 3}  # applied on round 6
BOSS_TYPE_BY_ROUND = {6: "stompy", 11: "dragon", 16: None, 21: None, 25: None}

# Per-level scale (1-indexed in Lua, mirrored 0-indexed here -> we keep
# 1-indexed access via SCALE_BY_LEVEL[level - 1]).
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


def post_boss_hp_mult(level: int) -> int:
    if level >= 12:
        return 4
    if level >= 7:
        return 2
    return 1


def scaled_enemy_hp(level: int, base_hp: int) -> float:
    scale = ENEMY_SCALE_BY_LEVEL[level - 1]
    return (base_hp + base_hp * 0.2 * scale) * post_boss_hp_mult(level)


def scaled_boss_hp(level: int, base_hp: int) -> float:
    # Boss scale table is short; fall back to 0 if level past end.
    if level - 1 < len(BOSS_SCALE_BY_LEVEL):
        scale = BOSS_SCALE_BY_LEVEL[level - 1]
    else:
        scale = 0
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
    # L6 is boss round itself -> 0 specials in wave (handled by boss separately).
    # L7+ uses LEVELS_AFTER_BOSS_LEVEL mapping {1->4, 2->4, 3->5, 4->5, 5->5}.
    last_boss = max(b for b in BOSS_ROUNDS if b <= level) if any(b <= level for b in BOSS_ROUNDS) else 0
    adjusted = level - last_boss
    if adjusted <= 0:
        return 0  # the boss round itself
    return {1: 4, 2: 4, 3: 5, 4: 5, 5: 5}.get(adjusted, 5)


WAVE_KILL_QUOTA_MULTIPLIER = 1.5  # the wave instructions cycle ~1.5x


def round_enemy_hp(level: int) -> float:
    """Total HP the player must chew through in a round."""
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


# ---------------------------------------------------------------------------
# Shop / purchase model
# ---------------------------------------------------------------------------

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


def expected_shop_cost(level: int) -> float:
    """Average cost of one shop slot at this level (weighted across rarities)."""
    weights = RARITY_WEIGHTS_BY_TIER[level_to_tier(level)]
    rarities = ("common", "rare", "epic", "legendary")
    return sum(w * ITEM_COST_BY_RARITY[r] for w, r in zip(weights, rarities))


# items_v2.lua: 3 items shown per shop refresh.
SHOP_SLOTS = 3

# How much effective DPS multiplier (additive to dmg_m / aspd_m) does one
# purchased item contribute, AVERAGED across all rarities and sets? Items can
# carry 1-2 sets; ~half the set pool is DPS-relevant (Damage, ASPD, Crit,
# Repeat, Multi, Splash, Range, Bloodlust, Attack Effects). Set bonuses go
# 1/2/4 stat points; first pieces hit immediately.
#
# Rough per-rarity contribution to (dmg_m + aspd_m) sum, additive:
DPS_CONTRIB_BY_RARITY = {
    "common": 0.10,
    "rare": 0.10,    # rares roll 0-0 stat values but carry set procs; ~equiv
    "epic": 0.22,    # epics roll 2 sets, more set-stacking chance
    "legendary": 0.33,
}


def expected_dps_contrib(level: int) -> float:
    weights = RARITY_WEIGHTS_BY_TIER[level_to_tier(level)]
    rarities = ("common", "rare", "epic", "legendary")
    return sum(w * DPS_CONTRIB_BY_RARITY[r] for w, r in zip(weights, rarities))


# ---------------------------------------------------------------------------
# Player base DPS
# ---------------------------------------------------------------------------

# combat_stats.lua
TROOP_DAMAGE = 11
NUM_TROOPS = 3

# Default unit class is archer (most common pick). dmg_mult=1.5, attack
# cooldown 'fast' = 1.1s in attack_cooldowns. So per-troop DPS at base:
BASE_DMG_PER_TROOP = TROOP_DAMAGE * 1.5
BASE_ATTACK_COOLDOWN = 1.1
BASE_DPS_PER_TROOP = BASE_DMG_PER_TROOP / BASE_ATTACK_COOLDOWN  # ≈ 15.0
BASE_TEAM_DPS = NUM_TROOPS * BASE_DPS_PER_TROOP  # ≈ 45.0


def team_dps(buff_dmg_m: float, buff_aspd_m: float) -> float:
    # Lua: dmg = base * (1 + buff_dmg_m_adds) ; aspd_m = 1/(1+aspd_adds).
    # buff_dmg_m starts at 1 and is added to. We pass the SUM of added stat,
    # so effective multiplier = (1 + buff_dmg_m).
    eff_dmg = BASE_DMG_PER_TROOP * (1 + buff_dmg_m)
    eff_cd = BASE_ATTACK_COOLDOWN / (1 + buff_aspd_m)
    return NUM_TROOPS * eff_dmg / eff_cd


# ---------------------------------------------------------------------------
# Simulator
# ---------------------------------------------------------------------------


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
    dps: float
    enemy_hp: float
    rounds_to_clear: float
    gold_end: float


@dataclass
class SimConfig:
    buy_rate: float = 1.0      # fraction of affordable items the player actually buys
    dps_split: float = 0.5     # half of per-item bonus goes to dmg_m, half to aspd_m
    starting_gold: float = STARTING_GOLD
    # If True, all per-item bonus goes into a single combined "dmg_m" variable
    # rather than splitting. Doesn't change effective DPS much but reads simpler.
    combine_into_dmg_only: bool = False


def simulate(cfg: SimConfig) -> list[RoundState]:
    gold = cfg.starting_gold
    dmg_m = 0.0
    aspd_m = 0.0
    cumulative_items = 0
    rows: list[RoundState] = []

    for level in range(1, NUMBER_OF_ROUNDS + 1):
        # 1. Income at the start of the buy phase (Lua adds gold post-arena).
        income = GOLD_PER_ROUND
        if level in GOLD_FOR_BOSS_ROUND:
            income = GOLD_FOR_BOSS_ROUND[level]
        gold_start_of_round = gold + income

        # 2. Shop: 3 slots, average cost varies by tier. Greedy: buy items at
        # avg cost while gold permits, scaled by buy_rate.
        avg_cost = expected_shop_cost(level)
        max_affordable = int(gold_start_of_round // avg_cost) if avg_cost > 0 else 0
        max_buyable_this_shop = min(max_affordable, SHOP_SLOTS)
        items_bought = int(round(max_buyable_this_shop * cfg.buy_rate))
        spent = items_bought * avg_cost
        gold_after = gold_start_of_round - spent

        # 3. Apply purchased items to multipliers.
        per_item_contrib = expected_dps_contrib(level)
        total_contrib = items_bought * per_item_contrib
        if cfg.combine_into_dmg_only:
            dmg_m += total_contrib
        else:
            dmg_m += total_contrib * cfg.dps_split
            aspd_m += total_contrib * (1 - cfg.dps_split)

        cumulative_items += items_bought
        dps = team_dps(dmg_m, aspd_m)
        e_hp = round_enemy_hp(level)
        rtc = e_hp / dps if dps > 0 else float("inf")

        rows.append(RoundState(
            level=level,
            gold_start=gold + income,  # start-of-shop gold
            income=income,
            spent=spent,
            items_bought=items_bought,
            cumulative_items=cumulative_items,
            dmg_m=dmg_m,
            aspd_m=aspd_m,
            dps=dps,
            enemy_hp=e_hp,
            rounds_to_clear=rtc,
            gold_end=gold_after,
        ))
        gold = gold_after

    return rows


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


def print_table(rows: list[RoundState], cfg: SimConfig) -> None:
    print(f"\n=== UNDERLOD balance curve (buy_rate={cfg.buy_rate}, "
          f"dps_split={cfg.dps_split}) ===\n")
    header = (
        f"{'L':>3} {'tier':>5} {'gold':>6} {'inc':>4} {'spent':>6} "
        f"{'buy':>4} {'cum':>4} {'dmgM':>5} {'aspM':>5} {'DPS':>7} "
        f"{'enemyHP':>9} {'clr(s)':>7}"
    )
    print(header)
    print("-" * len(header))
    for r in rows:
        boss_mark = "*" if r.level in BOSS_ROUNDS else " "
        print(
            f"{r.level:>3}{boss_mark}{level_to_tier(r.level):>4.1f} "
            f"{r.gold_start:>6.1f} {r.income:>4} {r.spent:>6.1f} "
            f"{r.items_bought:>4} {r.cumulative_items:>4} "
            f"{r.dmg_m:>5.2f} {r.aspd_m:>5.2f} {r.dps:>7.1f} "
            f"{r.enemy_hp:>9.0f} {r.rounds_to_clear:>7.1f}"
        )
    print("\n* = boss round\n")


def plot(rows: list[RoundState], cfg: SimConfig, out_path: str) -> None:
    import matplotlib.pyplot as plt

    levels = [r.level for r in rows]
    fig, axes = plt.subplots(2, 2, figsize=(13, 8), constrained_layout=True)

    # 1. Gold flow
    ax = axes[0, 0]
    ax.plot(levels, [r.gold_start for r in rows], "-o", label="gold at shop")
    ax.plot(levels, [r.spent for r in rows], "-s", label="spent")
    ax.plot(levels, [r.gold_end for r in rows], "-^", label="gold after buy")
    for b in BOSS_ROUNDS:
        ax.axvline(b, color="grey", alpha=0.2, linestyle="--")
    ax.set_title("Gold per round")
    ax.set_xlabel("Round")
    ax.set_ylabel("Gold")
    ax.legend()
    ax.grid(alpha=0.3)

    # 2. Item count + multipliers
    ax = axes[0, 1]
    ax.plot(levels, [r.cumulative_items for r in rows], "-o", color="tab:purple",
            label="cum items")
    ax.set_xlabel("Round")
    ax.set_ylabel("Cumulative items", color="tab:purple")
    ax.grid(alpha=0.3)
    ax2 = ax.twinx()
    ax2.plot(levels, [r.dmg_m for r in rows], "-s", color="tab:red", label="dmg_m")
    ax2.plot(levels, [r.aspd_m for r in rows], "-^", color="tab:orange", label="aspd_m")
    ax2.set_ylabel("Multiplier sum", color="tab:red")
    for b in BOSS_ROUNDS:
        ax.axvline(b, color="grey", alpha=0.2, linestyle="--")
    ax.set_title("Items bought + stat multipliers")
    lines, labels = ax.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax.legend(lines + lines2, labels + labels2, loc="upper left")

    # 3. Player DPS vs enemy HP per round (log scale)
    ax = axes[1, 0]
    ax.plot(levels, [r.dps for r in rows], "-o", color="tab:blue", label="team DPS")
    ax.plot(levels, [r.enemy_hp for r in rows], "-s", color="tab:red",
            label="round HP burden")
    for b in BOSS_ROUNDS:
        ax.axvline(b, color="grey", alpha=0.2, linestyle="--")
    ax.set_yscale("log")
    ax.set_title("Player DPS vs total enemy HP per round (log)")
    ax.set_xlabel("Round")
    ax.set_ylabel("value (log)")
    ax.legend()
    ax.grid(alpha=0.3, which="both")

    # 4. Rounds-to-clear proxy
    ax = axes[1, 1]
    rtc = [r.rounds_to_clear for r in rows]
    ax.plot(levels, rtc, "-o", color="tab:green")
    for b in BOSS_ROUNDS:
        ax.axvline(b, color="grey", alpha=0.2, linestyle="--")
    ax.set_title("Seconds to clear (HP burden / DPS)")
    ax.set_xlabel("Round")
    ax.set_ylabel("Seconds")
    ax.grid(alpha=0.3)

    fig.suptitle(
        f"UNDERLOD balance curve  |  buy_rate={cfg.buy_rate}  "
        f"dps_split={cfg.dps_split}  starting_gold={cfg.starting_gold}"
    )
    fig.savefig(out_path, dpi=130)
    print(f"saved plot -> {out_path}")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--buy-rate", type=float, default=1.0,
                   help="fraction of affordable items the player actually buys (default 1.0)")
    p.add_argument("--dps-split", type=float, default=0.5,
                   help="fraction of per-item bonus into dmg_m (rest goes to aspd_m)")
    p.add_argument("--starting-gold", type=float, default=STARTING_GOLD)
    p.add_argument("--combine", action="store_true",
                   help="route all per-item bonus into dmg_m (ignores aspd)")
    p.add_argument("--no-plot", action="store_true")
    p.add_argument("--out", default="analysis/balance_curve.png")
    args = p.parse_args()

    cfg = SimConfig(
        buy_rate=args.buy_rate,
        dps_split=args.dps_split,
        starting_gold=args.starting_gold,
        combine_into_dmg_only=args.combine,
    )
    rows = simulate(cfg)
    print_table(rows, cfg)
    if not args.no_plot:
        plot(rows, cfg, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
