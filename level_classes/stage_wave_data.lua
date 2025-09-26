-- Stage Data Configuration
-- Defines wave generation parameters for each stage (selectable from stage select screen)
-- Stages are identified as difficulty_number (e.g., normal_1, hard_3, extreme_5)
-- 'Level' refers to gameplay progression (increments when you complete stages)


-- Default wave configuration
DEFAULT_WAVE_DURATION = 20  -- seconds for enemies to spawn over
DEFAULT_WAVE_TIMEOUT = 30   -- seconds before forcing wave completion

-- Default power distribution across waves
DEFAULT_WAVE_POWER_SPLITS = {
  [1] = {1.0},        -- 1 wave: 100%
  [2] = {0.4, 0.6},   -- 2 waves: 40%, 60%
  [3] = {0.28, 0.32, 0.4},  -- 3 waves: 28%, 32%, 40%
  [4] = {0.22, 0.24, 0.26, 0.28},  -- 4 waves: 22%, 24%, 26%, 28%
}

LIST_OF_STAGES = {
  'A1',
  'A2',
  'A3',
  'A4',
  'A5',
  'B1',
  'B2',
  'B3',
  'B4',
  'B5',
  'C1',
  'C2',
  'C3',
  'C4',
  'C5',
}

STAGE_DATA = {
  ['A1'] = {
    name = 'A1',
    round_power = 3000,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_enemies = {},
    weapons = {
      ['machine_gun'] = {
        level = 1,
        items = {{procs = {'distance_multiplier'}}},
      }
    }
  },
  ['A2'] = {
    name = 'A2',
    round_power = 5000,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies = {},
    weapons = {
      ['machine_gun'] = {
        level = 1,
        items = {{procs = {'distance_multiplier'}}},
      }
    }
  },
  ['A3'] = {
    name = 'A3',
    round_power = 5000,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {['crossfire'] = 1},
      [2] = {['archer'] = 1, ['crossfire'] = 1},
      [3] = {['crossfire'] = 2},
    },
    weapons = {
      ['machine_gun'] = {
        level = 1,
        items = {{procs = {'distance_multiplier'}}},
      }
    }
  },
  ['A4'] = {
    name = 'A4',
    round_power = 6000,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {['crossfire'] = 2},
      [2] = {['archer'] = 2, ['crossfire'] = 1},
      [3] = {['crossfire'] = 3},
    },
    weapons = {
      ['machine_gun'] = {
        level = 1,
        items = {{procs = {'distance_multiplier'}}},
      }
    }
  },
  ['A5'] = {
    name = 'A5',
    boss = 'stompy',
    weapons = {
      ['machine_gun'] = {
        level = 1,
        items = {{procs = {'distance_multiplier'}}},
      }
    }
  },
}

ORB_HEALTH_BY_DIFFICULTY = {
  normal = 5,
  hard = 3,
  extreme = 3,
}

-- ========================================
-- DIFFICULTY MULTIPLIERS
-- ========================================
DIFFICULTY_MULTIPLIERS = {
  normal = {
    hp = 1.0,
    dmg = 1.0,
    mvspd = 1.0,
    aspd = 1.0,
  },
  hard = {
    hp = 1.5,
    dmg = 1.25,
    mvspd = 1.1,
    aspd = 1.1,
  },
  extreme = {
    hp = 2.0,
    dmg = 1.5,
    mvspd = 1.2,
    aspd = 1.2,
  }
}

-- ========================================
-- ENEMY POWER VALUES
-- ========================================
ENEMY_POWER = {
  -- Swarmers
  ['swarmer'] = 25,
  ['seeker'] = 25,

  ['snake'] = 75,

  -- Basic enemies
  ['shooter'] = 50,
  ['chaser'] = 50,

  -- Special enemies (T1)
  ['archer'] = 75,
  ['burst'] = 75,
  ['turret'] = 75,
  ['cleaver'] = 75,
  ['selfburst'] = 75,
  ['snakearrow'] = 75,
  ['crossfire'] = 75,
  ['spiral'] = 75,
  ['tank'] = 75,
  ['goblin_archer'] = 75,

  -- Special enemies (T1.5)
  ['mortar'] = 75,
  ['singlemortar'] = 75,
  ['line_mortar'] = 75,
  ['aim_spread'] = 75,
  ['charger'] = 75,

  -- Special enemies (T2+)
  ['laser'] = 100,
  ['rager'] = 100,
  ['stomper'] = 100,

  -- Bosses
  ['stompy'] = 500,
  ['dragon'] = 600,
  ['heigan'] = 700,
  ['bigstomper'] = 800,
  ['final_boss'] = 1000,
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
function GET_SWARMERS_PER_GROUP(level)
  return 12
end

function GET_SNAKES_PER_GROUP(level)
  return 1  -- Always 1 snake when spawning snakes
end

function GET_SPECIAL_ENEMIES_PER_GROUP(level)
  return 1
end
-- ========================================
-- API FUNCTIONS
-- ========================================
function Get_Stage_Data(stage_id)
  return STAGE_DATA[stage_id] or STAGE_DATA['A1']
end

function Get_Stage_Round_Power(stage_id)
  local data = Get_Stage_Data(stage_id)
  return data.round_power
end

function Get_Stage_Enemy_Stats_Multiplier(stage_id, difficulty)
  local data = Get_Stage_Data(stage_id)
  if data.difficulty and data.difficulty.enemy_stats then
    return data.difficulty.enemy_stats
  end
  return DIFFICULTY_MULTIPLIERS[difficulty] or DIFFICULTY_MULTIPLIERS['normal']
end

function Stage_Has_Boss(stage_id)
  local data = Get_Stage_Data(stage_id)
  return data and data.boss ~= nil
end

function Get_Stage_Boss(stage_id)
  local data = Get_Stage_Data(stage_id)
  return data and data.boss
end

function Get_Stage_Spawnable_Enemies(stage_id)
  local data = Get_Stage_Data(stage_id)
  return {
    normal = data.normal_enemies or {},
    special = data.special_enemies or {},
  }
end

function Get_Stage_Orb_Health(stage_id, difficulty)
  local data = Get_Stage_Data(stage_id)
  if data.difficulty and data.difficulty.orb_health then
    return data.difficulty.orb_health
  elseif data.orb_health then
    return data.orb_health
  end
  return ORB_HEALTH_BY_DIFFICULTY[difficulty] or ORB_HEALTH_BY_DIFFICULTY['normal']
end