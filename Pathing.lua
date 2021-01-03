require('DoublyLinkedList')

Pathing = {}
Pathing.__index = Pathing

-- elements are tables
setmetatable(Pathing, { __call =
    function()
        newPathing = setmetatable({
            length = 0,
            history = DoublyLinkedList()
        }, Pathing)
        newPathing
        return 
    end
})

function Pathing:logPos(pos)
    
    -- confirm format
    if type(pos) ~= 'table' then
        return false
    end
    if (pos.x == nil) or (pos.y == nil) or (pos.z == nil) then
        return false
    end

    self.history.appendLeft(pos)

    return true
end

local function isValidCut(nodeArr,i,j)
    local x_i = nodeArr[i].x
    local y_i = nodeArr[i].y
    local z_i = nodeArr[i].z
    local x_j = nodeArr[i].x
    local y_j = nodeArr[i].y
    local z_j = nodeArr[i].z

    if math.abs(x_i - x_j) == 1 then return true end
    if math.abs(y_i - y_j) == 1 then return true end
    if math.abs(z_i - z_j) == 1 then return true end

    return false
end

local function sortedPairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- sort keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return iterator
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return t[keys[i]]
        end
    end
end

local function value(cut, N):
    return (cut.endIndex * N) + cut.startIndex
end

function Pathing:getPathToOrigin()

    -- get data into array for fast access
    nodeArr = {}
    for node in self.history.iterate() do
        nodeData = {
            x=node.x,
            y=node.y,
            z=node.z
        }
        nodeArr[#nodeArr + 1] = nodeData
    end

    -- collect all valid cuts
    cutsArr = {}
    for i = 1,#nodeArr do
        for j = i,#nodeArr do
            if isValidCut(nodeArr,i,j) then
                cutsArr[#cutsArr + 1] = {
                    startIndex=i,
                    endIndex=j
                }
            end
        end
    end

    -- sort the array by endIndex,startIndex
    N = #cutsArr
    for cut in sortedPairs(
        cutsArr,
        function(t,a,b) return value(t[a]) < value(t[b]) end
    ) do
        
    end