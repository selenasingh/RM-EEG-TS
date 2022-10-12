%%%%% EEG TASK-SWITCHING PARADIGM %%%%%
%%%---File history:
%%% original: Saurabh Shaw, 2020
%%% current: Selena Singh, 2022

%%% Changes made (Singh): 
%%% - Re-organize so initialization occurs in sep. file
%%% - Add Stroop task, Cued Rumination Trials
%%% - File organization for participant data 
%%% - Biosemi data saving directly from MATLAB
%%% - unify "Run_composite_test" with "Run_composite_test_triggers", add
%%%     EEG trigger saving to trials

%%%%%%%------------------------------
sca; %close psychtoolbox windows
close all; 
clear; %clear workspace
clc; 

test_run = true; % TODO: instructions set to only appear in test situation. Ask Saurabh why.
resting_state = false; % Collecting resting state data?

%%%%%%%%%%%%% Path and Data Saving Set-up %%%%%%%%%%%%%%%
%proj_path = fullfile('E:', 'selena', 'RM-EEG'); %for computer at htrl
proj_path = fullfile('/Users','selenasingh', 'Desktop', 'PhD - current work', 'EEG study', 'RM-EEG-TS', 'RM-EEG-TS'); %local 
pt = readtable(fullfile(proj_path, 'participants.xlsx'));
pid = pt.id(end); %extract participant ID
session = pt.session(end); %pre or post intervention, or single, session. 
subject_name = join([string(pid) '_' char(session)], '');

% data saving, current participant's path
data_path = fullfile(proj_path, 'data', num2str(pid));

%%%%%%%%%%%%%%%%%%% Experiment Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%
experiment_params % load experiment params 

%%%%%%%%%%%%% Extracting Ruminations, AMs, and WM words %%%%%%%%%%%%
[CR_data_table] = readtable(fullfile(proj_path, 'memories', join(['Ruminations_' subject_name '.xlsx'],'')));
[AM_data_table] = readtable(fullfile(proj_path, 'memories', join(['Episodic_Memories_' subject_name '.xlsx'],'')));
[corpus_data_table] = readtable(fullfile(proj_path, 'memories', 'Word_corpus.xlsx'));

%initialization
AM_words =  {}; AM_word_rating_cell = []; AM_memory_number = [];
CR_words = {}; CR_word_rating_cell = []; CR_memory_number = [];

%taking from table, organizing for experiment loop
%AUTOBIOGRAPHICAL MEMORIES
i = 1;
while i <= size(AM_data_table,1) && ~isempty(cell2mat(AM_data_table{i,3}))
    AM_words = [AM_words strsplit(cell2mat(AM_data_table{i,3}),',')];
    AM_word_rating_cell = [AM_word_rating_cell strsplit(cell2mat(AM_data_table{i,4}),',')];
    num_words_added = length(strsplit(cell2mat(AM_data_table{i,3}),','));
    AM_memory_number = [AM_memory_number repmat(i,[1,num_words_added])];
    i = i+1;
end
num_AM_words = size(AM_words,2);

%CUED RUMINATION
j = 1;
while j <= size(CR_data_table,1) && ~isempty(cell2mat(CR_data_table{j,3}))
    CR_words = [CR_words strsplit(cell2mat(CR_data_table{j,3}),',')];
    CR_word_rating_cell = [CR_word_rating_cell strsplit(cell2mat(CR_data_table{j,4}),',')];
    num_words_added = length(strsplit(cell2mat(CR_data_table{j,3}),','));
    CR_memory_number = [CR_memory_number repmat(j,[1,num_words_added])];
    j = j+1;
end
num_CR_words = size(CR_words,2);

%WORKING MEMORY WORDS
corpus_words = corpus_data_table{:,1}';
num_corpus_words = size(corpus_words,2);

% Create randomized list of either WM, AM, or CR task blocks (0-AM, 1-WM, 2-CR):
Exp_blocks = [zeros(1,nBlocks),ones(1,nBlocks), 2.*ones(1,nBlocks)];
Exp_blocks = Exp_blocks(randperm(length(Exp_blocks)));

