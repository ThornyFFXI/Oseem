local ffi = require("ffi");
ffi.cdef[[
    int32_t memcmp(const void* buff1, const void* buff2, size_t count);
]];

local equipmentData = {
    [1] = { Id = 25640, Flags = 0x05},
    [2] = { Id = 25716, Flags = 0x05},
    [3] = { Id = 27138, Flags = 0x05},
    [4] = { Id = 25840, Flags = 0x05},
    [5] = { Id = 27494, Flags = 0x05},
    [6] = { Id = 25641, Flags = 0x09},
    [7] = { Id = 25717, Flags = 0x09},
    [8] = { Id = 27139, Flags = 0x09},
    [9] = { Id = 25841, Flags = 0x09},
    [10] = { Id = 27495, Flags = 0x09},
    [11] = { Id = 25642, Flags = 0x0F},
    [12] = { Id = 25718, Flags = 0x0F},
    [13] = { Id = 27140, Flags = 0x0F},
    [14] = { Id = 25842, Flags = 0x0F},
    [15] = { Id = 27496, Flags = 0x0F},
    [16] = { Id = 25643, Flags = 0x0C},
    [17] = { Id = 25719, Flags = 0x0C},
    [18] = { Id = 27141, Flags = 0x0C},
    [19] = { Id = 25843, Flags = 0x0C},
    [20] = { Id = 27497, Flags = 0x0C},
    [21] = { Id = 25644, Flags = 0x11},
    [22] = { Id = 25720, Flags = 0x11},
    [23] = { Id = 27142, Flags = 0x11},
    [24] = { Id = 25844, Flags = 0x11},
    [25] = { Id = 27498, Flags = 0x11},
    [26] = { Id = 20505, Flags = 0x09},
    [27] = { Id = 20579, Flags = 0x05},
    [28] = { Id = 20677, Flags = 0x05},
    [29] = { Id = 21686, Flags = 0x01},
    [30] = { Id = 21746, Flags = 0x09},
    [31] = { Id = 21754, Flags = 0x01},
    [32] = { Id = 21804, Flags = 0x01},
    [33] = { Id = 21854, Flags = 0x01},
    [34] = { Id = 21904, Flags = 0x01},
    [35] = { Id = 21021, Flags = 0x01},
    [36] = { Id = 21072, Flags = 0x05},
    [37] = { Id = 22054, Flags = 0x0C},
    [38] = { Id = 22113, Flags = 0x02},
    [39] = { Id = 22134, Flags = 0x02 }
};

local function InitializePaths()
    gState.Paths = T{};
    local flags = gState.Equipment.Flags;
    local text = '';
    if (bit.band(flags, 0x01) == 0x01) then
        gState.Paths:append({ Name = 'Melee', Id = 0, Param = 0x0008 });
    end
    if (bit.band(flags, 0x02) == 0x02) then
        gState.Paths:append({ Name = 'Ranged', Param = 0x0108 });
    end
    if (bit.band(flags, 0x04) == 0x04) then
        gState.Paths:append({ Name = 'Magic', Param = 0x0208 });
    end
    if (bit.band(flags, 0x08) == 0x08) then
        gState.Paths:append({ Name = 'Pet', Param = 0x0308 });
    end
    if (bit.band(flags, 0x10) == 0x10) then
        gState.Paths:append({ Name = 'Healing', Param = 0x0408 });
    end
    gState.PathIndex = { 0 };
end

function SelectStone()        
    if gState.UseFern[1] and gState.Fern > 0 then
        gState.StoneParam = 1;
        gState.LastStone = 'Fern Stone';
        return true;
    elseif gState.UsePellucid[1] and gState.Pellucid > 0 then
        gState.StoneParam = 0;
        gState.LastStone = 'Pellucid Stone';
        return true;
    elseif gState.UseTaupe[1] and gState.Taupe > 0 then
        gState.StoneParam = 2;
        gState.LastStone = 'Taupe Stone';
        return true;
    end
    return false;
end

function SendMenuPacket(param1, param2, exit)
    if (type(exit) == 'boolean') then
        if exit then
            exit = 1;
        else
            exit = 0;
        end
    end

    local packet = struct.pack('LLHHHBBHH', 0, gState.OseemId, param1, param2, gState.OseemIndex, exit, 0, AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0), gState.OseemMenu);
    AshitaCore:GetPacketManager():AddOutgoingPacket(0x5B, packet:totable());
end

