%%%%% Working Memory Trials: n-back task %%%%%
%%%---File history:
%%% original: Saurabh Shaw, 2020
%%% current: Selena Singh, 2022
%%%
%%%---changes made (Singh) 
%%% - unified 'Run_WM with 'Run_WM_triggers', save EEG triggers for trials 
%%%%%%%------------------------------

% Prepare trials for the current block:
rand_corpus_words = corpus_words(randperm(num_corpus_words));
WM_trial_word_list = rand_corpus_words(1:nTrials);

% Display Instructions for WM task:
if test_run
    WM_task_instruction = ['You will be shown a series of words on the screen. \n\n Try to remember the word you saw ' num2str(nBack_num) ' words ago'];
    DrawFormattedText(wPtr, WM_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(instructions_time); Screen('Flip', wPtr);
end

question_trials = randi(nTrials,[1,num_questions]);
question_responses = zeros(1,num_questions);
question_responses_raw = zeros(1,num_questions);
question_responses_rawtimes = cell(1,num_questions);
num_questions_asked = 0;

% Display the AM words:
for tr = 1:nTrials
    
    curr_trial_word = WM_trial_word_list{1,tr};
    DrawFormattedText(wPtr, curr_trial_word, 'center', 'center', white);
    screenflipText{block}= [screenflipText{block} {curr_trial_word}];
    [~,screenFlip_timestamp(tr)] = Screen('Flip', wPtr); 
    screenflipTimes{block} = [screenflipTimes{block} screenFlip_timestamp(tr)];
    [~, ampTrigger_timestamp(tr)] = IOPort('Write', portHandle, uint8(class+tr*10)); 
    triggers{block} = [triggers{block} uint8(class+tr*10)];
    WaitSecs(Trial_duration);
    Screen('Flip', wPtr);
    
    % Populate the class_MARK vector:
    if ~test_run 
        [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_Trial_duration,prevSample,class, tr, class_MARK, class_MARK_idx); 
    end
    
    % Ask the n-back question:
    if ismember(tr,question_trials) && (tr > nBack_num)
        
        num_questions_asked = num_questions_asked + 1;
        
        rand_corpus_words = corpus_words(randperm(num_corpus_words));
        question_options = [rand_corpus_words(1:num_question_options-1) WM_trial_word_list(tr - nBack_num)];
        question_options = question_options(randperm(num_question_options)); % Need to track correct option
        question_text = ['Which word did you see ' num2str(nBack_num) ' words ago \n\n' ];
        for j = 1:num_question_options
            question_text = [question_text num2str(j) '. ' question_options{j} '\n\n'];                        
        end
        
        % Get Character input:
        FlushEvents('GetChar');
        DrawFormattedText(wPtr, question_text, 'center', 'center', white); 
        screenflipText{block}= [screenflipText{block} {question_text}];
        [~,screenFlip_time_temp] = Screen('Flip', wPtr); 
        screenflipTimes{block} = [screenflipTimes{block} screenFlip_time_temp];
        [~, ampTrigger_timestamp(tr)] = IOPort('Write', portHandle, uint8(num_questions_asked*10+9)); 
        triggers{block} = [triggers{block} uint8(num_questions_asked*10+9)];
        [ch,when] = GetChar();
        [~, ampTrigger_timestamp(tr)] = IOPort('Write', portHandle, uint8(str2num(ch))); 
        triggers{block} = [triggers{block} uint8(str2num(ch))];
        KbWait;
        Screen('Flip', wPtr);
        
        % Check if response is correct:
        if strcmp(question_options(str2num(ch)),WM_trial_word_list(tr - nBack_num))
            question_responses(num_questions_asked) = 1;
        end    

        % Save raw responses and timing:
        question_responses_raw(num_questions_asked) = str2num(ch); 
        question_responses_rawtimes{num_questions_asked} = when;
        
    end
        
    fprintf(1,'%i trials completed out of %i trials \n', tr, nTrials);

end