%%%%%%%%%%%%%%%%%%%% STROOP TASK %%%%%%%%%%%%%%%%%%%%%%%%
Run_stroop

%%%%%%%%%%%%%%%%%%%% SETTING UP EEG DATA SAVING %%%%%%%%%%%%%%%%%
if ~test_run

    % data saving, current participant's path 
    data_path_eeg = fullfile(proj_path, 'data', sprintf('%d', pid), 'eeg'); % change so aligns with saurabh's requirements
    
    % get access to fieldtrip 
    addpath(genpath('E:\Saurabh_files\Research_code\Toolboxes\FieldTrip'));
    rmpath(genpath('E:\Saurabh_files\Research_code\Toolboxes\Fieldtrip\compat'));
    
    % start recording EEG
    biosemi2ftPath = fullfile('E:', 'Saurabh_files', 'Research_code', 'Toolboxes', 'Fieldtrip', 'realtime', 'bin', 'win32');
    
    % turning biosemi on, start saving data
    system('start powershell')
    cmd = {'cd %s; .\\biosemi2ft biosemi_config.txt %s -', biosemi2ftPath, data_path_eeg};
    clipboard('copy', sprintf(cmd{:}));
    fprintf('\n\nCopy and paste the following command into the powershell window that just opened:\n');
    fprintf('(Alternatively, just paste using ctrl + V because the command has already been copied to your clipboard \n\n');
    fprintf(cmd{:})
    fprintf('\n\nThen press S to enable saving\n')
    input('When you have done this, press enter to continue', 's');
end

%%%%%%%%%%%%%%%%%%% Fieldtrip setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~test_run
    cfg                = [];
    cfg.blocksize      = 1;                            % seconds
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

    % Setup COM port for writing triggers to Biosemi interface:
    triggerCOMport = 'COM4';
    [portHandle, errMsg] = IOPort('OpenSerialPort', triggerCOMport, 'BaudRate=115200');
    if ~isempty(errMsg) input('Something went wrong:', 's'); end

end

%%%%%%%%%%%%%%%%% Display Setup, using PsychToolBox %%%%%%%%%%%%%%%%%%%%%
%instruction Text
text = sprintf('Three different tasks will be presented. \n\n The specific instructions for each task will be presented shortly. \n\n Between each task, you will be presented with one of three images \n which will indicate the type of task you will be performing next.\n');

% Setup screen
Screen('Preference', 'SkipSyncTests', 1);  

% Counts the number of monitors, and uses highest number monitor
mons=size(get(0, 'MonitorPositions'));
screenNum = mons(1)-1;
sca

% Open a windows in default monitor. Resolution and size by default
[wPtr,wRect] = Screen('OpenWindow',screenNum); 

% Hide mouse
% HideCursor;

% Define the center of the screen
[x0, y0] = RectCenter(wRect);

% Find the black and white color
black  = BlackIndex(wPtr);
white  = WhiteIndex(wPtr);

% text paramaters
Screen('TextFont',wPtr, 'Courier New');
Screen('TextSize',wPtr, 28);

% Fixation parameters
fixSize  = 25; % In pixels
fixThick = 3;  % Thickness of the fixation lines

% Blacken the Screen
Screen('FillRect', wPtr,black);
Screen(wPtr, 'Flip');

% Display Pre-Training Instructions
DrawFormattedText(wPtr, text, 'center', 'center', white);
Screen('Flip', wPtr);
WaitSecs(5.0);
%wait for keypress
KbWait;
%remove instruction
Screen('Flip', wPtr);

Screen('Preference', 'SkipSyncTests', 1);

%%%%%%%%%%%%%%%%%%%%% Experiment Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%% ----- Resting State Acquisition:

