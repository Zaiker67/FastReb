-- Settings Tab

settingsTab.leaderstats = lp.player:WaitForChild("leaderstats")
settingsTab.rebirths = settingsTab.leaderstats:WaitForChild("Rebirths")
settingsTab.strength = settingsTab.leaderstats:WaitForChild("Strength")
settingsTab.running = false
settingsTab.workerActive = false
settingsTab.startedAt = 0
settingsTab.timerStarted = false
settingsTab.hasStarted = false
settingsTab.totalElapsed = 0
settingsTab.startRebirths = settingsTab.rebirths.Value
settingsTab.gainedBaselineSet = false
settingsTab.lastRebirthAt = tick()
settingsTab.lastRebirthValue = settingsTab.rebirths.Value
settingsTab.paceBaselineReady = false
settingsTab.petFolders = {}
settingsTab.pets = {}
settingsTab.uniquePets = {}
settingsTab.omegas = {}
settingsTab.swifts = {}
settingsTab.hounds = {}
settingsTab.hydras = {}
settingsTab.tribals = {}
settingsTab.folderIndex = 1
settingsTab.petIndex = 1
settingsTab.repIndex = 1
settingsTab.equippedCount = 0
settingsTab.currentPercent = 0
settingsTab.maxSlots = 12
settingsTab.strengthTarget = 0
settingsTab.repsPerBurst = 12
settingsTab.rebirthValueBefore = settingsTab.rebirths.Value
settingsTab.Status = settingsTab:AddLabel("Status: Inactive")
settingsTab.Runtime = settingsTab:AddLabel("Runtime: 0d 0h 0m 0s")
settingsTab.RebirthStats = settingsTab:AddLabel("Rebirths: " .. formatCurrentStat(settingsTab.rebirths.Value) .. " | Gained: 0")
settingsTab.Pace = settingsTab:AddLabel("Pace: -- / Hour | -- / Day | -- / Week")
settingsTab.AveragePace = settingsTab:AddLabel("Average: -- / Hour | -- / Day | -- / Week")
settingsTab.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

settingsTab.updateStats = function()
    settingsTab.RebirthStats.Text = "Rebirths: " .. formatCurrentStat(settingsTab.rebirths.Value)
        .. " | Gained: " .. formatNumber(settingsTab.rebirths.Value - settingsTab.startRebirths)
end

settingsTab.updateRuntime = function()
    settingsTab.elapsed = settingsTab.totalElapsed
    if settingsTab.running and settingsTab.timerStarted then
        settingsTab.elapsed = settingsTab.elapsed + tick() - settingsTab.startedAt
    end

    settingsTab.Runtime.Text = string.format(
        "Runtime: %dd %dh %dm %ds",
        math.floor(settingsTab.elapsed / 86400),
        math.floor((settingsTab.elapsed % 86400) / 3600),
        math.floor((settingsTab.elapsed % 3600) / 60),
        math.floor(settingsTab.elapsed % 60)
    )
end

settingsTab.updatePace = function()
    if not settingsTab.running then
        return
    end

    if not settingsTab.paceBaselineReady then
        settingsTab.paceBaselineReady = true
        settingsTab.timerStarted = true
        settingsTab.startedAt = tick()
        settingsTab.lastRebirthAt = tick()
        settingsTab.lastRebirthValue = settingsTab.rebirths.Value
        settingsTab.averageStartedAt = tick()
        settingsTab.averageStartRebirths = settingsTab.rebirths.Value
        return
    end

    if settingsTab.rebirths.Value <= settingsTab.lastRebirthValue then
        return
    end

    settingsTab.rebirthGain = settingsTab.rebirths.Value - settingsTab.lastRebirthValue
    settingsTab.secondsPerRebirth = (tick() - settingsTab.lastRebirthAt) / settingsTab.rebirthGain
    settingsTab.hourlyPace = 3600 / settingsTab.secondsPerRebirth
    settingsTab.dailyPace = 86400 / settingsTab.secondsPerRebirth
    settingsTab.weeklyPace = 604800 / settingsTab.secondsPerRebirth

    settingsTab.Pace.Text = string.format(
        "Pace: %s / Hour | %s / Day | %s / Week",
        formatNumber(settingsTab.hourlyPace),
        formatNumber(settingsTab.dailyPace),
        formatNumber(settingsTab.weeklyPace)
    )

    settingsTab.averageElapsed = tick() - settingsTab.averageStartedAt
    settingsTab.averageHourlyPace = (settingsTab.rebirths.Value - settingsTab.averageStartRebirths)
        / settingsTab.averageElapsed * 3600

    settingsTab.AveragePace.Text = string.format(
        "Average: %s / Hour | %s / Day | %s / Week",
        formatNumber(settingsTab.averageHourlyPace),
        formatNumber(settingsTab.averageHourlyPace * 24),
        formatNumber(settingsTab.averageHourlyPace * 168)
    )

    settingsTab.lastRebirthAt = tick()
    settingsTab.lastRebirthValue = settingsTab.rebirths.Value
