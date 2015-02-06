--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcSoilModPlugins = {}

local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcSoilModPlugins.version = (modItem and modItem.version) and modItem.version or "?.?.?";


-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod2Plugins"] = getfenv(0)["modSoilMod2Plugins"] or {}
table.insert(getfenv(0)["modSoilMod2Plugins"], fmcSoilModPlugins)

--
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function fmcSoilModPlugins.soilModPluginCallback(soilMod,settings)

    --
    fmcSoilModPlugins.reduceWindrows        = settings.getKeyAttrValue("plugins.fmcSoilModPlugins",  "reduceWindrows",      true)
    fmcSoilModPlugins.removeSprayMoisture   = settings.getKeyAttrValue("plugins.fmcSoilModPlugins",  "removeSprayMoisture", true)

    --
    settings.setKeyAttrValue("plugins.fmcSoilModPlugins",  "reduceWindrows",         fmcSoilModPlugins.reduceWindrows     )
    settings.setKeyAttrValue("plugins.fmcSoilModPlugins",  "removeSprayMoisture",    fmcSoilModPlugins.removeSprayMoisture)

    log("reduceWindrows=",fmcSoilModPlugins.reduceWindrows,", removeSprayMoisture=",fmcSoilModPlugins.removeSprayMoisture)
    
    -- Gather the required special foliage-layers for Soil Management & Growth Control.
    local allOK = fmcSoilModPlugins.setupFoliageLayers()

    if allOK then
        -- Using SoilMod's plugin facility, we add SoilMod's own effects for each of the particular "Utils." functions
        -- To keep my own sanity, all the plugin-functions for each particular "Utils." function, have their own block:
        fmcSoilModPlugins.pluginsForCutFruitArea(        soilMod)
        fmcSoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
        fmcSoilModPlugins.pluginsForUpdatePloughArea(    soilMod)
        fmcSoilModPlugins.pluginsForUpdateSowingArea(    soilMod)
        fmcSoilModPlugins.pluginsForUpdateSprayArea(     soilMod)
        -- And for the 'growth-cycle' plugins:
        fmcSoilModPlugins.pluginsForGrowthCycle(         soilMod)
    end

    return allOK

end

--
local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
end

