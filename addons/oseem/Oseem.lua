addon.name      = 'Oseem';
addon.author    = 'Thorny';
addon.version   = '1.01';
addon.desc      = 'Automatic augmenter for reisenjima augment system with the NPC Oseem.';
addon.link      = 'https://github.com/ThornyFFXI/Oseem';

require('common');
chat = require('chat');
require('augment');
require('gui');
require('packets');

gSettings = {
    Delay = { 0.2 },
};

gState = {
    Equipment = nil,
    CurrentDelay = 0,
    MenuDelay = 0,
    Pellucid = 0,
    Fern = 0,
    Taupe = 0,
    OseemIndex = 0,
    OseemId = 0,
    OseemMenu = 0,
    State = 'AwaitingTrade',
    AugmentPending = false,
    KeepAugment = false,
    AugmentDelay = { 1.2 },
    RetryDelay = { 5.0 },
    UseFern = { true },
    UsePellucid = { false },
    UseTaupe = { false },
};

function PrintError(text)
    print(chat.header('Oseem') .. chat.error(text));
end

function PrintMessage(text)
    print(chat.header('Oseem') .. chat.message(text));
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0) then
        return;
    end
    args[1] = string.lower(args[1]);
    if (args[1] == '/oseem') then

        if (#args > 1) and (string.lower(args[2]) == 'reset') then
            PrintMessage('Resetting window position.');
            gState.ResetPosition = true;
        end
        e.blocked = true;
    end
end);