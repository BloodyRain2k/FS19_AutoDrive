AutoDrive.CHASEPOS_LEFT = -1
AutoDrive.CHASEPOS_RIGHT = 1
AutoDrive.CHASEPOS_REAR = 3

function AutoDrive.getNodeName(node)
    if node == nil then
        return "nil"
    else
        return getName(node)
    end
end

function AutoDrive.getDischargeNode(combine)
    local dischargeNode = nil
    for _, dischargeNodeIter in pairs(combine.spec_dischargeable.dischargeNodes) do
        dischargeNode = dischargeNodeIter
    end
    if combine.getPipeDischargeNodeIndex ~= nil then
        dischargeNode = combine.spec_dischargeable.dischargeNodes[combine:getPipeDischargeNodeIndex()]
    end
    return dischargeNode.node
end

function AutoDrive.getPipeRoot(combine)
    local pipeRoot = AutoDrive.getDischargeNode(combine)
    local parentStack = Buffer:new()
    local combineNode = combine.components[1].node

    repeat
        parentStack:Insert(pipeRoot)
        pipeRoot = getParent(pipeRoot)
    until ((pipeRoot == combineNode) or (pipeRoot == 0) or (pipeRoot == nil) or parentStack:Count() == 100)

    local translationMagnitude = 0
    local pipeRootX, pipeRootY, pipeRootZ
    local pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ
    local heightUnderRoot, pipeRootAgl
    local lastPipeRoot = pipeRoot

    repeat
        pipeRoot = parentStack:Get()
        if pipeRoot ~= nil and pipeRoot ~= 0 then
            pipeRootX, pipeRootY, pipeRootZ = getTranslation(pipeRoot)
            pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ = getWorldTranslation(pipeRoot)
            heightUnderRoot = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ)
            pipeRootAgl = pipeRootWorldY - heightUnderRoot
            translationMagnitude = MathUtil.vector3Length(pipeRootX, pipeRootY, pipeRootZ)
        end
        AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeRoot - Search Stack " .. pipeRoot .. " " .. AutoDrive.getNodeName(pipeRoot))
        AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeRoot - Search Stack " .. translationMagnitude .. " " .. pipeRootAgl .. " " .. " " .. AutoDrive.sign(pipeRootX) .. " " .. AutoDrive.getPipeSide(combine))
    until ((translationMagnitude > 0.01 and translationMagnitude < 100) and
           (combine:getIsBufferCombine() or AutoDrive.sign(pipeRootX) == AutoDrive.getPipeSide(combine)) and
           (pipeRootY > 0) or
           parentStack:Count() == 0
          )
    AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeRoot - Search Stack " .. pipeRoot .. " " .. AutoDrive.getNodeName(pipeRoot))
    AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeRoot - Search Stack " .. translationMagnitude .. " " .. pipeRootAgl .. " " .. " " .. AutoDrive.sign(pipeRootX)  .. " ".. AutoDrive.getPipeSide(combine))
     
    if pipeRoot == nil or pipeRoot == 0 then
        pipeRoot = combine.components[1].node
    end

    return pipeRoot
end

function AutoDrive.getPipeRootOffset(combine)
    local combineNode = combine.components[1].node
    local pipeRoot = AutoDrive.getPipeRoot(combine)
    local pipeRootX, pipeRootY, pipeRootZ = getWorldTranslation(pipeRoot)
    local diffX, diffY, diffZ = worldToLocal(combineNode, pipeRootX, pipeRootY, pipeRootZ)
    --AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeRootZOffset - " .. diffZ )
    return worldToLocal(combineNode, pipeRootX, pipeRootY, pipeRootZ)
end

function AutoDrive.getPipeSide(combine)
    local combineNode = combine.components[1].node
    local dischargeNode = AutoDrive.getDischargeNode(combine)
    local dischargeX, dichargeY, dischargeZ = getWorldTranslation(dischargeNode)
    local diffX, _, _ = worldToLocal(combineNode, dischargeX, dichargeY, dischargeZ)
    return AutoDrive.sign(diffX)
end

function AutoDrive.getPipeLength(combine)
    local pipeRootX, _ , pipeRootZ = getWorldTranslation(AutoDrive.getPipeRoot(combine))
    local dischargeX, dischargeY, dischargeZ = getWorldTranslation(AutoDrive.getDischargeNode(combine))
    local length = MathUtil.vector3Length(pipeRootX - dischargeX, 
                                          0, 
                                          pipeRootZ - dischargeZ)
    --AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeLength - " .. length)
    return length
end

function AutoDrive.isSugarcaneHarvester(combine)
    local isSugarCaneHarvester = true
    if combine.getAttachedImplements ~= nil then
        for _, implement in pairs(combine:getAttachedImplements()) do
            if implement ~= nil and implement ~= combine and (implement.object == nil or implement.object ~= combine) then
                isSugarCaneHarvester = false
            end
        end
    end
    return isSugarCaneHarvester
end