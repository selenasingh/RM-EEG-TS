%% Test Setup:
clear all; clc; % addpath(genpath('Z:\expts\AttentionBCI\Experiment_code'));
addpath(genpath('C:\Users\gTec Laptop\Documents\MATLAB\Toolboxes\Fieldtrip'));
% rmpath(genpath('C:\Users\gTec Laptop\Documents\MATLAB\Toolboxes\Fieldtrip\compat'));

subject_ID = 'DM_ExtSpeakersPC34';
exp_time = datestr(now,30);  % Date and Time of the experiment

% Timing Settings:
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
test_run = false;
FourWayTest = false;
TwoWayTest = true;


% Resting state:
resting_state = false;
resting_time = 5*60;

%% Fieldtrip setup
if ~test_run
    cfg                = [];
    cfg.blocksize      = 6;                            % seconds
    cfg.overlap        = 0;
    cfg.jumptoeof      = 'no';
    cfg.bufferdata     = 'last';
    cfg.channel        = 'all';
    cfg.dataset        = 'buffer://localhost:1972';    % where to read the data
    % cfg.datafile        = 'buffer://localhost:1972';
    
    % translate dataset into datafile+headerfile
    cfg = ft_checkconfig(cfg, 'dataset2files', 'yes');
    cfg = ft_checkconfig(cfg, 'required', {'datafile' 'headerfile'});
    
    % ensure that the persistent variables related to caching are cleared
    clear ft_read_header
    
    % start by reading the header from the realtime buffer
    hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true, 'retry', true);
    
    % make a copy of the header that will be passed to the writing function, update with the channel selection
    chanindx          = 1:hdr.nChans;
    writehdr          = hdr;
    writehdr.nChans   = length(chanindx);
    writehdr.label    = writehdr.label(chanindx);
    writehdr.chantype = writehdr.chantype(chanindx);
    writehdr.chanunit = writehdr.chanunit(chanindx);
    
    % determine the size of blocks to process
    blocksize_Trial_duration = round(Trial_duration*hdr.Fs);
    blocksize_prefix = round(prefix_time * hdr.Fs);
    blocksize_interBlock_time = round(interBlock_time*hdr.Fs);
    blocksize_instructions_time = round(instructions_time*hdr.Fs);
    blocksize_resting_time = round(resting_time*hdr.Fs);
    overlap = round(cfg.overlap*hdr.Fs);
    
    if strcmp(cfg.jumptoeof, 'yes')
        prevSample = hdr.nSamples * hdr.nTrials;
    else
        prevSample = 0;
    end
    count = 0;
end
%% Display Setup
%instruction Text
%text = sprintf('Two different tasks will be presented. \n\n The specific instructions for each task will be presented shortly. \n\n Between each task, you will be presented with one of two images \n which will indicate the type of task you will be performing next.\n');
text = sprintf('Several tasks will be presented, each 5 seconds long in duration.\n\n Specific instructions for each task will be presented. \n\n For the duration of each task, please try and minimize eye blinks and motor movement.\n');
text2 = sprintf('test 1');
text3 = sprintf('test 2');
text4 = sprintf('test 3');
% Setup screen
% Get/set details of environment, computer, and video card (i.e. Screen)
%for testing this is okay. For real simuluation make sure, skipsynctests =0
Screen('Preference', 'SkipSyncTests', 1);  

% Counts the number of monitors, and uses highest number monitor
mons=size(get(0, 'MonitorPositions'));
screenNum = mons(1)-1;sca

% Define the monitor to used (0 = default one )
% screenNum = 2;

% Open a windows in default monitor. Resolution and size by default
% Could modify for not full screen (debugging purposes) but may present
% functionality problems

[wPtr,wRect] = Screen('OpenWindow',screenNum);

% Hide mouse
HideCursor;

% Define the center of the screen
[x0, y0] = RectCenter(wRect);

% Find the black and white color
black  = BlackIndex(wPtr);
white  = WhiteIndex(wPtr);
green = [0 255 0];
red = [255,0,0];