function HandleOutgoingChunk()
    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local myStatus = AshitaCore:GetMemoryManager():GetEntity():GetStatus(myIndex);

    if (gState.State == 'AugmentDelay') then
        if (myStatus == 4) and (os.clock() > gState.CurrentDelay) and (os.clock() > gState.MenuDelay) then
            gState.MenuDelay = os.clock() + gState.RetryDelay[1];
            local path = gState.Paths[gState.PathIndex[1] + 1];
            SendMenuPacket(path.Param, gState.StoneParam, true);
            PrintMessage(string.format('Sending augment packet(%s:%s).', path.Name, gState.LastStone));;
        end
    elseif (gState.State == 'ExitMenu') then
        if (myStatus ~= 4) then
            gState.State = 'AwaitingTrade';
            PrintMessage('Menu has cleanly exited, keeping existing augments.  You may resume movement and interaction.');
        elseif (os.clock() > gState.MenuDelay) then
            SendMenuPacket(0x0000, 0x4000, false);
            PrintMessage('Sending menu exit packet.');
            gState.MenuDelay = os.clock() + 4;
        end
    elseif (gState.State == 'KeepAugment') then        
        if (myStatus ~= 4) then
            gState.State = 'AwaitingTrade';
            PrintMessage('Menu has cleanly exited, keeping new augments.  You may resume movement and interaction.');
        elseif (os.clock() > gState.MenuDelay) then
            SendMenuPacket(0x0009, 0x0000, false);
            PrintMessage('Sending keep augment packet.');
            gState.MenuDelay = os.clock() + 4;
        end
    end
end

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (gState.State == 'AwaitingTrade') then
        if (e.id == 0x34) then
            local entityIndex = struct.unpack('H', e.data, 0x28 + 1);
            local menuId = struct.unpack('H', e.data, 0x2C + 1);
            if (AshitaCore:GetMemoryManager():GetEntity():GetName(entityIndex) == 'Oseem') and (menuId == 0x2523) then
                local equipmentIndex = struct.unpack('B', e.data, 0x0C + 1);
                local equipPiece = equipmentData[equipmentIndex + 1];
                if not equipPiece then
                    PrintError(string.format('Unable to locate an item entry for index %u.  Plugin will not activate.', equipmentIndex));
                    return;
                end
                gState.Equipment = equipPiece;
                InitializePaths();
                gState.Pellucid = struct.unpack('B', e.data, 0x08 + 1);
                gState.Fern = struct.unpack('B', e.data, 0x09 + 1);
                gState.Taupe = struct.unpack('B', e.data, 0x0A + 1);
                gState.OseemIndex = entityIndex;
                gState.OseemId = struct.unpack('L', e.data, 0x04 + 1);
                gState.OseemMenu = menuId;
                gState.State = 'AwaitingMenu';
                e.blocked = true;
                PrintMessage('Menu is being blocked, but the server still knows you are using it.  Please avoid movement or interaction with anything, as you may hardlock your client.');
            end
        end

        --This will ensure nothing gets blocked if we aren't actually in oseem's menus.
        return;
    elseif (gState.State == 'AugmentDelay') or (gState.State == 'AwaitingDecision') then
        if (e.id == 0x5C) then
            local pellucid = struct.unpack('B', e.data, 0x04 + 1);
            local fern = struct.unpack('B', e.data, 0x05 + 1);
            local taupe = struct.unpack('B', e.data, 0x06 + 1);

            --Expect a stone decrease so a double sent packet doesn't interfere with state.
            if (pellucid < gState.Pellucid) or (fern < gState.Fern) or (taupe < gState.Taupe) then
                gState.Pellucid = pellucid;
                gState.Fern = fern;
                gState.Taupe = taupe;
                BuildAugment(e);
                if EvaluateAugment() or (gState.State == 'AwaitingDecision') or not SelectStone() then
                    gState.State = 'AwaitingDecision';
                    gState.CurrentDelay = os.clock() + gState.AugmentDelay[1];
                else
                    gState.State = 'AugmentDelay';
                    gState.CurrentDelay = os.clock() + gState.AugmentDelay[1];
                end
                gState.MenuDelay = os.clock() + 0.2;
            end
        end
    end

    --If addon is loaded, but you aren't opening oseem menu, then AwaitingTrade will catch it before it gets here and return.
    --Block all menu related packets because addon handles it via injection.
    if (e.id == 0x32) or (e.id == 0x34) or (e.id == 0x5C) then
        e.blocked = true;
    end
end);

ashita.events.register('packet_out', 'packet_out_cb', function (e)
    if (ffi.C.memcmp(e.data_raw, e.chunk_data_raw, e.size) == 0) then
        HandleOutgoingChunk();
    end
end);