--
function fmcSoilModPlugins.setupFoliageLayers()
    -- Get foliage-layers that contains visible graphics (i.e. has material that uses shaders)
    g_currentMission.fmcFoliageManure       = g_currentMission:loadFoliageLayer("fmc_manure",     -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageSlurry       = g_currentMission:loadFoliageLayer("fmc_slurry",     -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageWeed         = g_currentMission:loadFoliageLayer("fmc_weed",       -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageLime         = g_currentMission:loadFoliageLayer("fmc_lime",       -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageFertilizer   = g_currentMission:loadFoliageLayer("fmc_fertilizer", -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageHerbicide    = g_currentMission:loadFoliageLayer("fmc_herbicide",  -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageWater        = g_currentMission:loadFoliageLayer("fmc_water",      -5, -1, true, "alphaBlendStartEnd")

    ---- Get foliage-layers that are invisible (i.e. has viewdistance=0 and a material that is "blank")
    g_currentMission.fmcFoliageSoil_pH          = getChild(g_currentMission.terrainRootNode, "fmc_soil_pH"      )
    g_currentMission.fmcFoliageFertN            = getChild(g_currentMission.terrainRootNode, "fmc_fertN"        )
    g_currentMission.fmcFoliageFertPK           = getChild(g_currentMission.terrainRootNode, "fmc_fertPK"       )
    g_currentMission.fmcFoliageMoisture         = getChild(g_currentMission.terrainRootNode, "fmc_moisture"     )
    g_currentMission.fmcFoliageHerbicideTime    = getChild(g_currentMission.terrainRootNode, "fmc_herbicideTime")

    -- Add the non-visible foliage-layer to be saved too.
    table.insert(g_currentMission.dynamicFoliageLayers, g_currentMission.fmcFoliageSoil_pH)
    
    --
    local function verifyFoliage(foliageName, foliageId, reqChannels)
        local numChannels
        if hasFoliageLayer(foliageId) then
                  numChannels    = getTerrainDetailNumChannels(foliageId)
            local terrainSize    = getTerrainSize(foliageId)
            local densityMapSize = getDensityMapSize(foliageId)
            if numChannels == reqChannels then
                logInfo("Foliage-layer check ok: '",foliageName,"'"
                    ,",id=",        foliageId
                    ,",numChnls=",  numChannels
                    ,",size=",      terrainSize,"/",densityMapSize
                    ,",parent=",    getParent(foliageId)
                )
                return true
            end
        end;
        logInfo("ERROR! Required foliage-layer '",foliageName,"' either does not exist (foliageId=",foliageId,"), or have wrong num-channels (",numChannels,")")
        return false
    end

    local allOK = true
    allOK = verifyFoliage("fmc_manure"              ,g_currentMission.fmcFoliageManure              ,2) and allOK;
    allOK = verifyFoliage("fmc_slurry"              ,g_currentMission.fmcFoliageSlurry              ,2) and allOK;
    allOK = verifyFoliage("fmc_weed"                ,g_currentMission.fmcFoliageWeed                ,4) and allOK;
    allOK = verifyFoliage("fmc_lime"                ,g_currentMission.fmcFoliageLime                ,1) and allOK;
    allOK = verifyFoliage("fmc_fertilizer"          ,g_currentMission.fmcFoliageFertilizer          ,3) and allOK;
    allOK = verifyFoliage("fmc_herbicide"           ,g_currentMission.fmcFoliageHerbicide           ,2) and allOK;
    allOK = verifyFoliage("fmc_water"               ,g_currentMission.fmcFoliageWater               ,2) and allOK;
    
    allOK = verifyFoliage("fmc_soil_pH"             ,g_currentMission.fmcFoliageSoil_pH             ,4) and allOK;
    allOK = verifyFoliage("fmc_fertN"               ,g_currentMission.fmcFoliageFertN               ,4) and allOK;
    allOK = verifyFoliage("fmc_fertPK"              ,g_currentMission.fmcFoliageFertPK              ,3) and allOK;
    allOK = verifyFoliage("fmc_moisture"            ,g_currentMission.fmcFoliageMoisture            ,3) and allOK;
    allOK = verifyFoliage("fmc_herbicideTime"       ,g_currentMission.fmcFoliageHerbicideTime       ,2) and allOK;
    
    return allOK
end

--
function fmcSoilModPlugins.pluginsForCutFruitArea(soilMod)
    --
    -- Additional effects for the Utils.CutFruitArea()
    --

    --
    soilMod.addPlugin_CutFruitArea_after(
        "Volume affected if partial-growth-state for crop",
        5,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if fruitDesc.allowsPartialGrowthState then
                dataStore.volume = dataStore.pixelsSum / fruitDesc.maxHarvestingGrowthState
            end
        end
    )
    
    ---- Special case; if fertN layer is not there, then add the default "double yield from spray layer" effect.
    if not hasFoliageLayer(g_currentMission.fmcFoliageFertN) then
        soilMod.addPlugin_CutFruitArea_before(
            "Remove spray where min/max-harvesting-growth-state is",
            5,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.destroySpray then
                    setDensityMaskParams(g_currentMission.terrainDetailId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                    dataStore.spraySum = setDensityMaskedParallelogram(
                        g_currentMission.terrainDetailId, 
                        sx,sz,wx,wz,hx,hz, 
                        g_currentMission.sprayChannel, 1, 
                        dataStore.fruitFoliageId, 0, g_currentMission.numFruitStateChannels, 
                        0 -- value
                    );
                    setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
                end
            end
        )
    end
        
    --
    soilMod.addPlugin_CutFruitArea_before(
        "Set sowing-channel where min/max-harvesting-growth-state is",
        10,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if fruitDesc.useSeedingWidth and (dataStore.destroySeedingWidth == nil or dataStore.destroySeedingWidth) then
                setDensityMaskParams(g_currentMission.terrainDetailId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState); 
                setDensityMaskedParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    dataStore.fruitFoliageId, 0, g_currentMission.numFruitStateChannels, 
                    2^g_currentMission.sowingChannel  -- value
                );
                setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
            end
        end
    )

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get weed density and cut weed",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get weeds, but only the lower 2 bits (values 0-3), and then set them to zero.
                -- This way weed gets cut, but alive weed will still grow again.
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", 0);
                dataStore.weeds = {}
                dataStore.weeds.oldSum, dataStore.weeds.numPixels, dataStore.weeds.newDelta = setDensityParallelogram(
                    g_currentMission.fmcFoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0,2,
                    0 -- value
                )
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", -1);
            end
        )
        
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by percentage of weeds",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.weeds.numPixels > 0 then
                    local weedPct = (dataStore.weeds.oldSum / (3 * dataStore.weeds.numPixels)) * (dataStore.weeds.numPixels / dataStore.numPixels)
                    -- Remove some volume that weeds occupy.
                    dataStore.volume = math.max(0, dataStore.volume - (dataStore.volume * weedPct))
                end
            end
        )
    end
    
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageFertN) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get N density",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get N
                --setDensityMaskParams(g_currentMission.fmcFoliageFertN, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.fertN = {}
                dataStore.fertN.oldSum, dataStore.fertN.numPixels, dataStore.fertN.newDelta = getDensityParallelogram(
                    g_currentMission.fmcFoliageFertN, 
                    sx,sz,wx,wz,hx,hz,
                    0,4
                    --dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels
                )
                --setDensityMaskParams(g_currentMission.fmcFoliageFertN, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by N",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- SoilManagement does not use spray for "yield".
                dataStore.spraySum = 0
                --
                if dataStore.fertN.numPixels > 0 then
                    local nutrientLevel = dataStore.fertN.oldSum / dataStore.fertN.numPixels
                    -- If nutrition available, then increase volume by 50%-100%
                    if nutrientLevel > 0 then
                        dataStore.volume = dataStore.volume * math.min(2, nutrientLevel+1.5)
                    end
                end
            end
        )
    end
    
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get PK density",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get PK and reduce.
                --setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.fertPK = {}
                dataStore.fertPK.oldSum, dataStore.fertPK.numPixels, dataStore.fertPK.newDelta = getDensityParallelogram(
                    g_currentMission.fmcFoliageFertPK, 
                    sx,sz,wx,wz,hx,hz,
                    0,3
                    --dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                    ---1 -- decrease
                )
                --setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is slightly boosted by PK",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                local fertPct = (dataStore.fertPK.numPixels > 0) and (dataStore.fertPK.oldSum / dataStore.fertPK.numPixels) or 0
                local volumeBoost = (dataStore.numPixels * fertPct)
                dataStore.volume = dataStore.volume + volumeBoost
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then

        -- TODO - Try to add for different fruit-types.
        fmcSoilModPlugins.pHCurve = AnimCurve:new(linearInterpolator1)
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.20, time= 0 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.70, time= 1 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.80, time= 2 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.85, time= 3 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.90, time= 4 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.94, time= 5 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.97, time= 6 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=1.00, time= 7 }) -- neutral
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.98, time= 8 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.95, time= 9 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.91, time=10 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.87, time=11 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.84, time=12 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.80, time=13 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.76, time=14 })
        fmcSoilModPlugins.pHCurve:addKeyframe({ v=0.50, time=15 })
    
    
        soilMod.addPlugin_CutFruitArea_before(
            "Get soil pH density",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get soil pH
                --setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.soilpH = {}
                dataStore.soilpH.sumPixels, dataStore.soilpH.numPixels, dataStore.soilpH.totPixels = getDensityParallelogram(
                    g_currentMission.fmcFoliageSoil_pH, 
                    sx,sz,wx,wz,hx,hz,
                    0,4
                    --dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels
                )
                --setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by soil pH level",
            50,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                local pHFactor = (dataStore.soilpH.totPixels > 0) and (dataStore.soilpH.sumPixels / dataStore.soilpH.totPixels) or 7
                local factor = fmcSoilModPlugins.pHCurve:get(pHFactor)
--log("soil pH: s",dataStore.soilpH.sumPixels," n",dataStore.soilpH.numPixels," t",dataStore.soilpH.totPixels," / f",pHFactor," c",factor)
                dataStore.volume = dataStore.volume * (factor or 1)
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageMoisture) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get water-moisture",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                --setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.moisture = {}
                dataStore.moisture.sumPixels, dataStore.moisture.numPixels, dataStore.moisture.totPixels = getDensityParallelogram(
                    g_currentMission.fmcFoliageMoisture, 
                    sx,sz,wx,wz,hx,hz,
                    0,3
                    --dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                )
                --setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "greater", -1);
            end
        )

        fmcSoilModPlugins.moistureCurve = AnimCurve:new(linearInterpolator1)
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.70, time=0 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.88, time=1 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.94, time=2 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.98, time=3 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=1.10, time=4 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.96, time=5 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.93, time=6 })
        fmcSoilModPlugins.moistureCurve:addKeyframe({ v=0.70, time=7 })        

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by water-moisture",
            70,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                local moistureFactor = (dataStore.moisture.totPixels > 0) and (dataStore.moisture.sumPixels / dataStore.moisture.totPixels) or 4
                local factor = fmcSoilModPlugins.moistureCurve:get(moistureFactor)