if resting_state
    Resting_task_instruction = 'Please sit back, relax, close your eyes and \n \n do not think of anything in particular \n';
    DrawFormattedText(wPtr, Resting_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    [~, resttrigTimestart] = IOPort('Write', portHandle, uint8(18)); 
    WaitSecs(resting_time); Screen('Flip', wPtr);
    
    % Get EEG data (& online processing): 
    if ~test_run
        [resting_buffer_INDEX,resting_EEG_MARKERS,resting_EEG,prevSample] = get_EEG_data(cfg,blocksize_resting_time,1,chanindx,[],[],[]);
        save(strcat('resting_EEG_',subject_name),'cfg','resting_EEG','resting_EEG_MARKERS','resting_buffer_INDEX');        
    end   

    % Resting task instruction done:
    [~, resttrigTimeend] = IOPort('Write', portHandle, uint8(28));
    Resting_task_instruction = 'Resting state completed. Please wait for task section to begin.';
    DrawFormattedText(wPtr, Resting_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(20); Screen('Flip', wPtr);
end

%%%%%%%%%%% ----- Experiment loop:

%initialization 
EEG = cell(1,length(Exp_blocks));
class_MARKERS = cell(1,length(Exp_blocks));
class_MARKERS_idx = cell(1,length(Exp_blocks));
EEG_MARKERS = cell(1,length(Exp_blocks));
buffer_INDEX = cell(1,length(Exp_blocks));
question_RESP = cell(1,length(Exp_blocks));
triggers = cell(1,length(Exp_blocks));
triggerTimes = cell(1,length(Exp_blocks));
screenflipTimes = cell(1,length(Exp_blocks));
screenflipText = cell(1,length(Exp_blocks));
question_responses_RAW = cell(1,length(Exp_blocks));
question_responses_RAWTIMES = cell(1,length(Exp_blocks));
prevSample = 1;

for block = 1:length(Exp_blocks)
    EVENT = [];
    DATA = [];
    class_MARK = [];
    class_MARK_idx = [];
    INDEX = [];
    
    tic;
    if Exp_blocks(block) == 1   % It is an AM trial (Class 2)
        
        switch iti_stim
            case 'word'
                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2));
                
                DrawFormattedText(wPtr,'Autobiographical Memory', 'center', 'center', white);
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                class = 1; % interblock time (Class 1)
                [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
                triggerTimes{block} = [triggerTimes{block} trigTimes]; 
                triggers{block} = [triggers{block} uint8(class)]; 
                WaitSecs(floor(interBlock_time/2)); Screen('Flip', wPtr); 
                
                
            case 'symbol'                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                class = 1; % interblock time (Class 1)
                [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
                triggerTimes{block} = [triggerTimes{block} trigTimes]; 
                triggers{block} = [triggers{block} uint8(class)]; 
                WaitSecs(interBlock_time); 
                Screen('Flip', wPtr); 
                class = 1; % interblock time (Class 1)             
        end %end switch
        
        % Populate the class_MARK vector for interblock segment:
        if ~test_run [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_interBlock_time,prevSample,class, block, class_MARK, class_MARK_idx); 
        end %end if
        class = 2; 
        [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
        triggerTimes{block} = [triggerTimes{block} trigTimes]; 
        triggers{block} = [triggers{block} uint8(class)]; 
        Run_AM
        triggerTimes{block} = [triggerTimes{block} ampTrigger_timestamp];
        
    elseif Exp_blocks(block) == 0     % It is a WM trial (Class 3)
        
        switch iti_stim
            case 'word'
                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2));
                
                DrawFormattedText(wPtr, 'Word Memory', 'center', 'center', white); 
                screenflipText{block} = [screenflipText{block} {'Word Memory'}];
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                class = 1; % interblock time (Class 1)
                [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
                triggerTimes{block} = [triggerTimes{block} trigTimes]; 
                triggers{block} = [triggers{block} uint8(class)]; 
                WaitSecs(floor(interBlock_time/2)); 
                Screen('Flip', wPtr);
                
            case 'symbol'                
                % Draw white circle
                Screen('FillOval', wPtr,[0,0,0]);
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                WaitSecs(interBlock_time); 
                Screen('Flip', wPtr); 
                class = 1; % interblock time (Class 1)
                
        end %end switch
        
        % Populate the class_MARK vector for interblock segment:
        if ~test_run 
            [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_interBlock_time,prevSample,class, block, class_MARK, class_MARK_idx); 
        end %end if
        class = 3; 
        [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
        triggerTimes{block} = [triggerTimes{block} trigTimes]; 
        triggers{block} = [triggers{block} uint8(class)];       
        Run_WM
        triggerTimes{block} = [triggerTimes{block} ampTrigger_timestamp];

    elseif Exp_blocks(block) == 2 % cued rumination trial 
        switch iti_stim
            case 'word'
                 % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2));
                
                DrawFormattedText(wPtr,'Rumination', 'center', 'center', white);
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                class = 1; % interblock time (Class 1)
                [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
                triggerTimes{block} = [triggerTimes{block} trigTimes]; 
                triggers{block} = [triggers{block} uint8(class)]; 
                WaitSecs(floor(interBlock_time/2)); 
                Screen('Flip', wPtr); 
                
            case 'symbol'                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                [~,screenFlip_time] = Screen('Flip', wPtr); 
                screenflipTimes{block} = [screenflipTimes{block} screenFlip_time];
                class = 1; % interblock time (Class 1)
                [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
                triggerTimes{block} = [triggerTimes{block} trigTimes]; 
                triggers{block} = [triggers{block} uint8(class)]; 
                WaitSecs(interBlock_time); 
                Screen('Flip', wPtr); 
                class = 1; % interblock time (Class 1)                  
       
        end %end switch
        % Populate the class_MARK vector for interblock segment:
        if ~test_run 
            [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_interBlock_time,prevSample,class, block, class_MARK, class_MARK_idx); 
        end %end if
        class = 4;
        [~, trigTimes] = IOPort('Write', portHandle, uint8(class)); 
        triggerTimes{block} = [triggerTimes{block} trigTimes]; 
        triggers{block} = [triggers{block} uint8(class)]; 
        Run_CR
        triggerTimes{block} = [triggerTimes{block} ampTrigger_timestamp];

        
    end %end outer if (if, elseif, else)
    
    % Collect EEG from the duration of this block:
    
    if ~test_run 
        block_runtime = toc;
        blocksize = round(block_runtime*hdr.Fs);
        [buffer_INDEX{block},EEG_MARKERS{block},EEG{block},prevSample] = get_EEG_data(cfg,blocksize,prevSample,chanindx,INDEX,EVENT,DATA); 
    end %end if

    question_RESP{block} = question_responses;
    question_responses_RAW{block} = question_responses_raw;
    question_responses_RAWTIMES{block} = question_responses_rawtimes;
    class_MARKERS{block} = class_MARK;
    class_MARKERS_idx{block} = class_MARK_idx;
    
    % Save intermittent data in case of crash:
    if ~test_run
        files = dir(strcat('composite_task_',subject_name,'_block_',num2str(block),'*.mat'));
        save([strcat(data_path, '\', 'composite_task_',subject_name,'_block_',num2str(block),num2str(length(files)+1))],'cfg','EEG','class_MARKERS','class_MARKERS_idx','EEG_MARKERS','buffer_INDEX','question_RESP','Exp_blocks','block',...
            'triggerTimes','triggers','screenflipText','screenflipTimes','question_responses_RAW','question_responses_RAWTIMES');
    end %end if
    
end %end for loop for experiment block

sca;

%%%%%%%%%%%%%%%%% Save the entire dataset: %%%%%%%%%%%%%%%%%%%%%
if ~test_run
    save(strcat(data_path, '\', 'composite_task_',subject_name,'_full_dataset'),'cfg','EEG','class_MARKERS','class_MARKERS_idx','EEG_MARKERS','buffer_INDEX','question_RESP','Exp_blocks','block',...
        'triggerTimes','triggers','screenflipText','screenflipTimes','question_responses_RAW','question_responses_RAWTIMES');
    save([strcat(data_path, '\','End_Workspace_', subject_name)])
end

sca;
IOPort('Close', portHandle);

%%%%%%%%%%%%%%%% Concluding experiment %%%%%%%%%%%%%%%%%%%%
if ~test_run
    rmpath(genpath('E:\Saurabh_files\Research_code\Toolboxes\FieldTrip'));
    fprintf('\n\nExperiment complete! \nRemember to stop recording the EEG data by first pressing D, then Esc\n')
    fprintf('Remember, also, to add the participant to the payment log\n\n')
else
    fprintf('Test run complete!')
end 

