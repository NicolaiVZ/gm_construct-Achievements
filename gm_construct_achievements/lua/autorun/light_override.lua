if SERVER then
    -- Wait a bit to make sure light.lua has already loaded.
    timer.Simple(1, function()
        if MakeLight then
            -- Save the original function in a local variable.
            local oldMakeLight = MakeLight
            
            -- Overwrites MakeLight.
            function MakeLight(ply, r, g, b, brght, size, toggle, on, keyDown, Data)
                local light = oldMakeLight(ply, r, g, b, brght, size, toggle, on, keyDown, Data)
                
                if IsValid(light) then
                    -- We run a custom hook that notifies that a light has been created.
                    hook.Run("LightCreated", light)
                end
                
                return light
            end
            
            print("[LightAddon] MakeLight ha sido sobreescrito correctamente.")
        else
            print("[LightAddon] MakeLight no está definido; puede que no se haya cargado aún.")
        end
    end)
end