--log("moisture: s",dataStore.moisture.sumPixels," n",dataStore.moisture.numPixels," t",dataStore.moisture.totPixels," / f",moistureFactor," c",factor)
                dataStore.volume = dataStore.volume * (factor or 1)
            end
        )
    end
    
    ---- Issue #26. MoreRealistic's OverrideCutterAreaEvent.LUA will multiply volume with 1.5
    ---- if not sprayed, where the normal game multiply with 1.0. - However both methods will 
    ---- multiply with 2.0 in case the spraySum is greater than zero. - So to fix this, this 
    ---- plugin for SoilMod will make CutFruitArea return half the volume and have spraySum 
    ---- greater than zero.
    --soilMod.addPlugin_CutFruitArea_after(
    --    "Fix for MoreRealistic multiplying volume by 1.5, where SoilMod expects it to be 1.0",
    --    9999, -- This plugin MUST be the last one, before 'CutFruitArea' returns!
    --    function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)    
    --        dataStore.volume = dataStore.volume / 2
    --        dataStore.spraySum = 1
    --        
    --      -- Below didn't work correctly. Causes problem when graintank less than 5% and there's weed plants.
    --      -- -- Fix for multiplayer, to ensure that event will be sent to clients, if there was something to cut.
    --      -- if (dataStore.numPixels > 0) or (dataStore.weeds ~= nil and dataStore.weeds.numPixels > 0) then
    --      --     dataStore.volume = dataStore.volume + 0.0000001
    --      -- end
    --      
    --      -- Thinking of a different approach, to send "cut"-event to clients when volume == 0 and (numPixels > 0 or weed > 0),
    --      -- where a "global variable" will be set, and then afterwards elsewhere it is tested to see if an event should be sent,
    --      -- but it requires appending extra functionality to Combine.update() and similar vanilla methods, which may cause even other problems.
    --    end
    --)
