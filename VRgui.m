function parameters = VRgui
%% Make figure window
scrsze = get(0, 'ScreenSize');
GUIdialog = figure(8);
cla;
set(GUIdialog,...
    'WindowStyle', 'Modal',...
    'NumberTitle', 'Off', ...
    'Name', 'Setup', ...
    'MenuBar', 'None', ...
    'Units','Pixels',...
    'Position',[(scrsze(3)/2/2-110) (scrsze(4)/2-250) 220 480], ...
    'Visible', 'Off',...
    'Resize', 'Off',...
    'KeyPressFcn', @keypressFcn);

%% UI Components
MainPanel        =   uipanel('BorderType', 'None', 'Units','Pixels');
MousePanel       =   uipanel('Parent',MainPanel, 'Title','Mouse', 'TitlePosition','centertop', 'Units','Pixels', 'Position',[10 380 200 90]);
MouseIDInput     = uicontrol('Parent',MousePanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 40 100 20], 'TooltipString','input');
WeightInput      = uicontrol('Parent',MousePanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 10 100 20], 'TooltipString','input');
MouseIDLabel     = uicontrol('Parent',MousePanel, 'Style','Text', 'String','ID',         'Units','Pixels', 'Position',[10 35 60 20]);
MouseWeightLabel = uicontrol('Parent',MousePanel, 'Style','Text', 'String','Weight (g)', 'Units','Pixels', 'Position',[10 5 60 20]);

InitialPanel  =   uipanel('Parent', MainPanel, 'Title', 'Initial Parameters', 'TitlePosition', 'centertop', 'Units','Pixels', 'Position',[10 240 200 120]);
ContrastInput = uicontrol('Parent', InitialPanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 70 100 20], 'TooltipString','input');
SFInput       = uicontrol('Parent', InitialPanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 40 100 20], 'TooltipString','input');
VelocityInput = uicontrol('Parent', InitialPanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 10 100 20], 'TooltipString','input');
ContrastLabel = uicontrol('Parent', InitialPanel, 'Style','Text', 'String','Contrast', 'Units','Pixels', 'Position',[10 65 60 20]);
SFLabel       = uicontrol('Parent', InitialPanel, 'Style','Text', 'String','SF',       'Units','Pixels', 'Position',[10 35 60 20]);
VelocityLabel = uicontrol('Parent', InitialPanel, 'Style','Text', 'String','Velocity', 'Units','Pixels', 'Position',[10 5 60 20]);

VariablePanel        =   uipanel('Parent', MainPanel, 'Title', 'Variable Parameters', 'TitlePosition', 'centertop', 'Units','Pixels', 'Position',[10 70 200 150]);
ChangeModeInput      = uicontrol('Parent', VariablePanel, 'Style','Popup', 'String','None|Contrast|Spatial Frequency', 'callback', @disableOptions, 'Units','Pixels', 'Position',[90 100 100 20], 'TooltipString','input');
ChangeToInput        = uicontrol('Parent', VariablePanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 70 100 20], 'TooltipString','input');
ChangeAfterModeInput = uicontrol('Parent', VariablePanel, 'Style','Popup', 'String','Distance|Time', 'Units','Pixels', 'Position',[90 40 100 20], 'TooltipString','input');
ChangeAfterInput     = uicontrol('Parent', VariablePanel, 'Style','Edit', 'Units','Pixels', 'Position',[90 10 100 20], 'TooltipString','input');
ChangeModeLabel      = uicontrol('Parent', VariablePanel, 'Style','Text', 'String','Change', 'Units','Pixels', 'Position',[10 95 60 20]);
ChangeToLabel        = uicontrol('Parent', VariablePanel, 'Style','Text', 'String','Change To', 'Units','Pixels', 'Position',[10 65 60 20]);
ChangeAfterModeLabel = uicontrol('Parent', VariablePanel, 'Style','Text', 'String','Change After', 'Units','Pixels', 'Position',[10 35 80 20]);
ChangeAfterLabel     = uicontrol('Parent', VariablePanel, 'Style','Text', 'String','', 'Units','Pixels', 'Position',[10 5 80 20]);

