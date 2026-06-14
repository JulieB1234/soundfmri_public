function timing_files_mw(sub_nb, options)

global options;

% this function runs separately for each subject

%% SET UP DIRECTORIES AND OUTPUT FILES

Output_directory = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/MW/Timingfiles');

% Load subject's behavioral data
% Active sessions (block < 10)
%filenameTF_active = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/Subject_%d_*.mat', str2double(sub_nb));
%files_active = dir(filenameTF_active); % Get a list of all matching files
% Passive sessions (block > 9)
filenameTF_passive = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/Subject_%d_*.mat', str2double(sub_nb));
files_passive = dir(filenameTF_passive); % Get a list of all matching files
% Define the 2 different types of "trials"
% if ~isempty(files_active)
%     active_data = load(fullfile(files_active(1).folder, files_active(1).name)) ; trials_active = active_data.trials;
% else
%     % Display a message in case no matching file is found
%     disp(['No matching active file found for Subject ' sub_nb]);
% end
if ~isempty(files_passive)
    passive_data = load(fullfile(files_passive(1).folder, files_passive(1).name)) ; trials_passive = passive_data.trials;
else
    % Display a message in case no matching file is found
    disp(['No matching passive file found for Subject ' sub_nb]);
end

%% SET UP PARAMETERS

% Define main parameters after loading the trials of interest
% blocks_nb = length(unique(trials.block));
% trials_nb = max(trials.trial);
% trials_per_block = max(trials.trial_in_block);
% trial = (1:trials_nb)';
%blocks_nb_active = length(unique(trials_active.block));
blocks_nb_passive = length(unique(trials_passive.block));
%trials_nb_active = max(trials_active.trial);
trials_nb_passive = max(trials_passive.trial);
%trials_per_block_active = max(trials_active.trial_in_block);
trials_per_block_passive = max(trials_passive.trial_in_block);

% Sanity check -- make sure run numbers match between scans,and behavioral files
run_nb = length(options.Sessions_names.(['subj' sub_nb]));
run_nb_active = 0;
run_nb_passive = 0;

for irun = 1:run_nb
    if contains(options.Sessions_names.(['subj' sub_nb]){irun},'A')
        %run_nb_active = run_nb_active + 1;
    elseif contains(options.Sessions_names.(['subj' sub_nb]){irun},'P')
         run_nb_passive = run_nb_passive + 1;
    end
end

% if length(run_nb_active) == length(blocks_nb_active)
%     fprintf('\n subj %d active : block nbs match! \n', str2double(sub_nb));
% else
%     fprinpt('\n subj %d active : block nbs dont match: behav = %d ; scans = %d \n', str2double(sub_nb), length(blocks_nb_active), length(run_nb_active));
% end
if length(run_nb_passive) == length(blocks_nb_passive)
    fprintf('\n subj %d passive : block nbs match! \n', str2double(sub_nb));
else
    fprinpt('\n subj %d passive : block nbs dont match: behav = %d ; scans = %d \n', str2double(sub_nb), length(blocks_nb_passive), length(run_nb_passive));
end

%% Loop across blocks to get trials data

