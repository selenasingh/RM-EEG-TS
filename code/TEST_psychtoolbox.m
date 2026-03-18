% Clear the workspace and the screen
sca;
close all;
clear;

subject_name = 'Neutral';
exp_time = datestr(now,30);  % Date and Time of the experiment

Trial_duration = 2;             %Inter-trial interval (time between end and start of trials)
prefix_time = 2;     %How long the fixation appears before the cue
interBlock_time = 5;         % Time between two blocks (duration of time saliency information is shown)
instructions_time = 5;      % Duration for which the instructions show up before the onset of a task

% Experimental settings:
nBlocks = 10;           % Number of Blocks
nTrials = 10;            % Number of trials
nClass = 2;             % Number of task classes

% WM n-back Settings:
nBack_num = 2; % Recollection task - or 2 back task
num_questions = 5;
num_question_options = 4;
repeat_AM_words = true;

% Inter-trial stimulus type:
iti_stim = 'word';
test_run = true;

% Resting state:
resting_state = false;
resting_time = 5*60;

text = sprintf('Two different tasks will be presented. \n\n The specific instructions for each task will be presented shortly. \n\n Between each task, you will be presented with one of two images \n which will indicate the type of task you will be performing next.\n');


% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. With our setup, values defined between 0 and 1.
white = WhiteIndex(screenNumber);

black = BlackIndex(screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half the luminace value for white
grey = white / 2;

startXpix = 120;
startYpix = 50;
dimX = 400;
dimY = 250;

% Open an on screen window using PsychImaging and color it grey.

% Hide mouse
%HideCursor;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, ...
                       [startXpix startYpix startXpix + dimX startYpix + dimY]);

% Define the center of the screen
[x0, y0] = RectCenter(windowRect);

%black  = BlackIndex(window);
%white  = WhiteInde
% x(window);

% text paramaters
Screen('TextFont', window, 'Courier New');
Screen('TextSize', window, 12);

fixSize  = 25; % In pixels
fixThick = 3;  % Thickness of the fixation lines

% Blacken the Screen
%Screen('FillRect', window ,black);
Screen(window, 'Flip');

% Display Pre-Training Instructions
DrawFormattedText(window, text, 'center', 'center', white);
Screen('Flip', window);
WaitSecs(5.0);
%wait for keypress
KbStrokeWait;
%remove instruction
Screen('Flip', window);

%Screen('Preference', 'SkipSyncTests', 1)
% Now we have drawn to the screen we wait for a keyboard button press (any
% key) to terminate the demo.


% Clear the screen.
sca;