end

--
fmcSoilModPlugins.fmcTYPE_UNKNOWN    = 0
fmcSoilModPlugins.fmcTYPE_PLOUGH     = 2^0
fmcSoilModPlugins.fmcTYPE_CULTIVATOR = 2^1
fmcSoilModPlugins.fmcTYPE_SEEDER     = 2^2

--
function fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, isForced, implementType)
    -- Increase FertN where there's solidManure
    setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.fmcFoliageManure, 0, 2, (implementType==fmcSoilModPlugins.fmcTYPE_PLOUGH and 10 or 6));

    setDensityTypeIndexCompareMode(g_currentMission.fruits[1].id, 2) -- COMPARE_NONE
        ---- Increase FertN where there's windrow
        --setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.fruits[1].id, 8,g_currentMission.numWindrowChannels, 1); -- TODO - assumes that all fruit's windrow starts at channel 8.
        ---- Increase FertN where there's crops at growth-stage 3-8
        setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "between", 3, 8)
        addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.fruits[1].id, 0,g_currentMission.numFruitStateChannels, 4);
    setDensityTypeIndexCompareMode(g_currentMission.fruits[1].id, 0) -- COMPARE_EQUAL
    
    -- Increase soil pH where there's lime
    setDensityMaskParams(         g_currentMission.fmcFoliageSoil_pH, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.fmcFoliageSoil_pH,  sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.fmcFoliageLime, 0, 1, 4);

    -- Special case for slurry, due to ZunHammer and instant cultivating.
    setDensityMaskParams(         g_currentMission.fmcFoliageSlurry, "equals", 1);
    setDensityMaskedParallelogram(g_currentMission.fmcFoliageSlurry, sx,sz,wx,wz,hx,hz, 0,2, g_currentMission.fmcFoliageSlurry, 0,1, 2)
    
    -- Remove the manure/lime we've just cultivated/ploughed into ground.
    setDensityParallelogram(g_currentMission.fmcFoliageManure, sx,sz,wx,wz,hx,hz, 0, 2, 0)
    setDensityParallelogram(g_currentMission.fmcFoliageLime,   sx,sz,wx,wz,hx,hz, 0, 1, 0)
    -- Remove weed plants - where we're cultivating/ploughing.
    setDensityParallelogram(g_currentMission.fmcFoliageWeed,   sx,sz,wx,wz,hx,hz, 0, 4, 0)
end

--
function fmcSoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateCultivatorArea()
    --

    soilMod.addPlugin_UpdateCultivatorArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.fmcUpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, fmcSoilModPlugins.fmcTYPE_CULTIVATOR);
        end
    )

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.fmcFoliageManure)
    and hasFoliageLayer(g_currentMission.fmcFoliageSlurry)
    and hasFoliageLayer(g_currentMission.fmcFoliageLime)
    and hasFoliageLayer(g_currentMission.fmcFoliageWeed)
    and hasFoliageLayer(g_currentMission.fmcFoliageFertN)
    then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for SoilMod",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, fmcSoilModPlugins.fmcTYPE_CULTIVATOR)
            end
        )
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizer) then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Cultivator changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
            41,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Where 'greater than 4', then set most-significant-bit to zero
                setDensityMaskParams(         g_currentMission.fmcFoliageFertilizer, "greater", 4)
                setDensityMaskedParallelogram(g_currentMission.fmcFoliageFertilizer,           sx,sz,wx,wz,hx,hz, 2, 1, g_currentMission.fmcFoliageFertilizer, 0, 3, 0);
                setDensityMaskParams(         g_currentMission.fmcFoliageFertilizer, "greater", 0)
            end
        )
    end
    
end

