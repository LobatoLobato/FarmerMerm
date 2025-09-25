require "behaviourtree"
require "class"

local IteratorNodeIterator = Class(function(self)
    self.items = {}
end) do -- Methods
    function IteratorNodeIterator:Push(value)
        table.insert(self.items, value)
    end
    function IteratorNodeIterator:Pop()
        return table.remove(self.items, 1)
    end

    function IteratorNodeIterator:IsEmpty()
        return #self.items == 0
    end

    function IteratorNodeIterator:Clear()
        self.items = {}
    end

    function IteratorNodeIterator:Count()
        return #self.items
    end
end

function IterateAndDoActionNode(inst, parameters)
    local name = parameters.name
    local starter = parameters.starter
    local action = parameters.action
    local run = parameters.run

    local iterator = IteratorNodeIterator()
    
    local function ifnode()
        return starter(inst, iterator)
    end
    local function whilenode()
        return not iterator:IsEmpty()
    end
    local function findnode()
        return action(inst, iterator)
    end
    local looper
    if parameters.chatterstring then
        looper = LoopNode { ConditionNode(whilenode), ChattyNode(inst, parameters.chatterstring, DoAction(inst, findnode, "DoAction_Chatty", run, 10)) }
    else
        looper = LoopNode { ConditionNode(whilenode), DoAction(inst, findnode, "DoAction_NoChatty", run, 10) }
    end
    
    local IteratorNode = IfThenDoWhileNode(ifnode, whilenode, name, looper)

    function IteratorNode:ClearIterator() iterator:Clear() end

    return IteratorNode
end


