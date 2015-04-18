function results = matlabVR
%% Lloyd Russell April 2014
%% to do
% save properly
% complete change mode
% change every
% plot every x cm breaking up
% daq session based?

%% reset everything
clear all; close all; sca; daqreset;

%% user input
setup = VRgui;
% filename = ;

%% live figure window
fig = figure();
posWidth = 430;
posHeight = 340;
set(fig, 'position', [100 100 posWidth posHeight], 'units','pixels', 'toolbar','none');
% MainPanel        =   uipanel('BorderType', 'None', 'Units','Pixels');

trackPositionAxes = axes('units','pixels', 'position',[40 200 350 100]);
hold on;
trackDwell = bar(0, 0, 1, 'linestyle', 'none', 'facecolor', [.7 .7 .7]);
trackPosition = plot([0 0],[0 0], 'linewidth', 3);
trackPositionStart = plot(0,0, 'o', 'markerface', 'k', 'markeredge', 'none');
trackPositionEnd = plot(0,0, 'd', 'markerface', 'r', 'markeredge', 'none');
title('Dwell (s) at position (cm)')
box off
% ylabel('Time (s)')
% xlabel('Position (cm)')

positionAxes = axes('units','pixels', 'position',[40 40 150 100]);
positionPlotHandle = plot(0,0, 'linewidth', 2);
title('Position (cm)')
box off
% xlabel('Time (s)')
% ylabel('Position (cm)')

velocityAxes = axes('units','pixels', 'position',[240 40 150 100]);
velocityPlotHandle = plot(0,0, 'linewidth', 1);
title('Velocity (cm/s)')
box off
avgVelLine = line(0, 0, 'color', 'r', 'linewidth', 2, 'visible','off');
% xlabel('Time (s)')
% ylabel('Velocity (cm/s)')

