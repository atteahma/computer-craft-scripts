DoublyLinkedList = {}
DoublyLinkedList.__index = DoublyLinkedList

-- elements are tables
setmetatable(DoublyLinkedList, { __call =
    function(_, ...)
        local newLL = setmetatable({ length = 0 }, DoublyLinkedList)
        for _,v in ipairs{...} do
            newLL:push(v)
        end
        return newLL
    end
})

function DoublyLinkedList:append(elem)
    if self.last then
        self.last.next = elem
        elem.prev = self.last
        self.last = elem
    else
        -- first elem
        self.first = elem
        self.last = elem
    end

    self.length = self.length + 1
end

function DoublyLinkedList:appendLeft(elem)
    if self.first then
        self.first.prev = elem
        elem.next = self.first
        self.first = elem
    else
        -- first elem
        self.first = elem
        self.last = elem
    end

    self.length = self.length + 1
end

function DoublyLinkedList:pop()
    if self.last then
        ret = self.last

        self.last = self.last.prev

        self.length = self.length - 1

        -- garbage collection
        self.last.next = nil
        ret.prev = nil
        ret.next = nil
        return ret
    end

    return nil
end

function DoublyLinkedList:popLeft()
    if self.first then
        ret = self.first

        self.first = self.first.next

        self.length = self.length - 1

        -- garbage collection
        self.first.prev = nil
        ret.prev = nil
        ret.next = nil
        return ret
    end

    return nil
end

function DoublyLinkedList:print()
    curr = self.first

    if curr then
        while curr do
            for k,v in pairs(curr) do
                if k ~= 'prev' and k ~= 'next' then
                    print(k,v)
                end
            end
            print()
            curr = curr.next
        end
    else
        print(nil)
    end
end

function DoublyLinkedList:copy()
    newDLL = DoublyLinkedList()
    curr = self.first
    while curr do
        newElem = {}
        for k,v in pairs(curr) do
            newElem[k] = v
        end
        newDLL.append(newElem)
        curr = curr.next
    end
    return newDll
end

local function iterate(self,current)
    if not current then
        current = self.first
    else
        current = current.next
    end
    return current
end
  
function DoublyLinkedList:iterate()
    return iterate,self,nil
end

local function iterateReverse(self,current)
    if not current then
        current = self.last
    elseif current then
        current = current.prev
    end
    return current
end
  
function DoublyLinkedList:iterateReverse()
    return iterateReverse,self,nil
end