for iblock = 1:blocks_nb_passive %blocks_nb_active
    blocknum = iblock-1;
    % Define onsets, durations, names, +/- pmod if needed (depending on the option)
    if ismember(options.GLMtype,'Classic')
        % Define names and corresponding indices
        j=1; names = cell(0);
        %names{j} = 'stim_vowel1';           idx_stim1 = j;     j=j+1; %vowel A
        %names{j} = 'stim_vowel2';           idx_stim2 = j;     j=j+1; %vowel E
        names{j} = 'mw_answer_sound_vowel1';idx_mwsound1 = j;  j=j+1;
        names{j} = 'mw_answer_other_vowel1';idx_mwother1 = j;  j=j+1;
        names{j} = 'mw_answer_sound_vowel2';idx_mwsound2 = j;  j=j+1;
        names{j} = 'mw_answer_other_vowel2';idx_mwother2 = j;  j=j+1;
        names{j} = 'rt_question_vowel1';    idx_rt1 = j;       j=j+1;
        names{j} = 'mw_question_vowel1';    idx_mw1 = j;       j=j+1;
        names{j} = 'quiz_question_vowel1';  idx_quiz1 = j;     j=j+1;
        names{j} = 'none_question_vowel1';  idx_none1 = j;     j=j+1;
        names{j} = 'rt_question_vowel2';    idx_rt2 = j;       j=j+1;
        names{j} = 'mw_question_vowel2';    idx_mw2 = j;       j=j+1;
        names{j} = 'quiz_question_vowel2';  idx_quiz2 = j;     j=j+1;
        names{j} = 'none_question_vowel2';  idx_none2 = j;     j=j+1;
        names{j} = 'FixPoint';              idx_fixpoint = j;  j=j+1;
        names{j} = 'Keypress';              idx_kp = j;        % last one
        names = names';
        onsets = cell(j,1); durations = cell(j,1);
        %if ismember(options.PModVer,'V2') % [-2.2 -1.2 -0.2 0.8 2.8] for both vowels
        % Define onsets, durations and pmods
        i = 1 + blocknum * trials_per_block_passive ;
        while i < ((trials_per_block_passive + 1)+blocknum*trials_per_block_passive)
            if trials_passive.stimulus_num(i) == 1 %vowel A
                % Keypress, question type, answer if mindwandering -- as a function of question type
                if trials_passive.question_num(i) == 1 % quiz
                    % response screen & question type
                    onsets{idx_quiz1} = [onsets{idx_quiz1} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_quiz1} = [durations{idx_quiz1} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i))
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                    end
                elseif trials_passive.question_num(i) == 2 % RT
                    % response screen & question type
                    onsets{idx_rt1} = [onsets{idx_rt1} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_rt1} = [durations{idx_rt1} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i))
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                    end
                elseif trials_passive.question_num(i) == 3 % mindwandering
                    % response screen & question type
                    onsets{idx_mw1} = [onsets{idx_mw1} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_mw1} = [durations{idx_mw1} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i))
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                        % answer to MW probe
                        %if ~isnan(trials_passive.answer_num(i))
                        if trials_passive.answer_num(i) == 1 % answer is the sound
                            onsets{idx_mwsound1} = [onsets{idx_mwsound1} trials_passive.onset_stim(i)];
                            durations{idx_mwsound1} = [durations{idx_mwsound1} str2double(options.stim_duration)];
                        elseif trials_passive.answer_num(i) ~= 1
                            onsets{idx_mwother1} = [onsets{idx_mwother1} trials_passive.onset_stim(i)];
                            durations{idx_mwother1} = [durations{idx_mwother1} str2double(options.stim_duration)];
                        end
                        %end
                    end
                elseif trials_passive.question_num(i) == 4 %none /!\ use rt2 and time_pause
                    % response screen & question type
                    onsets{idx_none1} = [onsets{idx_none1} trials_passive.time_pause(i) - trials_passive.scan_start(i)];
                    durations{idx_none1} = [durations{idx_none1} 0];
                end
            elseif trials_passive.stimulus_num(i) == 2 % vowel E
                % Keypress, question type, answer if mindwandering -- as a function of question type
                if trials_passive.question_num(i) == 1 % quiz
                    % response screen & question type
                    onsets{idx_quiz2} = [onsets{idx_quiz2} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_quiz2} = [durations{idx_quiz2} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i)) 
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                    end
                elseif trials_passive.question_num(i) == 2 % RT
                    % response screen & question type
                    onsets{idx_rt2} = [onsets{idx_rt2} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_rt2} = [durations{idx_rt2} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i)) 
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                    end
                elseif trials_passive.question_num(i) == 3 % mindwandering
                    % response screen & question type
                    onsets{idx_mw2} = [onsets{idx_mw2} trials_passive.time_quest(i) - trials_passive.scan_start(i)];
                    durations{idx_mw2} = [durations{idx_mw2} 0];
                    % keypress
                    if ~isnan(trials_passive.answer_num(i)) %~isnan(trials_passive.rt1(i))
                        onsets{idx_kp} = [onsets{idx_kp} trials_passive.time_quest(i) - trials_passive.scan_start(i) + trials_passive.rt1(i)];
                        durations{idx_kp} = [durations{idx_kp} 0];
                    end
                    % answer to MW probe
                    if ~isnan(trials_passive.answer_num(i)) 
                        if trials_passive.answer_num(i) == 1
                            onsets{idx_mwsound2} = [onsets{idx_mwsound2} trials_passive.onset_stim(i)];
                            durations{idx_mwsound2} = [durations{idx_mwsound2} str2double(options.stim_duration)];
                        elseif trials_passive.answer_num(i) ~= 1
                            onsets{idx_mwother2} = [onsets{idx_mwother2} trials_passive.onset_stim(i)];
                            durations{idx_mwother2} = [durations{idx_mwother2} str2double(options.stim_duration)];
                        end
                    end
                elseif trials_passive.question_num(i) == 4 %none /!\ use rt2 and time_pause
                    % response screen & question type
                    onsets{idx_none2} = [onsets{idx_none2} trials_passive.time_pause(i) - trials_passive.scan_start(i)];
                    durations{idx_none2} = [durations{idx_none2} 0];
                end
            end
            % Fixation point
            onsets{idx_fixpoint} = [onsets{idx_fixpoint} trials_passive.onset_start(i)];
            durations{idx_fixpoint} = [durations{idx_fixpoint} 0];
            i = i+1;
        end
        % if some arrays are empty, fill them artificially and notify
        % it for later
        for ionset = 1:length(onsets)
            if ~isempty(onsets{ionset})
                options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock}(ionset) = 0;
            elseif isempty(onsets{ionset})
                onsets{ionset} = 1000;
                durations{ionset} = 0;
                options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock}(ionset) = ionset ; %[options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))) 1];
                fprintf('\n Subject %d - Run %d passive : regressor %s was empty and artificially filled \n ', str2double(sub_nb), blocknum, names{ionset});
            end
        end
    end
    % Save file for each run separately
    filename_base_passive = fullfile(Output_directory, sprintf('mw_timing_file_passive_subject%i_run%i', str2double(sub_nb), blocknum));
    if ismember(options.GLMtype,'Classic')
        filename_matTF = [filename_base_passive '_classic_' '.mat'];
        save(filename_matTF,"names","onsets","durations");
    elseif ismember(options.GLMtype,'Pmod')
        if ismember(options.PModVer,'V1')
            filename_matTF = [filename_base_passive '_pmod_V1_' '.mat'];
        elseif ismember(options.PModVer,'V2')
            filename_matTF = [filename_base_passive '_pmod_V2_' '.mat'];
        end
        save(filename_matTF,"names","onsets","durations","pmod");
    end
end