--
function fmcSoilModPlugins.pluginsForUpdatePloughArea(soilMod)
    --
    -- Additional effects for the Utils.UpdatePloughArea()
    --

    soilMod.addPlugin_UpdatePloughArea_before(
        "Destroy common area",
        30,function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.fmcUpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, fmcSoilModPlugins.fmcTYPE_PLOUGH);
        end
    )

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.fmcFoliageManure)
    and hasFoliageLayer(g_currentMission.fmcFoliageSlurry)
    and hasFoliageLayer(g_currentMission.fmcFoliageLime)
    and hasFoliageLayer(g_currentMission.fmcFoliageWeed)
    and hasFoliageLayer(g_currentMission.fmcFoliageFertN)
    then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Update foliage-layer for SoilMod",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, fmcSoilModPlugins.fmcTYPE_PLOUGH)
            end
        )
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizer) then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Ploughing changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
            41,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Where 'greater than 4', then set most-significant-bit to zero
                setDensityMaskParams(         g_currentMission.fmcFoliageFertilizer, "greater", 4)
                setDensityMaskedParallelogram(g_currentMission.fmcFoliageFertilizer,           sx,sz,wx,wz,hx,hz, 2, 1, g_currentMission.fmcFoliageFertilizer, 0, 3, 0);
                setDensityMaskParams(         g_currentMission.fmcFoliageFertilizer, "greater", 0)
            end
        )
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageWater) then
        soilMod.addPlugin_UpdatePloughArea_after(
            "Plouging should reduce water-level",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                setDensityParallelogram(g_currentMission.fmcFoliageWater, sx,sz,wx,wz,hx,hz, 0,2, 1);
            end
        )
    end
    
    -- Attempt at adding stones randomly appearing when ploughing.
    -- Unfortunately it won't work, for two reasons:
    -- - Using "math.random" client-side, will produce different results compared to server,
    --   so it will not be the same areas that gets affected.
    -- - Even when the equipment/tool is not moving, it will still continuously call
    --   Utils.updatePloughArea(), thereby causing "flickering" of the terrain.
    --local stoneFoliageLayerId = getChild(g_currentMission.terrainRootNode, "stones")
    --if stoneFoliageLayerId ~= nil and stoneFoliageLayerId ~= 0 then
    --    local numChannels     = getTerrainDetailNumChannels(stoneFoliageLayerId)
    --    local value           = 2^numChannels - 1
    --
    --    soilMod.addPlugin_UpdatePloughArea_before(
    --        "Ploughing causes stones to randomly appear",
    --        50,
    --        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --            if math.random(0,100) < 2 then
    --                setDensityParallelogram(stoneFoliageLayerId, sx,sz,wx,wz,hx,hz, 0, numChannels, value)
    --            end
    --        end
    --    )
    --end
    
end

--
function fmcSoilModPlugins.pluginsForUpdateSowingArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSowingArea()
    --

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
        soilMod.addPlugin_UpdateSowingArea_before(
            "Destroy weed plants when sowing",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Remove weed plants - where we're seeding.
                setDensityParallelogram(g_currentMission.fmcFoliageWeed, sx,sz,wx,wz,hx,hz, 0,4, 0)
            end
        )
    end
    
end

