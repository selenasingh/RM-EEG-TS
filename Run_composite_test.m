%% Test Setup:
clear all; clc; addpath(genpath('Z:\expts\AttentionBCI\Experiment_code'));

subject_name = 'GH';
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

% Resting state:
resting_state = false;
resting_time = 5*60;

%% Fieldtrip setup
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
end
%% Display Setup
%instruction Text
text = sprintf('Two different tasks will be presented. \n\n The specific instructions for each task will be presented shortly. \n\n Between each task, you will be presented with one of two images \n which will indicate the type of task you will be performing next.\n');

% Setup screen
Screen('Preference', 'SkipSyncTests', 1);  

% Counts the number of monitors, and uses highest number monitor
mons=size(get(0, 'MonitorPositions'));
screenNum = mons(1)-1;sca

% Define the monitor to used (0 = default one )
% screenNum = 2;

% Open a windows in default monitor. Resolution and size by default
[wPtr,wRect] = Screen('OpenWindow',screenNum);

% Hide mouse
HideCursor;

% Define the center of the screen
[x0, y0] = RectCenter(wRect);

% Find the black and white color
black  = BlackIndex(wPtr);
white  = WhiteIndex(wPtr);

% text paramaters
Screen('TextFont',wPtr, 'Courier New');
Screen('TextSize',wPtr, 28);
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
WaitSecs(5.0);
%wait for keypress
KbWait;
%remove instruction
Screen('Flip', wPtr);

Screen('Preference', 'SkipSyncTests', 1);

%% Experiment Setup:

% Read in the Autobiographical memory (AM) words
from the xlsx file:
AM_fileName = ['Episodic_Memories_' subject_name '.xlsx'];
%AM_fileName = ['Episodic_Memories.xlsx'];
[AM_data_table] = readtable(AM_fileName);

% Extract the AM words from AM_data_table:
AM_words = {}; AM_word_rating_cell = []; AM_memory_number = [];
i = 1;
while i <= size(AM_data_table,1) && ~isempty(cell2mat(AM_data_table{i,3}))
    AM_words = [AM_words strsplit(cell2mat(AM_data_table{i,3}),',')];
    AM_word_rating_cell = [AM_word_rating_cell strsplit(cell2mat(AM_data_table{i,4}),',')];
    num_words_added = length(strsplit(cell2mat(AM_data_table{i,3}),','));
    AM_memory_number = [AM_memory_number repmat(i,[1,num_words_added])];
    i = i+1;
end
num_AM_words = size(AM_words,2);
% AM_word_rating = [];
% for j = 1:num_AM_words
%     AM_word_rating = [AM_word_rating str2num(AM_word_rating_cell{j})];    
% end
% clear AM_word_rating_cell

% Read in the other words from the English corpus:
corpus_fileName = 'Word_corpus.xlsx';
[corpus_data_table] = readtable(corpus_fileName);
corpus_words = corpus_data_table{:,1}';
num_corpus_words = size(corpus_words,2);

% Create randomized list of either WM or AM task blocks (0-AM, 1-WM):
Exp_blocks = [zeros(1,nBlocks),ones(1,nBlocks)];
Exp_blocks = Exp_blocks(randperm(length(Exp_blocks)));

