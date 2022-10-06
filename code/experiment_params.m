%%% experiment parameters %%%
% Timing Settings:
Trial_duration = 2;          % Inter-trial interval (time between end and start of trials)
prefix_time = 2;             % How long the fixation appears before the cue
interBlock_time = 5;         % Time between two blocks (duration of time saliency information is shown)
instructions_time = 5;       % Duration for which the instructions show up before the onset of a task

% Experimental settings:
nBlocks = 1 ;                % Number of Blocks
nTrials = 10;                % Number of trials
nClass = 3;                  % Number of task classes

% WM n-back Settings:
nBack_num = 1; % Recollection task - or 2 back task
num_questions = 5;
num_question_options = 4;
repeat_AM_words = true;
repeat_CR_words = true;

% Inter-trial stimulus type:
iti_stim = 'word';