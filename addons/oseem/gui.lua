local imgui = require ('imgui');

local function GetComboBoxText()
    local text = '';
    for _,v in ipairs(gState.Paths) do
        text = text .. v.Name .. '\0';
    end
    text = text .. '\0';
    return text;
end

local function RenderGeneralTab()
    imgui.Checkbox(string.format('Use Fern Stones (Current: %d)', gState.Fern), gState.UseFern);
    imgui.Checkbox(string.format('Use Pellucid Stones (Current: %d)', gState.Pellucid), gState.UsePellucid);
    imgui.Checkbox(string.format('Use Taupe Stones (Current: %d)', gState.Taupe), gState.UseTaupe);
    imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Augment Delay');
    imgui.SliderFloat('##Augment Delay', gState.AugmentDelay, 0.2, 5.0);
    imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Retry Delay');
    imgui.SliderFloat('##Retry Delay', gState.RetryDelay, 4.0, 10.0);
    imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Augment Path');
    imgui.Combo('##Path', gState.PathIndex, GetComboBoxText());
    imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Current Minimum Augments:');
    for _,v in ipairs(AugmentData.Master) do
        if (v.Value[1] > 0) then
            local outString = '  ' .. string.format(v.Format, v.Value[1]);
            imgui.Text(outString);
        end
    end
    if (imgui.Button('Quit', { 100 })) then
        gState.State = 'ExitMenu';
    end
    imgui.SameLine(imgui.GetWindowWidth() - 115);
    if (imgui.Button('Start', { 100 })) then
        gState.ActiveAugments = T{};
        for _,v in ipairs(AugmentData.Master) do
            if (v.Value[1] > 0) then
                gState.ActiveAugments:append(v);
            end
        end

        if not SelectStone() then
            PrintError('No valid stones selected.  Exiting menu.');
            gState.State = 'ExitMenu';
            return;
        end
        
        gState.State = 'AugmentDelay';
        gState.CurrentDelay = 0;
        gState.MenuDelay = 0;
    end
end

local function RenderSettingsTab(settings)
    for _,v in ipairs(settings) do
        imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, v.Name);
        imgui.SliderInt(v.ElementName, v.Value, v.Minimum, v.Maximum, '%d', ImGuiSliderFlags_AlwaysClamp);
    end
end

local function DrawConfigMenu()
    if gState.ResetPosition then
        imgui.SetNextWindowPos({0, 0});
        gState.ResetPosition = false;
    end
    imgui.SetNextWindowSize({ 420, 410 });
    if imgui.Begin('Oseem_Config', { true }, ImGuiWindowFlags_NoResize) then
        imgui.Text('Current Item:');
        imgui.SameLine();
        imgui.TextColored( { 0.1, 1.0, 0.1, 1.0 }, AshitaCore:GetResourceManager():GetItemById(gState.Equipment.Id).Name[1]);
        if imgui.BeginTabBar('##Oseem_Config_Tabs') then
            if imgui.BeginTabItem('General', nil) then
                RenderGeneralTab();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Attributes', nil) then
                RenderSettingsTab(AugmentData.Attributes);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Stats', nil) then
                RenderSettingsTab(AugmentData.Stats);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Melee', nil) then
                RenderSettingsTab(AugmentData.Melee);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Mage', nil) then
                RenderSettingsTab(AugmentData.Mage);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Pet', nil) then
                RenderSettingsTab(AugmentData.Pet);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Utility', nil) then
                RenderSettingsTab(AugmentData.Utility);
                imgui.EndTabItem();
            end
        end
        imgui.End();
    end
end