end


settingsTab.unequipAllPets = function()
    unequipConfiguredPets()
end

settingsTab.equipFarmingPets = function()
    equipBestFarmingPets()
end

settingsTab.equipRebirthPets = function()
    equipBestRebirthPets()
end

settingsTab.performRebirth = function()
    settingsTab.strengthTarget = 5000 + settingsTab.rebirths.Value * 2550
    settingsTab.repsPerBurst = lp.player.MembershipType == Enum.MembershipType.Premium and 6 or 12

    settingsTab.repIndex = 1
    while settingsTab.running and settingsTab.strength.Value < settingsTab.strengthTarget do
        settingsTab.repIndex = 1
        while settingsTab.repIndex <= settingsTab.repsPerBurst do
            services.muscleEvent:FireServer("rep")
            settingsTab.repIndex = settingsTab.repIndex + 1
        end
        task.wait(0.02)
    end

    if settingsTab.running and settingsTab.strength.Value >= settingsTab.strengthTarget then
        settingsTab.equipRebirthPets()
        task.wait(0.25)
        settingsTab.rebirthValueBefore = settingsTab.rebirths.Value

        repeat
            services.replicatedstorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until settingsTab.rebirths.Value > settingsTab.rebirthValueBefore or not settingsTab.running
    end
end

settingsTab.startWorker = function()
    if settingsTab.workerActive then
        return
    end

    settingsTab.workerActive = true
    task.spawn(function()
        while settingsTab.running do
            settingsTab.equipFarmingPets()
            settingsTab.performRebirth()
            task.wait(0.5)
        end
        settingsTab.workerActive = false
    end)
end

settingsTab.rebirths:GetPropertyChangedSignal("Value"):Connect(function()
    settingsTab.updatePace()
    settingsTab.updateStats()
end)

settingsTab:AddSwitch("Fast Rebirth (Packs & Rep Pets Supported)", function(state)
    settingsTab.running = state
    if state then
        settingsTab.hasStarted = true
        settingsTab.startedAt = 0
        settingsTab.timerStarted = false
        if not settingsTab.gainedBaselineSet then
            settingsTab.startRebirths = settingsTab.rebirths.Value
            settingsTab.gainedBaselineSet = true
        end
        settingsTab.lastRebirthAt = tick()
        settingsTab.lastRebirthValue = settingsTab.rebirths.Value
        settingsTab.paceBaselineReady = false
        settingsTab.Status.Text = "Status: Rebirthing"
        settingsTab.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        settingsTab.updateStats()
        settingsTab.startWorker()
    else
        if settingsTab.timerStarted and settingsTab.startedAt > 0 then
            settingsTab.totalElapsed = settingsTab.totalElapsed + tick() - settingsTab.startedAt
            settingsTab.startedAt = 0
            settingsTab.timerStarted = false
        end
        settingsTab.Status.Text = settingsTab.hasStarted and "Status: Paused" or "Status: Inactive"
        settingsTab.Status.TextColor3 = settingsTab.hasStarted and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        settingsTab.updateRuntime()
    end
end):Set(false)

task.spawn(function()
    while true do
        settingsTab.updateRuntime()
        task.wait(1)
    end
end)
