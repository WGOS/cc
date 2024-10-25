Quarry = {}

local function changeVerticalPos(quarry)

end

local function process(quarry)

end

function Quarry:new(h, w, l)
    local obj = {
        dep = h,
        wid = w,
        len = l,
        
        curDep = 0,
        curWid = 0,
        curLen = 0,

        maxDep = 0,
        maxWid = 0,
        maxLen = 0,
    }

    setmetatable(obj, self)
    self.__index = self;

    obj.layers = math.ceil(h / 3)

    return obj;
end

function Quarry:start()
    print(self.layers)
    process(self)
end

function Quarry:getDepth()
    return self.dep
end