% text paramaters
Screen('TextFont',wPtr, 'Times New Roman');
%Screen('TextFont',wPtr, 'Courier New');
Screen('TextSize',wPtr, 38);

%Screen('TextStyle', wPtr, 1+2);

% Fixation parameters
fixSize  = 25; % In pixels
fixThick = 3;  % Thickness of the fixation lines

% Blacken the Screen
Screen('FillRect', wPtr,black);
Screen(wPtr, 'Flip');

% Display Pre-Training Instructions
DrawFormattedText(wPtr, text, 'center', 'center', white);
Screen('Flip', wPtr);
WaitSecs(1);
%wait for keypress
KbWait;

%{
 % SCREEN TESTS
%test 1
DrawFormattedText(wPtr, text2, 'center', 'center', white);
Screen('Flip', wPtr);
WaitSecs(1);
%KbWait;

%test 2
DrawFormattedText(wPtr, text3, 'center', 'center', white);
Screen('Flip', wPtr);
WaitSecs(1);


x0-fixSize, y0, x0+fixSize, y0
Screen('FillRect', wPtr, white, [x0-fixSize,y0,50,100]);
Screen('Flip', wPtr);



%top right
Screen('drawLine', wPtr, green, x0 + x0./2 - fixSize, y0./4, x0 + x0./2 + fixSize, y0./4, fixThick);
Screen('drawLine', wPtr, green, x0 + x0./2, y0./4-fixSize, x0 + x0./2, y0./4+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);

%top left
Screen('drawLine', wPtr, red, x0./4 - fixSize, y0./4, x0./4 + fixSize, y0./4, fixThick);
Screen('drawLine', wPtr, red, x0./4, y0./4-fixSize, x0./4, y0./4+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);

%bottom left
Screen('drawLine', wPtr, white, x0./4 - fixSize, (y0 + y0./2), x0./4 + fixSize, (y0 + y0./2), fixThick);
Screen('drawLine', wPtr, white, x0./4, (y0 + y0./2)-fixSize, x0./4, (y0 + y0./2)+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);

%bottom right
Screen('drawLine', wPtr, [255 0 255], x0 + x0./2 - fixSize, (y0 + y0./2), x0 + x0./2 + fixSize, (y0 + y0./2), fixThick);
Screen('drawLine', wPtr, [255 0 255], x0 + x0./2, (y0 + y0./2)-fixSize, x0 + x0./2, (y0 + y0./2)+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);
 

%right-centre
Screen('drawLine', wPtr, green, x0 + x0./2 - fixSize, y0, x0 + x0./2 + fixSize, y0, fixThick);
Screen('drawLine', wPtr, green, x0 + x0./2, y0-fixSize, x0 + x0./2, y0+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);

%left-centre
Screen('drawLine', wPtr, red, x0./4 - fixSize, y0, x0./4 + fixSize, y0, fixThick);
Screen('drawLine', wPtr, red, x0./4, y0-fixSize, x0./4, y0+fixSize, fixThick);
Screen('Flip', wPtr);
WaitSecs(1);

    %wait for key press
KbWait;
%}

%remove instruction
Screen('Flip', wPtr);

Screen('Preference', 'SkipSyncTests', 1); % why need to re-do screen preferences?



