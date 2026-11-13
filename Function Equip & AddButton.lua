-- Other Tab (tabs.other)
function unequipPets()
    for _, folder in pairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

function equipPetsByName(name)
    unequipPets()
    task.wait(0.01)
    for _, pet in pairs(lp.player.petsFolder.Unique:GetChildren()) do
        if pet.Name == name then
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

tabs.other:AddButton("Equip Best Rep Pets", function()
    equipBestFarmingPets()
end)
