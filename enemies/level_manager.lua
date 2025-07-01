LevelManager = {}
LevelManager.activeBoss = nil

LevelManager.t1 = 0.75
LevelManager.t2 = 0.50
LevelManager.t3 = 0.25

LevelManager.threshold1 = false
LevelManager.threshold2 = false
LevelManager.threshold3 = false

function LevelManager.init()
    LevelManager.activeBoss = nil

    LevelManager.threshold1 = false
    LevelManager.threshold2 = false
    LevelManager.threshold3 = false
end

function LevelManager.update(dt)
    --only call in arena
    local arena = main.current
    if not arena:is(Arena) then
        return
    end

    if LevelManager.activeBoss then
        LevelManager.bossThresholds()
    end


end

function LevelManager.bossThresholds()
    local boss = LevelManager.activeBoss
    if boss.dead or boss.hp <= 0 then
        LevelManager.activeBoss = nil
        return
    end

    local activateT1 = (boss.hp * 1.0 / boss.max_hp) <  LevelManager.t1 and not LevelManager.threshold1
    local activateT2 = (boss.hp * 1.0 / boss.max_hp) <  LevelManager.t2 and not LevelManager.threshold2
    local activateT3 = (boss.hp * 1.0 / boss.max_hp) <  LevelManager.t3 and not LevelManager.threshold3

    LevelManager.threshold1 = LevelManager.threshold1 or activateT1
    LevelManager.threshold2 = LevelManager.threshold2 or activateT2
    LevelManager.threshold3 = LevelManager.threshold3 or activateT3
    
    if boss.type == 'stompy' then

    elseif boss.type == 'dragon' then
        if activateT1 then
            Spawn_Enemy(main.current, 'dragonegg', SpawnGlobals.mid_spawns[1])
            Spawn_Enemy(main.current, 'dragonegg', SpawnGlobals.mid_spawns[2])
        elseif activateT2 then

        elseif activateT3 then
            Spawn_Enemy(main.current, 'dragonegg', SpawnGlobals.mid_spawns[1])
            Spawn_Enemy(main.current, 'dragonegg', SpawnGlobals.mid_spawns[2])

        end

    elseif boss.type == 'heigan' then

    end

end