%% Resting State Acquisition
if resting_state
    Resting_task_instruction = 'Please sit back, relax, close your eyes and \n \n do not think of anything in particular \n';
    DrawFormattedText(wPtr, Resting_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(resting_time); 
    
    Screen('Flip', wPtr);
    
    % Get EEG data: 
    if ~test_run
        [resting_buffer_INDEX,resting_EEG_MARKERS,resting_EEG,prevSample] = get_EEG_data(cfg,blocksize_resting_time,1,chanindx,[],[],[]);
        save(strcat('resting_EEG_',subject_ID),'cfg','resting_EEG','resting_EEG_MARKERS','resting_buffer_INDEX');        
    end    
end

%% Experiment Loop:
%load Pink_Noise
Fs = 11025*4; %is this defaulted somewhere?

%if we are testing 4 speaker scenario
if FourWayTest
    
Exp_blocks = 400; %100 trials per direction, not in use
Block_Time = 6; %5 second epochs ~ why 5 seconds? Is there an optimal epoch time? - not confirmed
Inter_Block_Time = Block_Time/2;

EEG = cell(1,length(Exp_blocks)); % not in use
A = [ones(1,2), 2*ones(1,2), 3*ones(1,2), 4*ones(1,2)]; %100*4
Real_A = A(randperm(length(A)));

for block = 1:length(A)
    EVENT = [];
    DATA = [];
    
    tic;  
    if Real_A(block) == 1
        %top right
        Screen('drawLine', wPtr, green, x0 + x0./2 - fixSize, y0./4, x0 + x0./2 + fixSize, y0./4, fixThick);
        Screen('drawLine', wPtr, green, x0 + x0./2, y0./4-fixSize, x0 + x0./2, y0./4+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        samples = [11*Fs,17*Fs];
        clear y Fs
        [y, Fs] = audioread('Lecture_3.wav', samples);
        B = size(y(:,1));
        wavedata = [zeros(B),y(:,1)];
        %y(1,:) = 0;
        sound(wavedata,Fs);        
        WaitSecs(floor(Block_Time));
        
    elseif Real_A(block) == 2
        %top left
        Screen('drawLine', wPtr, red, x0./4 - fixSize, y0./4, x0./4 + fixSize, y0./4, fixThick);
        Screen('drawLine', wPtr, red, x0./4, y0./4-fixSize, x0./4, y0./4+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        samples = [23*Fs,29*Fs]; 
        clear y Fs
        [y, Fs] = audioread('Lecture_4.mp3', samples);
        C = size(y(:,1));
        wavedata2 = [y(:,1),zeros(C)];
        sound(wavedata2,Fs);        
        WaitSecs(floor(Block_Time));
       
        
    elseif Real_A(block) == 3
        Screen('drawLine', wPtr, white, x0./4 - fixSize, (y0 + y0./2), x0./4 + fixSize, (y0 + y0./2), fixThick);
        Screen('drawLine', wPtr, white, x0./4, (y0 + y0./2)-fixSize, x0./4, (y0 + y0./2)+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        samples = [30*Fs,36*Fs]; 
        clear y Fs
        [y, Fs] = audioread('Lecture_5.wav', samples);
        sound(y,Fs);
        WaitSecs(floor(Block_Time));        
        
        
    elseif Real_A(block) == 4
        %bottom right
        Screen('drawLine', wPtr, [255 0 255], x0 + x0./2 - fixSize, (y0 + y0./2), x0 + x0./2 + fixSize, (y0 + y0./2), fixThick);
        Screen('drawLine', wPtr, [255 0 255], x0 + x0./2, (y0 + y0./2)-fixSize, x0 + x0./2, (y0 + y0./2)+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        samples = [66*Fs,72*Fs]; 
        clear y Fs
        [y, Fs] = audioread('Lecture_2.mp3', samples);
        sound(y,Fs);
        WaitSecs(floor(Block_Time));        
    end
    
    Screen('drawLine', wPtr, white, x0-fixSize, y0, x0+fixSize, y0, fixThick);
    Screen('drawLine', wPtr, white, x0, y0-fixSize, x0, y0+fixSize, fixThick);
    Screen('Flip', wPtr);
    
    
    samples = [1*Fs,4*Fs]; %read the first 2 seconds
    clear y Fs
    [y, Fs] = audioread('Pink_Noise.wav', samples);
    sound(y,Fs);
    WaitSecs(Inter_Block_Time);
end

%else if we are testing 2 speaker scenario
elseif TwoWayTest
    
Exp_blocks = 30; %100 trials per direction, not in use
Block_Time = 6; %5 second epochs ~ why 5 seconds? Is there an optimal epoch time? - edit: confirming 6 seconds is sufficient
Inter_Block_Time = Block_Time/2;

EEG = cell(1,length(Exp_blocks)); % NOT USED RIGHT NOW - Use for this?
A = [ones(1,Exp_blocks/2), 2*ones(1,Exp_blocks/2)]; %A = [ones(1,100), 2*ones(1,100)];
Real_A = A(randperm(length(A)));
%blocksize_trials = Block_Time*hdr.Fs;

% Load audio files:
y = cell(1,length(unique(A)));
samples = [21*Fs,27*Fs]; clear Fs; [y{1}, Fs] = audioread('Lecture_3.wav', samples);
samples = [23*Fs,29*Fs]; clear Fs; [y{2}, Fs] = audioread('Lecture_4.mp3', samples);
samples = [1*Fs,4*Fs]; [p, Fs] = audioread('Pink_Noise.wav', samples);

current_audio_length = 0;
for block = 1:length(A)
    EVENT = [];
    DATA = [];
    INDEX = [];
    
    tic;  
    if Real_A(block) == 1
        %RIGHT
        Screen('drawLine', wPtr, green, x0 + x0./2 - fixSize, y0, x0 + x0./2 + fixSize, y0, fixThick);
        Screen('drawLine', wPtr, green, x0 + x0./2, y0-fixSize, x0 + x0./2, y0+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        B = size(y{Real_A(block)}(:,1));
        wavedata = [zeros(B),y{Real_A(block)}(:,1)];
        sound(wavedata,Fs);        
        WaitSecs(floor(Block_Time));
        
    elseif Real_A(block) == 2
        %LEFT
        Screen('drawLine', wPtr, red, x0./4 - fixSize, y0, x0./4 + fixSize, y0, fixThick);
        Screen('drawLine', wPtr, red, x0./4, y0-fixSize, x0./4, y0+fixSize, fixThick);
        Screen('Flip', wPtr);
        
        C = size(y{Real_A(block)}(:,1));
        wavedata2 = [y{Real_A(block)}(:,1),zeros(C)];
        sound(wavedata2,Fs);        
        WaitSecs(floor(Block_Time));
        
    end
    
    % Collect EEG from the duration of this block:
    block_runtime = toc;
    if ~test_run
        blocksize = round(block_runtime*hdr.Fs); 
        [buffer_INDEX{block},EEG_MARKERS{block},EEG{block},prevSample] = get_EEG_data(cfg,blocksize,prevSample,chanindx,INDEX,EVENT,DATA);
    end
    %question_RESP{block} = question_responses;
    class_MARKERS{block} = Real_A(block);
    %class_MARKERS_idx{block} = class_MARK_idx;
    
    % Save intermittent data in case of crash:
    if ~test_run
        files = dir(strcat('attentionBCI_pretrain_',subject_ID,'_block_',num2str(block),'*.mat'));
        save([strcat('attentionBCI_pretrain_',subject_ID,'_block_',num2str(block)),num2str(length(files)+1)],'cfg','EEG','class_MARKERS','EEG_MARKERS','buffer_INDEX','Exp_blocks','block','Real_A')
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This is where the data processing would occur when running in online
    % mode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    Screen('drawLine', wPtr, white, x0-fixSize, y0, x0+fixSize, y0, fixThick);
    Screen('drawLine', wPtr, white, x0, y0-fixSize, x0, y0+fixSize, fixThick);
    Screen('Flip', wPtr);

    sound(p,Fs);
    WaitSecs(Inter_Block_Time);
    

end

% Save the entire dataset:
if ~test_run
    save(strcat('attentionBCI_pretrain_',subject_ID,'_full_dataset'),'cfg','EEG','class_MARKERS','EEG_MARKERS','buffer_INDEX','Exp_blocks','block','Real_A')
    save(['End_Workspace_' subject_ID])
end

end