--
function fmcSoilModPlugins.pluginsForUpdateSprayArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSprayArea()
    --

    if hasFoliageLayer(g_currentMission.fmcFoliageManure) then
        local foliageId       = g_currentMission.fmcFoliageManure
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1
        
        if Fillable.FILLTYPE_MANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread manure",
                10,
                Fillable.FILLTYPE_MANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_MANURESOLID ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread manureSolid",
                10,
                Fillable.FILLTYPE_MANURESOLID,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_SOLIDMANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread solidManure",
                10,
                Fillable.FILLTYPE_SOLIDMANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageSlurry) then
        local foliageId       = g_currentMission.fmcFoliageSlurry
        local numChannels     = 1 --getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1
        
        if Fillable.FILLTYPE_LIQUIDMANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (liquidManure)",
                10,
                Fillable.FILLTYPE_LIQUIDMANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_MANURELIQUID ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (manureLiquid)",
                10,
                Fillable.FILLTYPE_MANURELIQUID,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return true -- Place moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageWater) then
        local foliageId       = g_currentMission.fmcFoliageWater
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2 -- water +1
        
        if Fillable.FILLTYPE_WATER ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread water",
                10,
                Fillable.FILLTYPE_WATER,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return true -- Place moisture!
                end
            )
        end
    end
        
    if hasFoliageLayer(g_currentMission.fmcFoliageLime) then
        local foliageId       = g_currentMission.fmcFoliageLime
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1
        
        if Fillable.FILLTYPE_LIME ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread lime(solid1)",
                10,
                Fillable.FILLTYPE_LIME,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread lime(solid2)",
                10,
                Fillable.FILLTYPE_LIME + 128,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_KALK ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread kalk(solid1)",
                10,
                Fillable.FILLTYPE_KALK,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread kalk(solid2)",
                10,
                Fillable.FILLTYPE_KALK + 128,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
        local foliageId       = g_currentMission.fmcFoliageHerbicide
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        
        if Fillable.FILLTYPE_HERBICIDE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide",
                10,
                Fillable.FILLTYPE_HERBICIDE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 1) -- type-A
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_HERBICIDE2 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide2",
                10,
                Fillable.FILLTYPE_HERBICIDE2,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 2) -- type-B
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_HERBICIDE3 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide3",
                10,
                Fillable.FILLTYPE_HERBICIDE3,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 3) -- type-C
                    return true -- Place moisture!
                end
            )
        end

        --
        if hasFoliageLayer(g_currentMission.fmcFoliageHerbicideTime) then
            if Fillable.FILLTYPE_HERBICIDE4 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide4 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE4,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 1) -- type-A
                        setDensityParallelogram(g_currentMission.fmcFoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_HERBICIDE5 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide5 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE5,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 2) -- type-B
                        setDensityParallelogram(g_currentMission.fmcFoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_HERBICIDE6 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide6 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE6,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 3) -- type-C
                        setDensityParallelogram(g_currentMission.fmcFoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizer) then
        local fruitLayer = g_currentMission.fruits[1]
        if fruitLayer ~= nil and hasFoliageLayer(fruitLayer.id) then
            local fruitLayerId = fruitLayer.id
            local foliageId    = g_currentMission.fmcFoliageFertilizer
            local numChannels  = getTerrainDetailNumChannels(foliageId)
        
            if Fillable.FILLTYPE_FERTILIZER ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer(liquid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 1) -- type-A(liquid)
                        return true -- Place moisture!
                    end
                )
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer(solid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER + 128,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 1+4) -- type-A(solid)
                        return false -- No moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_FERTILIZER2 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer2(liquid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER2,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 2) -- type-B(liquid)
                        return true -- Place moisture!
                    end
                )
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer2(solid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER2 + 128,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 2+4) -- type-B(solid)
                        return false -- No moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_FERTILIZER3 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer3(liquid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER3,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 3) -- type-C(liquid)
                        return true -- Place moisture!
                    end
                )
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer3(solid)",
                    10,
                    Fillable.FILLTYPE_FERTILIZER3 + 128,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 3+4) -- type-C(solid)
                        return false -- No moisture!
                    end
                )
            end
        end
    end
end

