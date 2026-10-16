-- Rebirth Tab

tabs.rebirths.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.rebirths.rebirths = tabs.rebirths.leaderstats:WaitForChild("Rebirths")
tabs.rebirths.strength = tabs.rebirths.leaderstats:WaitForChild("Strength")
tabs.rebirths.running = false
tabs.rebirths.workerActive = false
tabs.rebirths.startedAt = 0
tabs.rebirths.timerStarted = false
tabs.rebirths.hasStarted = false
tabs.rebirths.totalElapsed = 0
tabs.rebirths.startRebirths = tabs.rebirths.rebirths.Value
tabs.rebirths.gainedBaselineSet = false
tabs.rebirths.lastRebirthAt = tick()
tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
tabs.rebirths.paceBaselineReady = false
tabs.rebirths.petFolders = {}
tabs.rebirths.pets = {}
tabs.rebirths.uniquePets = {}
tabs.rebirths.omegas = {}
tabs.rebirths.swifts = {}
tabs.rebirths.hounds = {}
tabs.rebirths.hydras = {}
tabs.rebirths.tribals = {}
tabs.rebirths.folderIndex = 1
tabs.rebirths.petIndex = 1
tabs.rebirths.repIndex = 1
tabs.rebirths.equippedCount = 0
tabs.rebirths.currentPercent = 0
tabs.rebirths.maxSlots = 12
tabs.rebirths.strengthTarget = 0
tabs.rebirths.repsPerBurst = 12
tabs.rebirths.rebirthValueBefore = tabs.rebirths.rebirths.Value
tabs.rebirths.Status = tabs.rebirths:AddLabel("Status: Inactive")
tabs.rebirths.Runtime = tabs.rebirths:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.rebirths.RebirthStats = tabs.rebirths:AddLabel("Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value) .. " | Gained: 0")
tabs.rebirths.Pace = tabs.rebirths:AddLabel("Pace: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.AveragePace = tabs.rebirths:AddLabel("Average: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.rebirths.updateStats = function()
    tabs.rebirths.RebirthStats.Text = "Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value)
        .. " | Gained: " .. formatNumber(tabs.rebirths.rebirths.Value - tabs.rebirths.startRebirths)
end

tabs.rebirths.updateRuntime = function()
    tabs.rebirths.elapsed = tabs.rebirths.totalElapsed
    if tabs.rebirths.running and tabs.rebirths.timerStarted then
        tabs.rebirths.elapsed = tabs.rebirths.elapsed + tick() - tabs.rebirths.startedAt
    end

    tabs.rebirths.Runtime.Text = string.format(
        "Runtime: %dd %dh %dm %ds",
        math.floor(tabs.rebirths.elapsed / 86400),
        math.floor((tabs.rebirths.elapsed % 86400) / 3600),
        math.floor((tabs.rebirths.elapsed % 3600) / 60),
        math.floor(tabs.rebirths.elapsed % 60)
    )
end

tabs.rebirths.updatePace = function()
    if not tabs.rebirths.running then
        return
    end

    if not tabs.rebirths.paceBaselineReady then
        tabs.rebirths.paceBaselineReady = true
        tabs.rebirths.timerStarted = true
        tabs.rebirths.startedAt = tick()
        tabs.rebirths.lastRebirthAt = tick()
        tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
        tabs.rebirths.averageStartedAt = tick()
        tabs.rebirths.averageStartRebirths = tabs.rebirths.rebirths.Value
        return
    end

    if tabs.rebirths.rebirths.Value <= tabs.rebirths.lastRebirthValue then
        return
    end

    tabs.rebirths.rebirthGain = tabs.rebirths.rebirths.Value - tabs.rebirths.lastRebirthValue
    tabs.rebirths.secondsPerRebirth = (tick() - tabs.rebirths.lastRebirthAt) / tabs.rebirths.rebirthGain
    tabs.rebirths.hourlyPace = 3600 / tabs.rebirths.secondsPerRebirth
    tabs.rebirths.dailyPace = 86400 / tabs.rebirths.secondsPerRebirth
    tabs.rebirths.weeklyPace = 604800 / tabs.rebirths.secondsPerRebirth

    tabs.rebirths.Pace.Text = string.format(
        "Pace: %s / Hour | %s / Day | %s / Week",
        formatNumber(tabs.rebirths.hourlyPace),
        formatNumber(tabs.rebirths.dailyPace),
        formatNumber(tabs.rebirths.weeklyPace)
    )

    tabs.rebirths.averageElapsed = tick() - tabs.rebirths.averageStartedAt
    tabs.rebirths.averageHourlyPace = (tabs.rebirths.rebirths.Value - tabs.rebirths.averageStartRebirths)
        / tabs.rebirths.averageElapsed * 3600

    tabs.rebirths.AveragePace.Text = string.format(
        "Average: %s / Hour | %s / Day | %s / Week",
        formatNumber(tabs.rebirths.averageHourlyPace),
        formatNumber(tabs.rebirths.averageHourlyPace * 24),
        formatNumber(tabs.rebirths.averageHourlyPace * 168)
    )

    tabs.rebirths.lastRebirthAt = tick()
    tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
end


tabs.rebirths.unequipAllPets = function()
    unequipConfiguredPets()
end

tabs.rebirths.equipFarmingPets = function()
    equipBestFarmingPets()
end

tabs.rebirths.equipRebirthPets = function()
    equipBestRebirthPets()
end

tabs.rebirths.performRebirth = function()
    tabs.rebirths.strengthTarget = 5000 + tabs.rebirths.rebirths.Value * 2550
    tabs.rebirths.repsPerBurst = lp.player.MembershipType == Enum.MembershipType.Premium and 6 or 12

    tabs.rebirths.repIndex = 1
    while tabs.rebirths.running and tabs.rebirths.strength.Value < tabs.rebirths.strengthTarget do
        tabs.rebirths.repIndex = 1
        while tabs.rebirths.repIndex <= tabs.rebirths.repsPerBurst do
            services.muscleEvent:FireServer("rep")
            tabs.rebirths.repIndex = tabs.rebirths.repIndex + 1
        end
        task.wait(0.02)
    end

    if tabs.rebirths.running and tabs.rebirths.strength.Value >= tabs.rebirths.strengthTarget then
        tabs.rebirths.equipRebirthPets()
        task.wait(0.25)
        tabs.rebirths.rebirthValueBefore = tabs.rebirths.rebirths.Value

        repeat
            services.replicatedstorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until tabs.rebirths.rebirths.Value > tabs.rebirths.rebirthValueBefore or not tabs.rebirths.running
    end
end

tabs.rebirths.startWorker = function()
    if tabs.rebirths.workerActive then
        return
    end

    tabs.rebirths.workerActive = true
    task.spawn(function()
        while tabs.rebirths.running do
            tabs.rebirths.equipFarmingPets()
            tabs.rebirths.performRebirth()
            task.wait(0.5)
        end
        tabs.rebirths.workerActive = false
    end)
end

tabs.rebirths.rebirths:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.rebirths.updatePace()
    tabs.rebirths.updateStats()
end)

tabs.rebirths:AddSwitch("Fast Rebirth (Packs & Rep Pets Supported)", function(state)
    tabs.rebirths.running = state
    if state then
        tabs.rebirths.hasStarted = true
        tabs.rebirths.startedAt = 0
        tabs.rebirths.timerStarted = false
        if not tabs.rebirths.gainedBaselineSet then
            tabs.rebirths.startRebirths = tabs.rebirths.rebirths.Value
            tabs.rebirths.gainedBaselineSet = true
        end
        tabs.rebirths.lastRebirthAt = tick()
        tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
        tabs.rebirths.paceBaselineReady = false
        tabs.rebirths.Status.Text = "Status: Rebirthing"
        tabs.rebirths.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.rebirths.updateStats()
        tabs.rebirths.startWorker()
    else
        if tabs.rebirths.timerStarted and tabs.rebirths.startedAt > 0 then
            tabs.rebirths.totalElapsed = tabs.rebirths.totalElapsed + tick() - tabs.rebirths.startedAt
            tabs.rebirths.startedAt = 0
            tabs.rebirths.timerStarted = false
        end
        tabs.rebirths.Status.Text = tabs.rebirths.hasStarted and "Status: Paused" or "Status: Inactive"
        tabs.rebirths.Status.TextColor3 = tabs.rebirths.hasStarted and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.rebirths.updateRuntime()
    end
end):Set(false)

task.spawn(function()
    while true do
        tabs.rebirths.updateRuntime()
        task.wait(1)
    end
end)
