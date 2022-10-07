%%%%% Cued Rumination Trials %%%%%
%%%---File history:
%%% original: Selena Singh, 2022
%%% very similar to Run_AM.m

%%%%%%%------------------------------
% TODO : Clean up, add comments/doc strings, improve readability
% Picking keywords from the same memory for this block:
num_unique_memories = max(CR_memory_number); 
rand_vect = randperm(num_unique_memories);
current_mem = rand_vect(1); % Pick a memory for this block
CR_words_idx = CR_memory_number == current_mem;
CR_words_selected = CR_words(CR_words_idx);

% Prepare trials for the current block:
if length(CR_words_selected) < (nTrials + num_questions) && ~repeat_CR_words
    rand_corpus_words = corpus_words(randperm(num_corpus_words));
    CR_trial_word_list_total = [CR_words_selected rand_corpus_words(1:(nTrials-length(CR_words_selected)+num_questions))];

elseif length(CR_words_selected) < (nTrials + num_questions) && repeat_CR_words
    rand_CR_words = repmat(CR_words_selected,[1,ceil((nTrials-length(CR_words_selected)+num_questions)/length(CR_words_selected))]);
    rand_CR_words = rand_CR_words(randperm(length(rand_CR_words)));
    
    CR_trial_word_list_total = [CR_words_selected rand_CR_words(1:(nTrials-length(CR_words_selected)+num_questions))];
    
else
    CR_trial_word_list_total = [CR_words_selected]; 
end
CR_trial_word_list_total = CR_trial_word_list_total(randperm(nTrials + num_questions));
CR_trial_word_list = CR_trial_word_list_total(1:nTrials);

question_trials = randi(nTrials,[1,num_questions]);
question_responses = zeros(1,num_questions);
num_questions_asked = 0;

%% Display Instructions for AM task:
if test_run
    CR_task_instruction = 'You will be shown a series of words on the screen.\n\n Some of these words describe your ruminations. \n\n Upon seeing a word that reminds you of your ruminations, \n\n engage in ruminating about that material. \n';
    DrawFormattedText(wPtr, CR_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(instructions_time); Screen('Flip', wPtr);
end

% Display the cued rumination words:
for tr = 1:nTrials
    
    curr_trial_word = CR_trial_word_list{1,tr};
    DrawFormattedText(wPtr, curr_trial_word, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(Trial_duration);
    Screen('Flip', wPtr);
    
     % Populate the class_MARK vector:
    if ~test_run [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize_Trial_duration,prevSample,class, tr, class_MARK, class_MARK_idx); end
        
    % Ask memory question:
    if ismember(tr,question_trials)
        
        num_questions_asked = num_questions_asked + 1;
        
        rand_corpus_words = corpus_words(randperm(num_corpus_words));
        question_options = [rand_corpus_words(1:num_question_options-1) CR_trial_word_list_total(nTrials+num_questions_asked)];
        curr_perm = randperm(num_question_options);
        question_options = question_options(curr_perm); % Tracking correct option
        question_text = ['Which of the following words also fits with the rumination: \n\n' ];
        for j = 1:num_question_options
            question_text = [question_text num2str(j) '. ' question_options{j} '\n\n'];                        
        end
        
        % Get Character input:
        FlushEvents('GetChar');
        DrawFormattedText(wPtr, question_text, 'center', 'center', white);
        Screen('Flip', wPtr);
        [ch] = GetChar();
        KbWait;
        Screen('Flip', wPtr);
        
        % Check if response is correct:
        if find(curr_perm == 4) == str2num(ch)
            question_responses(num_questions_asked) = 1;
        end            
        
    end
       
    fprintf(1,'%i trials completed out of %i trials \n', tr, nTrials);

end