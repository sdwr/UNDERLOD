-- Stage Data Configuration
-- Defines wave generation parameters for each stage (selectable from stage select screen)
-- Stages are identified as difficulty_number (e.g., normal_1, hard_3, extreme_5)
-- 'Level' refers to gameplay progression (increments when you complete stages)


-- Default wave configuration
DEFAULT_WAVE_DURATION = 20  -- seconds for enemies to spawn over
DEFAULT_WAVE_TIMEOUT = 60   -- seconds before forcing wave completion

-- Default power distribution across waves
DEFAULT_WAVE_POWER_SPLITS = {
  [1] = {1.0},        -- 1 wave: 100%
  [2] = {0.4, 0.6},   -- 2 waves: 40%, 60%
  [3] = {0.24, 0.3, 0.46},  -- 3 waves: 28%, 32%, 40%
  [4] = {0.22, 0.24, 0.26, 0.28},  -- 4 waves: 22%, 24%, 26%, 28%
  [5] = {1.0},
}

LIST_OF_STAGES = {
  'A_1',
  'A_2',
  'A_3',
  'A_4',
  'A_5',
  'B_1',
  'B_2',
  'B_3',
  'B_4',
  'B_5',
  'C_1',
  'C_2',
  'C_3',
  'C_4',
  'C_5',
}

STAGE_DATA = {
  ['A_1'] = {
    name = 'A_1',
    round_power = 4800,
    number_of_waves = 1,
    wave_duration = 13,
    normal_enemies = {'swarmer'},
    special_enemies = {},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['A_2'] = {
    name = 'A_2',
    round_power = 12000,
    number_of_waves = 2,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['A_3'] = {
    name = 'A_3',
    round_power = 16000,
    number_of_waves = 2,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['A_4'] = {
    name = 'A_4',
    round_power = 16000,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {['crossfire'] = 2},
      [2] = {['bomber'] = 2, ['crossfire'] = 1},
      [3] = {['crossfire'] = 2, ['bomber'] = 2},
    },
    snake_enemies_by_wave = {
      [1] = {['snake'] = 2},
      [2] = {['snake'] = 2},
      [3] = {['snake'] = 3},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['A_5'] = {
    name = 'A_5',
    boss = 'stompy',
    round_power = 4000,
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['B_1'] = {
    name = 'B_1',
    round_power = 5600,
    number_of_waves = 1,
    normal_enemies = {'seeker'},
    special_enemies = {},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['B_2'] = {
    name = 'B_2',
    round_power = 10000,
    number_of_waves = 2,
    normal_enemies = {'seeker'},
    special_seeker_types = {['touch'] = 4},
    special_enemies_by_wave = {
      [1] = {},
      [2] = {['laser'] = 2},
    },
    snake_enemies_by_wave = {
      [1] = {['big_touch'] = 1},
      [2] = {['big_touch'] = 1},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['B_3'] = {
    name = 'B_3',
    round_power = 12000,
    number_of_waves = 2,
    normal_enemies = {'seeker'},
    special_seeker_types = {['touch'] = 4},
    special_enemies_by_wave = {
      [1] = {['laser'] = 1, ['snakearrow'] = 1},
      [2] = {['laser'] = 2, ['snakearrow'] = 2},
    },
    snake_enemies_by_wave = {
      [1] = {['big_touch'] = 2},
      [2] = {['big_touch'] = 2},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['B_4'] = {
    name = 'B_4',
    round_power = 14000,
    number_of_waves = 3,
    normal_enemies = {'seeker'},
    special_seeker_types = {['touch'] = 4},
    special_enemies_by_wave = {
      [1] = {['laser'] = 1, ['snakearrow'] = 2},
      [2] = {['laser'] = 2, ['snakearrow'] = 2},
      [3] = {['laser'] = 2, ['snakearrow'] = 3},
    },
    snake_enemies_by_wave = {
      [1] = {['big_touch'] = 2},
      [2] = {['big_touch'] = 2},
      [3] = {['big_touch'] = 3},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['B_5'] = {
    name = 'B_5',
    round_power = 4000,
    boss = 'snake_boss',
    number_of_waves = 1,
    normal_enemies = {'seeker'},
    special_enemies = {},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['C_1'] = {
    name = 'C_1',
    round_power = 6400,
    number_of_waves = 1,
    wave_duration = 13,
    normal_enemies = {'swarmer'},
    special_enemies = {},
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['C_2'] = {
    name = 'C_2',
    round_power = 12800,
    number_of_waves = 2,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {},
      [2] = {['mortar'] = 2}
    },
    snake_enemies_by_wave = {
      [1] = {['net'] = 6},
      [2] = {['net'] = 6},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['C_3'] = {
    name = 'C_3',
    round_power = 16800,
    number_of_waves = 2,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {['arcspread'] = 2, ['mortar'] = 1},
      [2] = {['mortar'] = 2, ['arcspread'] = 2}
    },
    snake_enemies_by_wave = {
      [1] = {['net'] = 6},
      [2] = {['net'] = 8},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['C_4'] = {
    name = 'C_4',
    round_power = 16800,
    number_of_waves = 3,
    normal_enemies = {'swarmer'},
    special_swarmer_types = {['touch'] = 8},
    special_enemies_by_wave = {
      [1] = {['mortar'] = 2},
      [2] = {['arcspread'] = 2, ['mortar'] = 1},
      [3] = {['mortar'] = 2, ['arcspread'] = 2},
    },
    snake_enemies_by_wave = {
      [1] = {['net'] = 6},
      [2] = {['net'] = 8},
      [3] = {['net'] = 8},
    },
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
  ['C_5'] = {
    name = 'C_5',
    round_power = 4000,
    boss = 'dragon',
    weapons = {
      ['sword'] = {
        level = 1,
        items = {},
      }
    }
  },
}

function Get_Stage_Weapons(stage_id)
  local data = Get_Stage_Data(stage_id)
  return data.weapons
end

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
  ['big_touch'] = 75,
  ['net'] = 75,

  -- Basic enemies
  ['shooter'] = 50,
  ['chaser'] = 50,

  -- Special enemies (T1)
  ['archer'] = 75,
  ['bomber'] = 75,
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
  if STAGE_DATA[stage_id] then
    return STAGE_DATA[stage_id]
  end
  local data = deepcopy(STAGE_DATA['A_1'])
  data.name = stage_id
  return data
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