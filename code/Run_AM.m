% Picking keywords from the same memory for this block:
num_unique_memories = max(AM_memory_number); rand_vect = randperm(num_unique_memories);
current_mem = rand_vect(1); % Pick a memory for this block
AM_words_idx = AM_memory_number == current_mem;
AM_words_selected = AM_words(AM_words_idx);

% Prepare trials for the current block:
% AM_memory_number_list = AM_memory_number;
if length(AM_words_selected) < (nTrials + num_questions) && ~repeat_AM_words
    % Need to add code to record the frequency of the words
    rand_corpus_words = corpus_words(randperm(num_corpus_words));
    AM_trial_word_list_total = [AM_words_selected rand_corpus_words(1:(nTrials-length(AM_words_selected)+num_questions))];
    % AM_memory_number_list = [AM_memory_number_list repmat(999,[1,length(rand_corpus_words(1:(nTrials-length(AM_words_selected)+num_questions)))])];

elseif length(AM_words_selected) < (nTrials + num_questions) && repeat_AM_words
    rand_AM_words = repmat(AM_words_selected,[1,ceil((nTrials-length(AM_words_selected)+num_questions)/length(AM_words_selected))]);
    rand_AM_words = rand_AM_words(randperm(length(rand_AM_words)));
    
    AM_trial_word_list_total = [AM_words_selected rand_AM_words(1:(nTrials-length(AM_words_selected)+num_questions))];
    
else
    AM_trial_word_list_total = [AM_words_selected]; 
end
AM_trial_word_list_total = AM_trial_word_list_total(randperm(nTrials + num_questions));
AM_trial_word_list = AM_trial_word_list_total(1:nTrials);
% AM_memory_number_list = AM_memory_number_list(rand_order);

question_trials = randi(nTrials,[1,num_questions]);
question_responses = zeros(1,num_questions);
num_questions_asked = 0;

%% Display Instructions for AM task:
if test_run
    AM_task_instruction = 'You will be shown a series of words on the screen.\n\n Some of these words are those that elicit the memories you described, \n\n Upon seeing a word that elicits a memory, \n\n imagine the memory in as much detail as possible. \n';
    DrawFormattedText(wPtr, AM_task_instruction, 'center', 'center', white);
    Screen('Flip', wPtr);
    WaitSecs(instructions_time); Screen('Flip', wPtr);
end

% Display the AM words:
for tr = 1:nTrials
    
    curr_trial_word = AM_trial_word_list{1,tr};
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
        question_options = [rand_corpus_words(1:num_question_options-1) AM_trial_word_list_total(nTrials+num_questions_asked)];
        curr_perm = randperm(num_question_options);
        question_options = question_options(curr_perm); % Tracking correct option
        question_text = ['Which of the following words also describes the memory you are recalling: \n\n' ];
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