local function DrawAugmentMenu(decisionRequired)
    if gState.ResetPosition then
        imgui.SetNextWindowPos({0, 0});
        gState.ResetPosition = false;
    end
    imgui.SetNextWindowSize({480, 430});
    if imgui.Begin('Oseem_Augment', { true }, ImGuiWindowFlags_NoResize) then
        imgui.Text('Current Item:');
        imgui.SameLine();
        imgui.TextColored( { 0.1, 1.0, 0.1, 1.0 }, AshitaCore:GetResourceManager():GetItemById(gState.Equipment.Id).Name[1]);
        imgui.Text('Current Path:');
        imgui.SameLine();
        imgui.TextColored( { 0.1, 1.0, 0.1, 1.0 }, gState.Paths[gState.PathIndex[1] + 1].Name);
        imgui.Text('Current Stone:');
        imgui.SameLine();
        imgui.TextColored( { 0.1, 1.0, 0.1, 1.0 }, gState.LastStone);
        imgui.SameLine();
        if (gState.LastStone == 'Fern Stone') then
            imgui.Text(string.format('x%d', gState.Fern));
        elseif (gState.LastStone == 'Taupe Stone') then
            imgui.Text(string.format('x%d', gState.Taupe));
        elseif (gState.LastStone == 'Pellucid Stone') then
            imgui.Text(string.format('x%d', gState.Pellucid));
        end
        imgui.BeginGroup();
        imgui.BeginChild('leftpane', { 220, 150 }, false, 128);
        imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Existing Augments:');
        for _,v in ipairs(AugmentData.Current) do
            if (v.Current > 0) then
                local outString = '  ' .. string.format(v.Format, v.Current);
                imgui.Text(outString);
            end
        end
        imgui.EndChild();
        imgui.EndGroup();
        imgui.SameLine();
        imgui.BeginGroup();
        imgui.BeginChild('rightpane', { 220, 150 }, false, 128);
        imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Pending Augments:');
        for _,v in ipairs(AugmentData.Pending) do
            if (v.Pending > 0) then
                local outString = '  ' .. string.format(v.Format, v.Pending);
                imgui.Text(outString);
            end
        end
        imgui.EndChild();
        imgui.EndGroup();
        imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Current Minimum Augments:');
        for _,v in ipairs(gState.ActiveAugments) do
            if (v.Value[1] > 0) then
                local outString = '  ' .. string.format(v.Format, v.Value[1]);
                imgui.Text(outString);
            end
        end

        imgui.SetCursorPosY(imgui.GetWindowHeight() - 75);
        imgui.TextColored( { 1.0, 0.75, 0.55, 1.0 }, 'Augment Delay');
        local delay = gState.CurrentDelay - os.clock();
        local progress = 0;
        if (delay > 0) then
            progress = delay / gState.AugmentDelay[1];
        end
        imgui.ProgressBar(progress, 250, '');

        if decisionRequired then
            if imgui.Button('Quit (Keep Current)', { 140 }) then
                gState.State = 'ExitMenu';
            end
            imgui.SameLine(imgui.GetWindowWidth() - 314);
            if imgui.Button('Quit (Keep Pending)', { 140 }) then
                gState.State = 'KeepAugment';
            end
            imgui.SameLine(imgui.GetWindowWidth() - 155);
            if imgui.Button('Continue', { 140 }) then
                if not SelectStone() then
                    PrintError('No stones remaining.');
                    gState.State = 'ExitMenu';
                    return;
                end
                gState.State = 'AugmentDelay';
            end
        else
            imgui.SetCursorPosX(imgui.GetWindowWidth() - 155);
            if imgui.Button('Pause', { 140 }) then
                if (delay > 0) then
                    gState.State = 'AwaitingDecision';
                else
                    PrintError('Unable to pause.  Next packet was already sent.');
                end
            end
        end
        imgui.End();
    end
end

ashita.events.register('d3d_present', 'render', function()
    if (gState.State == 'AwaitingMenu') then
        DrawConfigMenu();
    elseif (gState.State == 'AwaitingDecision') or (gState.State == 'AugmentDelay') then
        DrawAugmentMenu(gState.State == 'AwaitingDecision');
    end
end);