%% Resting State Acquisition:
if resting_state
    Resting_task_instruction = 'Please sit back, relax, close your eyes and \n \n do not think of anything in particular \n';
    DrawFormattedText(wPtr, Resting_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(resting_time); Screen('Flip', wPtr);
    
    % Get EEG data (& online processing): 
    if ~test_run
        [resting_buffer_INDEX,resting_EEG_MARKERS,resting_EEG,prevSample] = get_EEG_data(cfg,blocksize_resting_time,1,chanindx,[],[],[]);
                
        %pseudocode
        
        
        
        save(strcat('resting_EEG_',subject_name),'cfg','resting_EEG','resting_EEG_MARKERS','resting_buffer_INDEX');        
    end    
end

%% Experiment Loop:
EEG = cell(1,length(Exp_blocks));
class_MARKERS = cell(1,length(Exp_blocks));
class_MARKERS_idx = cell(1,length(Exp_blocks));
EEG_MARKERS = cell(1,length(Exp_blocks));
buffer_INDEX = cell(1,length(Exp_blocks));
question_RESP = cell(1,length(Exp_blocks));
prevSample = 1;

for block = 1:length(Exp_blocks)
    EVENT = [];
    DATA = [];
    class_MARK = [];
    class_MARK_idx = [];
    INDEX = [];
    
    tic;
    if ~Exp_blocks(block)   % It is an AM trial (Class 2)
        
        switch iti_stim
            case 'word'
                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2));
                
                DrawFormattedText(wPtr,'Autobiographical Memory', 'center', 'center', white);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2)); Screen('Flip', wPtr); class = 1; % interblock time (Class 1)
                
            case 'symbol'                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(interBlock_time); Screen('Flip', wPtr); class = 1; % interblock time (Class 1)                
        end
        
        % Populate the class_MARK vector for interblock segment:
        if ~test_run [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_interBlock_time,prevSample,class, block, class_MARK, class_MARK_idx); end
        
        class = 2;
        Run_AM
        
    else     % It is a WM trial (Class 3)
        
        switch iti_stim
            case 'word'
                
                % Draw white fixation cross
                Screen('drawLine', wPtr, [0,0,0], x0-fixSize, y0, x0+fixSize, y0, fixThick);
                Screen('drawLine', wPtr, [0,0,0], x0, y0-fixSize, x0, y0+fixSize, fixThick);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2));
                
                DrawFormattedText(wPtr, 'Word Memory', 'center', 'center', white);
                Screen('Flip', wPtr);
                WaitSecs(floor(interBlock_time/2)); Screen('Flip', wPtr); class = 1; % interblock time (Class 1)
                
            case 'symbol'                
                % Draw white circle
                Screen('FillOval', wPtr,[0,0,0]);
                Screen('Flip', wPtr);
                WaitSecs(interBlock_time); Screen('Flip', wPtr); class = 1; % interblock time (Class 1)
        end
        
        % Populate the class_MARK vector for interblock segment:
        if ~test_run [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_interBlock_time,prevSample,class, block, class_MARK, class_MARK_idx); end
        
        class = 3;
        Run_WM
    end
    
    % Collect EEG from the duration of this block:
    block_runtime = toc;
    blocksize = round(block_runtime*hdr.Fs);
    if ~test_run [buffer_INDEX{block},EEG_MARKERS{block},EEG{block},prevSample] = get_EEG_data(cfg,blocksize,prevSample,chanindx,INDEX,EVENT,DATA); end
    question_RESP{block} = question_responses;
    class_MARKERS{block} = class_MARK;
    class_MARKERS_idx{block} = class_MARK_idx;
    
    % Save intermittent data in case of crash:
    if ~test_run
        files = dir(strcat('composite_task_',subject_name,'_block_',num2str(block),'*.mat'));
        save([strcat('composite_task_',subject_name,'_block_',num2str(block)),num2str(length(files)+1)],'cfg','EEG','class_MARKERS','class_MARKERS_idx','EEG_MARKERS','buffer_INDEX','question_RESP','Exp_blocks','block')
    end
    
end
sca;

% Save the entire dataset:
if ~test_run
    save(strcat('composite_task_',subject_name,'_full_dataset'),'cfg','EEG','class_MARKERS','class_MARKERS_idx','EEG_MARKERS','buffer_INDEX','question_RESP','Exp_blocks','block')
    save(['End_Workspace_' subject_name])
end

% Save the entire dataset:
% save(strcat('pretrain_',subject_name),'EEG','class_MARKERS','EEG_MARKERS','start_INDEX','scan');
% files = dir('testsaurabh*.mat');
% save(['testsaurabh',num2str(length(files)+1)])