%%
%{
fig2 = figure();
pos2Width = 200;
pos2Height = 340+25;
set(fig2, 'position', [120+posWidth 100 pos2Width pos2Height], 'units','pixels', 'menubar','none');
MainPanel        =   uipanel('BorderType', 'None', 'Units','Pixels');

abortButton = uicontrol('style','pushbutton', 'string','Stop', 'units','pixels', 'position',[20 20 50 20], 'fontSize', 9, 'callback',@abortFcn);

uicontrol('style','text', 'string', 'Elapsed time: ',     'position',[20 pos2Height-40 100 20], 'fontsize',9, 'horizontalalignment','left');
uicontrol('style','text', 'string', 'Total distance: ',   'position',[20 pos2Height-80 100 20], 'fontsize',9, 'horizontalalignment','left');
uicontrol('style','text', 'string', 'Current position: ', 'position',[20 pos2Height-120 100 20], 'fontsize',9, 'horizontalalignment','left');
uicontrol('style','text', 'string', 'Current speed: ',    'position',[20 pos2Height-160 100 20], 'fontsize',9, 'horizontalalignment','left');

timeText         = uicontrol('style','text', 'string', '#', 'position',[20 pos2Height-60 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');
totalDistText    = uicontrol('style','text', 'string', '#', 'position',[20 pos2Height-100 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');
currentPosText   = uicontrol('style','text', 'string', '#', 'position',[20 pos2Height-140 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');
currentSpeedText = uicontrol('style','text', 'string', '#', 'position',[20 pos2Height-180 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');

% uicontrol('style','text', 'string', 'Current contrast: ',    'position',[20 pos2Height-240 100 20], 'fontsize',9, 'horizontalalignment','left');
% contrastText     = uicontrol('style','edit', 'background','w', 'string', '100', 'position',[120 pos2Height-240 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');
% uicontrol('style','text', 'string', 'Current SF: ',    'position',[20 pos2Height-260 100 20], 'fontsize',9, 'horizontalalignment','left');
% sfText     = uicontrol('style','edit', 'background','w', 'string', '0.1', 'position',[120 pos2Height-260 60 20], 'fontsize',9, 'fontweight','bold', 'horizontalalignment','left');
% contrastSetting  = str2double(get(contrastText, 'string'));
% prevContrastSetting = [];
%}

%% psychtoolbox
PsychDefaultSetup(2);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 1);
AssertOpenGL;
ptb.screens = Screen('Screens');
ptb.screenNumber = max(ptb.screens);
ptb.white = WhiteIndex(ptb.screenNumber);
ptb.black = BlackIndex(ptb.screenNumber);
ptb.grey = (ptb.black + ptb.white) / 2;
ptb.inc = ptb.white - ptb.grey;
[ptb.screenWidth, ptb.screenHeight]=Screen('WindowSize', ptb.screenNumber);
if strcmpi(setup.mouse, 'test')
    [ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ptb.screenNumber, ptb.grey,[0 20 ptb.screenWidth 120]);
else
    [ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ptb.screenNumber, ptb.grey);
end
Screen('BlendFunction', ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
ptb.ifi = Screen('GetFlipInterval', ptb.window);

%% stim settings
setup.numSplitScreens = 2;
setup.widthOfScreenCM = 37;
setup.pixelsOfScreen = 1280; 
setup.pixelsPerCM = setup.pixelsOfScreen/setup.widthOfScreenCM;
setup.distanceFromMouse = 20;
setup.totalAngleVisualField1Scrn = radtodeg(tan((setup.widthOfScreenCM/2)/setup.distanceFromMouse));

ptb.cycles = round(setup.sf*setup.totalAngleVisualField1Scrn);
setup.actualSF = ptb.cycles/setup.totalAngleVisualField1Scrn;

ptb.visiblesize = ptb.screenWidth/setup.numSplitScreens; % Size of the grating image. Needs to be a power of two.
ptb.p = ptb.visiblesize/ptb.cycles;

f = 1/ptb.p;
fr = f*2*pi;    % frequency in radians.
x = meshgrid(0:ptb.visiblesize-1, 1);

% j = 1;
% for i = 0:0.5:100
%     grating(j,:) = ptb.grey + ptb.inc*cos(fr*x)*(i/100);
%     ptb.GratingTexture(j) = Screen('MakeTexture', ptb.window, grating(j,:), [], 1);
%     j = j+1;
% end

% for i = 1:length(grating)
%     if grating(i) > ptb.grey
%         grating(i) = ptb.grey + ptb.inc*(setup.contrast/100);
%     elseif grating(i) < ptb.grey
%         grating(i) = ptb.grey - ptb.inc*(setup.contrast/100);
%     end
% end

makeGratings;

disp('Display and stimuli ready');

%% daq / encoder
s = daq.createSession('ni');
ch1 = addCounterInputChannel(s, 'Dev1', 0, 'Position');
ch1.EncoderType = 'X1';
circumferenceOfBall = 20;
encoderPPR = 1024;

disp('DAQ and rotary encoder ready');

%%
xoffset1 = 0;
xoffset2 = 0;
timeStart = clock();
i = 1;
totalDistance = 0;
encoderPosition = 0;
abortState = false;
HideCursor;
% ptb.activeTexture = ptb.GratingTexture(setup.contrast*2);

while ~abortState
    newTime  = clock();
    
    if strcmpi(setup.mouse, 'test')
        [~, ~, keyCode, ~] = KbCheck;
        if keyCode(165) == 1                     % right alt
            encoderPosition = encoderPosition + 1*setup.velocityGain;
        elseif keyCode(164) == 1                 % left alt
            encoderPosition = encoderPosition - 1*setup.velocityGain;
        end
    else
        encoderPosition = inputSingleScan(s);
        counterNBits    = 32;
        signedThreshold = 2^(counterNBits-1);
        encoderPosition(encoderPosition > signedThreshold) = encoderPosition(encoderPosition > signedThreshold) - 2^counterNBits;
    end
    encoderPosRev = encoderPosition / encoderPPR;
    encoderPosDeg = encoderPosRev * 360;
    encoderPosCM  = encoderPosRev * circumferenceOfBall;
    
    if i > 1
        elapsedTime   = etime(newTime, timeStart);
        timeDiff      = etime(newTime, oldTime);
        posDifference = encoderPosCM - oldEncoderPos;
        totalDistance = totalDistance + sqrt(posDifference^2);
        velocity      = posDifference / timeDiff;
        results.timeDiff(i)   = timeDiff;
        results.time(i)       = elapsedTime;
        results.totalTime     = elapsedTime;
        results.totalDistance = totalDistance;
        results.distance(i)   = totalDistance;
        results.position(i)   = encoderPosCM;
        results.velocity(i)   = velocity;
        xoffset1              = xoffset1 + (posDifference*setup.pixelsPerCM);
        xoffset2              = xoffset2 - (posDifference*setup.pixelsPerCM);
        
%         changeCurrentGrating;
%         results.contrast(i) = contrastSetting;
        updateVisualStimuli;
%         updateLivePlot;
    end
    
    oldTime = newTime;
    oldEncoderPos = encoderPosCM;
    i = i + 1;
    
    [~, ~, keyCode, ~] = KbCheck;
        if keyCode(27) == 1                     % escape
            abortState = true;
        end
    
end

Screen('CloseAll')
daqreset;

results.setup = setup;
results.setup.ptb = ptb;
finaliseFigures;
saveResults;
ShowCursor;
    

%% functions
    function makeGratings (varargin)
            newgrating = ptb.inc*cos(fr*x)*(setup.contrast/100) + ptb.grey;
            ptb.newGratingTexture = Screen('MakeTexture', ptb.window, newgrating, [], 1);
            ptb.activeTexture = ptb.newGratingTexture;
    end

    function changeCurrentGrating (varargin)
        %         if results.position(i) > 100
        %             ptb.activeTexture = ptb.GratingTexture(setup.changeTo*2);
        %         else
        %             ptb.activeTexture = ptb.GratingTexture(setup.contrast*2);
        %         end
        contrastSetting = str2double(get(contrastText, 'string'));
        if ~isequal(contrastSetting,prevContrastSetting)
            newgrating = ptb.inc*cos(fr*x)*(contrastSetting/100) + ptb.grey;
            ptb.newGratingTexture = Screen('MakeTexture', ptb.window, newgrating, [], 1);
            ptb.activeTexture = ptb.newGratingTexture;
        end
        prevContrastSetting = contrastSetting;
    end

    function updateVisualStimuli (varargin)
        srcRect1  = [xoffset1 0 xoffset1+ptb.visiblesize 100];
        srcRect2  = [xoffset2 0 xoffset2+ptb.visiblesize 100];
        destRect1 = [0 0 ptb.visiblesize ptb.screenHeight];
        destRect2 = [ptb.visiblesize 0 ptb.visiblesize*setup.numSplitScreens ptb.screenHeight];
        Screen('DrawTexture', ptb.window, ptb.activeTexture, srcRect1, destRect1); % 'screen' 1
        Screen('DrawTexture', ptb.window, ptb.activeTexture, srcRect2, destRect2); % 'screen' 2
        Screen('Flip', ptb.window);
    end

    function updateLivePlot (varargin)
        minPos = min(results.position);
        maxPos = max(results.position);
        minVel = min(results.velocity);
        maxVel = max(results.velocity);
        maxPos(maxPos == minPos) = maxPos + 1;
        maxVel(maxVel == minVel) = maxVel + 1;
        
        if i > 100
            set(positionPlotHandle, 'XData', results.time(i-100:i), 'YData', results.position(i-100:i));
            set(velocityPlotHandle, 'XData', results.time(i-100:i), 'YData', results.velocity(i-100:i));
            set(positionAxes, 'Xlim', [results.time(i-100) results.time(i)]);
            set(velocityAxes, 'Xlim', [results.time(i-100) results.time(i)]);
            set(trackPositionEnd, 'XData', results.position(end));
            set(trackPosition, 'XData', [min(results.position) max(results.position)]);
            bins = [minPos:(maxPos-minPos)/99:maxPos];
            [data, ~] = hist(results.position, bins);
            avgTimeSample = mean(diff(results.time));
            data = data * avgTimeSample;
            set(trackDwell, 'XData', bins, 'YData', data);
            set(timeText,         'string',sprintf('%0.2f', results.totalTime));
            set(totalDistText,    'string',sprintf('%0.2f', results.totalDistance));
            set(currentPosText,   'string',sprintf('%0.2f', results.position(i)));
            set(currentSpeedText, 'string',sprintf('%0.2f', results.velocity(i)));
            drawnow;
            
        else
            set(positionPlotHandle, 'XData', results.time(1:i), 'YData', results.position(1:i));
            set(velocityPlotHandle, 'XData', results.time(1:i), 'YData', results.velocity(1:i));
            set(positionAxes, 'Xlim', [0 results.time(i)]);
            set(velocityAxes, 'Xlim', [0 results.time(i)]);
            set(trackPositionEnd, 'XData', results.position(end));
            set(trackPosition, 'XData', [min(results.position) max(results.position)]);
            bins = [minPos:(maxPos-minPos)/99:maxPos];
            [data, ~] = hist(results.position, bins);
            avgTimeSample = mean(diff(results.time));
            data = data * avgTimeSample;
            set(trackDwell, 'XData', bins, 'YData', data);
            set(timeText,         'string',sprintf('%0.2f', results.totalTime));
            set(totalDistText,    'string',sprintf('%0.2f', results.totalDistance));
            set(currentPosText,   'string',sprintf('%0.2f', results.position(i)));
            set(currentSpeedText, 'string',sprintf('%0.2f', results.velocity(i)));
            drawnow;
        end
    end

    function abortFcn (varargin)
        abortState = true;
        set(abortButton, 'visible', 'off');
    end

    function saveResults (varargin)  
        mainDir = ['C:' filesep 'VR'];
        if (~exist(mainDir,'dir'))
            mkdir(mainDir);
        end
        mouseDir = [mainDir filesep 'Results' filesep setup.mouse];
        if (~exist(mouseDir,'dir'))
            mkdir(mouseDir);
        end
        
        currentDate = datestr(now,'yyyymmdd');
        currentTime = datestr(now, 'HHMM');
        sessionID = [currentDate '_' setup.mouse '_t' currentTime];
        filename = [mouseDir filesep sessionID];
        
        save([filename '.mat']);        
        saveas(fig, filename, 'pdf');
    end

    function finaliseFigures (varargin)
        minPos = min(results.position);
        maxPos = max(results.position);
        minVel = min(results.velocity);
        maxVel = max(results.velocity);
        maxPos(maxPos == minPos) = maxPos + 1;
        maxVel(maxVel == minVel) = maxVel + 1;
        
        set(positionPlotHandle, 'XData', results.time, 'YData', results.position);
        set(positionAxes, 'xlim',[0 max(results.time)], 'ylim',[1.1*min(results.position) 1.1*max(results.position)]);
        
        set(velocityPlotHandle, 'XData', results.time, 'YData', results.velocity);
        set(velocityAxes, 'xlim',[0 max(results.time)], 'ylim',[1.1*min(results.velocity) 1.1*max(results.velocity)]);
        %         set(fig, 'currentaxes', velocityAxes);
        avgVel = nanmean(results.velocity);
        set(avgVelLine, 'XData', [0 max(results.time)], 'YData', [avgVel avgVel], 'visible','on');
  
                    set(trackPositionEnd, 'XData', results.position(end));
            set(trackPosition, 'XData', [min(results.position) max(results.position)]);

        bins          = minPos:(maxPos-minPos)/49:maxPos;
        [data, ~]     = hist(results.position, bins);
        avgTimeSample = mean(diff(results.time));
        data          = data * avgTimeSample;
        set(trackDwell, 'XData', bins, 'YData', data);
%         set(fig, 'currentaxes', trackPositionAxes);
%         ylim([1.1*min(data) 1.1*max(data)])
%         xlim([1.1*min(results.position) 1.1*max(results.position)])
    end
end