--
function fmcSoilModPlugins.pluginsForGrowthCycle(soilMod)
--[[
Growth states

   Density value (from channels/bits)
   |  RegisterFruit value (for RegisterFruit)
   |  |
   0  -  nothing
   1  0  growth-1 (just seeded)
   2  1  growth-2
   3  2  growth-3
   4  3  growth-4
   5  4  harvest-1 / prepare-1
   6  5  harvest-2 / prepare-2
   7  6  harvest-3 / prepare-3
   8  7  withered
   9  8  cutted
  10  9  harvest (defoliaged)
  11 10  <unused>
  12 11  <unused>
  13 12  <unused>
  14 13  <unused>
  15 14  <unused>
--]]
 
    -- Default growth
    soilMod.addPlugin_GrowthCycleFruits(
        "Increase crop growth",
        10, 
        function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            setDensityMaskParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue, fruitEntry.maxMatureValue - ((fmcGrowthControl.disableWithering or fruitEntry.witheredValue == nil) and 1 or 0))
            addDensityMaskedParallelogram(
              fruitEntry.fruitId,
              sx,sz,wx,wz,hx,hz,
              0, g_currentMission.numFruitStateChannels,
              fruitEntry.fruitId, 0, g_currentMission.numFruitStateChannels, -- mask
              1 -- increase
            )
            setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
        end
    )

    
    -- Decrease other layers depending on growth-stage
    local fruitLayer = g_currentMission.fruits[1]
    local fruitLayerId = fruitLayer.id
    if hasFoliageLayer(fruitLayerId) then
        if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
            soilMod.addPlugin_GrowthCycle(
                "Decrease soil pH when crop at growth-stage 5",
                15, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "equals", 5)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end
    
        if hasFoliageLayer(g_currentMission.fmcFoliageFertN) then
            soilMod.addPlugin_GrowthCycle(
                "Decrease N when crop between growth-stages 1-7",
                16, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.fmcFoliageFertN, "between", 1, 7)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end
    
        if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
            soilMod.addPlugin_GrowthCycle(
                "Decrease PK when crop at growth-stage 5",
                17, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "equals", 5)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end

        if hasFoliageLayer(g_currentMission.fmcFoliageMoisture) then
            soilMod.addPlugin_GrowthCycle(
                "Decrease moisture when crop at growth-stage 2",
                18, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "equals", 2)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end
    end
    
    ---- Herbicide side-effects
    --if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
    --    soilMod.addPlugin_GrowthCycleFruits(
    --        "Herbicide affect crop",
    --        20, 
    --        function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
    --            -- Herbicide may affect growth or cause withering...
    --            if fruitEntry.herbicideAvoidance ~= nil and fruitEntry.herbicideAvoidance >= 1 and fruitEntry.herbicideAvoidance <= 3 then
    --              -- Herbicide affected fruit
    --              setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
    --              -- When growing and affected by wrong herbicide, pause one growth-step
    --              setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue+1, fruitEntry.minMatureValue)
    --              addDensityMaskedParallelogram(
    --                fruitEntry.fruitId,
    --                sx,sz,wx,wz,hx,hz,
    --                0, g_currentMission.numFruitStateChannels,
    --                g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                -1 -- subtract one
    --              )
    --              -- When mature and affected by wrong herbicide, change to withered if possible.
    --              if fruitEntry.witheredValue ~= nil then
    --                setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
    --                setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minMatureValue, fruitEntry.maxMatureValue)
    --                setDensityMaskedParallelogram(
    --                    fruitEntry.fruitId,
    --                    sx,sz,wx,wz,hx,hz,
    --                    0, g_currentMission.numFruitStateChannels,
    --                    g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                    fruitEntry.witheredValue  -- value
    --                )
    --              end
    --              --
    --              setDensityCompareParams(fruitEntry.fruitId, "greater", -1)
    --              setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
    --            end
    --        end
    --    )
    --end
    
    
    -- Remove windrows
    if fmcSoilModPlugins.reduceWindrows ~= false then
        soilMod.addPlugin_GrowthCycleFruits(
            "Reduce crop windrows/swath",
            30, 
            function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
                -- Reduce windrow (gone with the wind)
                if fruitEntry.windrowId ~= nil and fruitEntry.windrowId ~= 0 then
                    setDensityMaskParams(fruitEntry.windrowId, "greater", 0)
                    addDensityMaskedParallelogram(
                        fruitEntry.windrowId,
                        sx,sz,wx,wz,hx,hz,
                        0, g_currentMission.numWindrowChannels,
                        fruitEntry.windrowId, 0, g_currentMission.numWindrowChannels,  -- mask
                        -1  -- subtract one
                    );
                    setDensityMaskParams(fruitEntry.windrowId, "greater", -1)
                end
            end
        )
    end
    
    
    --Lime/Kalk and soil pH
    if hasFoliageLayer(g_currentMission.fmcFoliageLime) then
        if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
            soilMod.addPlugin_GrowthCycle(
                "Increase soil pH where there is lime",
                20 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Increase soil-pH, where lime is
                    setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", 0); -- lime must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageLime, 0, 1,
                        3  -- increase
                    );
                    --setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1);
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Remove lime",
            20, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove lime
                setDensityParallelogram(
                    g_currentMission.fmcFoliageLime,
                    sx,sz,wx,wz,hx,hz,
                    0, 1,
                    0  -- value
                );
            end
        )
    end
    
    -- Manure
    if hasFoliageLayer(g_currentMission.fmcFoliageManure) then
        soilMod.addPlugin_GrowthCycle(
            "Reduce manure",
            30, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Decrease solid manure
                addDensityParallelogram(
                    g_currentMission.fmcFoliageManure,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    -1  -- subtract one
                );
            end
        )
    end
    
    -- Slurry (LiquidManure)
    if hasFoliageLayer(g_currentMission.fmcFoliageSlurry) then
        if hasFoliageLayer(g_currentMission.fmcFoliageFertN) then
            soilMod.addPlugin_GrowthCycle(
                "Increase N where there is slurry",
                40 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- add to nitrogen
                    setDensityMaskParams(g_currentMission.fmcFoliageFertN, "greater", 0); -- slurry must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageSlurry, 0, 2,  -- mask
                        3 -- increase
                    );
                    setDensityMaskParams(g_currentMission.fmcFoliageFertN, "greater", -1);
                end
            )
        end
        
        soilMod.addPlugin_GrowthCycle(
            "Remove slurry",
            40, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove liquid manure
                setDensityParallelogram(
                    g_currentMission.fmcFoliageSlurry,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0
                );
            end
        )
    end

    -- Fertilizer
    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizer) then
        if hasFoliageLayer(g_currentMission.fmcFoliageFertN) then
            soilMod.addPlugin_GrowthCycle(
                "Increase N where there is fertilizer type-A/C",
                45 - 2, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.fmcFoliageFertN, "equals", 1); -- fertilizer must be == 1
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageFertilizer, 0, 2,  -- mask
                        3 -- increase
                    );
                    setDensityMaskParams(g_currentMission.fmcFoliageFertN, "equals", 3); -- fertilizer must be == 3
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageFertilizer, 0, 2,  -- mask
                        5 -- increase
                    );
                    --setDensityMaskParams(g_currentMission.fmcFoliageFertN, "greater", -1);
                end
            )
        end
        if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
            soilMod.addPlugin_GrowthCycle(
                "Increase PK where there is fertilizer type-A/B",
                45 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "equals", 1); -- fertilizer must be == 1
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.fmcFoliageFertilizer, 0, 2,  -- mask
                        1 -- increase
                    );
                    setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "equals", 2); -- fertilizer must be == 2
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.fmcFoliageFertilizer, 0, 2,  -- mask
                        3 -- increase
                    );
                    --setDensityMaskParams(g_currentMission.fmcFoliageFertPK, "greater", -1);
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Remove fertilizer",
            45, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove fertilizer
                setDensityParallelogram(
                    g_currentMission.fmcFoliageFertilizer,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    0
                );
            end
        )
    end
    
    
    -- Weed and herbicide
    if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
        soilMod.addPlugin_GrowthCycle(
            "Reduce withered weed",
            50 - 2, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Decrease "dead" weed
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "between", 1, 3)
                addDensityParallelogram(
                    g_currentMission.fmcFoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    -1  -- subtract
                );
            end
        )
    
        --
        if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
            soilMod.addPlugin_GrowthCycle(
                "Change weed to withered where there is herbicide",
                50 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Change to "dead" weed
                    setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", 0)
                    setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", 0)
                    setDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageWeed,
                        sx,sz,wx,wz,hx,hz,
                        2, 1, -- affect only Most-Significant-Bit
                        g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
                        0 -- reset bit
                    )
                    --setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", -1)
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Increase weed growth",
            50, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Increase "alive" weed
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "between", 4, 6)
                addDensityParallelogram(
                    g_currentMission.fmcFoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    1  -- increase
                );
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", -1)
            end
        )
    end

    -- Herbicide and germination prevention
    if  hasFoliageLayer(g_currentMission.fmcFoliageHerbicideTime)
    and hasFoliageLayer(g_currentMission.fmcFoliageHerbicide)
    then
        soilMod.addPlugin_GrowthCycle(
            "Reduce germination prevention, where there is no herbicide",
            55,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Reduce germination prevention time.
                setDensityMaskParams(g_currentMission.fmcFoliageHerbicideTime, "equals", 0)
                addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageHerbicideTime,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
                    -1  -- decrease
                );
            end
        )
    end
    
    -- Herbicide and soil pH
    if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
        if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
            soilMod.addPlugin_GrowthCycle(
                "Reduce soil pH where there is herbicide",
                60 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Decrease soil-pH, where herbicide is
                    setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", 0)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
                        -1  -- decrease
                    );
                    --setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1)
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Remove herbicide",
            60, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove herbicide
                setDensityParallelogram(
                    g_currentMission.fmcFoliageHerbicide,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0  -- value
                );
            end
        )
    end

    -- Water and Moisture
    if  hasFoliageLayer(g_currentMission.fmcFoliageMoisture)
    and hasFoliageLayer(g_currentMission.fmcFoliageWater)
    then
        soilMod.addPlugin_GrowthCycle(
            "Increase/decrease water-moisture depending on water-level",
            70, 
            function(sx,sz,wx,wz,hx,hz,day)
                setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "equals", 1)
                addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.fmcFoliageWater, 0, 2, -- mask
                    -1  -- decrease
                );
                setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "equals", 2)
                addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.fmcFoliageWater, 0, 2, -- mask
                    1  -- increase
                );
                setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "equals", 3)
                addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.fmcFoliageWater, 0, 2, -- mask
                    2  -- increase
                );
            end
        )
        
        soilMod.addPlugin_GrowthCycle(
            "Remove water-level",
            71, 
            function(sx,sz,wx,wz,hx,hz,day)
                setDensityParallelogram(
                    g_currentMission.fmcFoliageWater,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0  -- value
                );
            end
        )
    end


    -- Spray and Moisture
    if fmcSoilModPlugins.removeSprayMoisture == true then

        if hasFoliageLayer(g_currentMission.fmcFoliageMoisture) then
            soilMod.addPlugin_GrowthCycle(
                "Increase water-moisture where there is sprayed",
                80 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.fmcFoliageMoisture, "equals", 1)
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.terrainDetailId, g_currentMission.sprayChannel, 1, -- mask
                        1  -- increase
                    );
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Remove spray moisture",
            80, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove moistness (spray)
                setDensityParallelogram(
                    g_currentMission.terrainDetailId,
                    sx,sz,wx,wz,hx,hz,
                    g_currentMission.sprayChannel, 1,
                    0  -- value
                );
            end
        )
    end
    
end

--
print(string.format("Script loaded: fmcSoilModPlugins.lua (v%s)", fmcSoilModPlugins.version));