BeginButton         = uicontrol('Parent', MainPanel, 'Style','PushButton', 'String','Begin', 'callback', @completeAndClose, 'Units','Pixels', 'Position',[115 10 95 40], 'TooltipString','input');
SetDefaultsButton   = uicontrol('Parent', MainPanel, 'Style','PushButton', 'String','Save defaults', 'callback', @saveDefaults, 'Units','Pixels', 'Position',[10 30 95 20], 'TooltipString','input');
ClearDefaultsButton = uicontrol('Parent', MainPanel, 'Style','PushButton', 'String','Reset defaults', 'callback', @ClearDefaults, 'Units','Pixels', 'Position',[10 10 95 20], 'TooltipString','input');

UI_All_Inputs = [findobj(gcf, 'Style','Edit'); findobj(gcf, 'Style','Popup')];
UI_All_Labels = findobj(gcf, 'Style','Text');
UI_All_Elements = [UI_All_Inputs; findobj(gcf, 'Style','PushButton')];

set(UI_All_Inputs, 'BackgroundColor', [1 1 1]);
set(UI_All_Labels, 'HorizontalAlignment', 'Left');
set(UI_All_Elements, 'KeyPressFcn', @keypressFcn);

%% loading default values on open / creating defaults file if does not exist
[~, ComputerName] = system('hostname');
ComputerName = genvarname(ComputerName);
if exist('GUIdefaults.mat', 'file')
    load('GUIdefaults', 'Defaults');
    if isfield(Defaults, (ComputerName))
        setValues;
    else
        resetValues;
        save('GUIdefaults', 'Defaults');
    end
else
    resetValues;
    save('GUIdefaults', 'Defaults');
end

disableOptions;

%% make figure visible
set(GUIdialog, 'Visible', 'On');
uicontrol(MouseIDInput); % sets focus
uiwait; % hold matlab until gui is closed

%% Functions and callbacks
    function completeAndClose (varargin)
        uicontrol(BeginButton);
        pause(0.01) %otherwise old value of uicontrol is used as keypressfcn completes before uicontrol update is registered
        mouseID = get(MouseIDInput, 'String');
        weight = get(WeightInput, 'String');
        
        if isstrprop(mouseID(1), 'alpha') && all(ismember(mouseID(2:end), '1234567890')) || strcmpi(mouseID, 'test')
            if all(ismember(weight, '1234567890.')) && str2double(num2str(get(WeightInput, 'String'))) >= 0
                
                toChangeInputList = cellstr(get(ChangeModeInput, 'String'));
                selectedToChange  = toChangeInputList{get(ChangeModeInput, 'Value')};
                
                changeAfterInputList = cellstr(get(ChangeAfterModeInput, 'String'));
                selectedChangeAfter  = changeAfterInputList{get(ChangeAfterModeInput, 'Value')};
                
                parameters.mouse           = upper(mouseID);
                parameters.weight          = str2double(weight);
                parameters.contrast        = str2double(get(ContrastInput, 'String'));
                parameters.sf              = str2double(get(SFInput, 'String'));
                parameters.velocityGain    = str2double(get(VelocityInput, 'String'));
                parameters.changeMode      = selectedToChange;
                parameters.changeTo        = str2double(get(ChangeToInput, 'String'));
                parameters.changeAfterMode = selectedChangeAfter;
                parameters.changeAfter     = str2double(get(ChangeAfterInput, 'String'));
                
                delete(gcf);
                
            else
                msgbox('Mouse weight is invalid.', 'Error: Weight', 'error', 'modal')
                uicontrol(WeightInput);
            end
        else
            msgbox('Mouse ID is invalid.', 'Error: Mouse ID', 'error', 'modal')
            uicontrol(MouseIDInput);
        end
    end

    function saveDefaults (varargin)
        [~, ComputerName] = system('hostname');
        ComputerName = genvarname(ComputerName);
        Defaults.(ComputerName).DefaultID              = upper(get(MouseIDInput, 'String'));
        Defaults.(ComputerName).DefaultWeight          = str2double(get(WeightInput, 'String'));
        Defaults.(ComputerName).DefaultContrast        = str2double(get(ContrastInput, 'String'));
        Defaults.(ComputerName).DefaultSF              = str2double(get(SFInput, 'String'));
        Defaults.(ComputerName).DefaultVelocity        = str2double(get(VelocityInput, 'String'));
        Defaults.(ComputerName).DefaultChangeMode      = get(ChangeModeInput, 'Value');
        Defaults.(ComputerName).DefaultChangeTo        = get(ChangeToInput, 'String');
        Defaults.(ComputerName).DefaultChangeAfterMode = get(ChangeAfterModeInput, 'Value');
        Defaults.(ComputerName).DefaultChangeAfter     = str2double(get(ChangeAfterInput, 'String'));
        save('GUIdefaults', 'Defaults', '-append');
    end

    function ClearDefaults (varargin)
        [~, ComputerName] = system('hostname');
        ComputerName = genvarname(ComputerName);
        resetValues;
        setValues;
        save('GUIdefaults', 'Defaults', '-append');
    end

    function setValues (varargin)
        set(MouseIDInput, 'String',Defaults.(ComputerName).DefaultID);
        set(WeightInput, 'String',Defaults.(ComputerName).DefaultWeight);
        set(ContrastInput, 'String',Defaults.(ComputerName).DefaultContrast);
        set(SFInput, 'String',Defaults.(ComputerName).DefaultSF);
        set(VelocityInput, 'String',Defaults.(ComputerName).DefaultVelocity);
        set(ChangeModeInput, 'Value',Defaults.(ComputerName).DefaultChangeMode);
        set(ChangeToInput, 'String',Defaults.(ComputerName).DefaultChangeTo);
        set(ChangeAfterModeInput, 'Value',Defaults.(ComputerName).DefaultChangeAfterMode);
        set(ChangeAfterInput, 'String',Defaults.(ComputerName).DefaultChangeAfter);
    end

    function resetValues (varargin)
        Defaults.(ComputerName) = [];
        ResetID              = [];
        ResetWeight          = [];
        ResetContrast        = [];
        ResetSF              = [];
        ResetVelocity        = [];
        ResetChangeMode      = 1;
        ResetChangeTo        = [];
        ResetChangeAfterMode = 1;
        ResetChangeAfter     = [];
        
        Defaults.(ComputerName).DefaultID              = ResetID;
        Defaults.(ComputerName).DefaultWeight          = ResetWeight;
        Defaults.(ComputerName).DefaultContrast        = ResetContrast;
        Defaults.(ComputerName).DefaultSF              = ResetSF;
        Defaults.(ComputerName).DefaultVelocity        = ResetVelocity;
        Defaults.(ComputerName).DefaultChangeMode      = ResetChangeMode;
        Defaults.(ComputerName).DefaultChangeTo        = ResetChangeTo;
        Defaults.(ComputerName).DefaultChangeAfterMode = ResetChangeAfterMode;
        Defaults.(ComputerName).DefaultChangeAfter     = ResetChangeAfter;
    end

    function keypressFcn (~, eventdata, ~)
        if strcmp(eventdata.Key,'return')
            completeAndClose;
        elseif strcmp(eventdata.Key,'s') && strcmp(eventdata.Modifier,'control')
            uicontrol(BeginButton);
            pause(0.01);
            saveDefaults;
        end
    end

    function disableOptions (varargin)
        if get(ChangeModeInput, 'Value') == 1
            set(ChangeToInput, 'enable','off');
            set(ChangeAfterModeInput, 'enable','off');
            set(ChangeAfterInput, 'enable','off');
        else
            set(ChangeToInput, 'enable','on');
            set(ChangeAfterModeInput, 'enable','on');
            set(ChangeAfterInput, 'enable','on');
        end
    end
end