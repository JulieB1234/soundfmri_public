function timing_files_audibPerSNR(sub_nb, options)

global options;

% this function runs separately for each subject

%% Update 2023 :
% PMOD for stim intensity, so instead of the timing files that had one regressor per stim type (n =
% 10, 5 stim levels x 2 vowels) we now have only 2 stim regressors : A and
% E, and each one has its parametric modulator
% what we keep is 'PMOD2', with mean centered regressors (manual mean centering
% from (0 1 2 3 5) to (-2.2 -1.2 -0.2 0.8 2.8) so that there is collinearity between
% regressors

%% Update March 2024 :
% 1/ instead of separate funcitons for active / passive conditions, we make a
% common one ; as for the main pipeline we consider for each subject:
% - 1st 9 blocks (0 to 8) are active
% - last 11 blocks (0 to 10) are passive
% 2/ we add new regressors:
% - audibility ratings in the active condition
% - correct or incorrect identification in the active condition
% - quesiton type in the passive condition
% - mindwandering answer in the passive condition

%% Update April 2024 :
% SPM returns an error in case of empty vectors for onsets and durations
% arrays in the timing files, which happens in case a given regressor
% doesn't happen in a given run (eg if a participant never picks a given
% answer in some run)
% I there for add, for all regressors except vowels and question types
% (which we know are always equally distributed in each run), a condition
% when an array is empty and we replace its onset by '1000' and duration by
% '0', so that the onset exceeds the duraiton of scanning for this run and
% it isn't taken into account. I just need to make sure there is no impact
% on following runs!! it seems okay on the example matrix of several runs i
% made manually with SPM GUI.
% + i need to add a line that displays the information, eg 'subj X run X
% have no onset for regressor X and was replaced'

% ==> it works \o/ ; done for passive regressors 'mindwandering probe
% answer = 'the sound' ; add it now for 'audibility 4' in the active
% condition !!

%% NB : for now I put the same onsets for both intensity and audibility regressors, ie stim onset, because I consider
% both stim intensity and audibility reports are related to brain activity
% when hearing the sound; I think it means we can either chose to study one
% or the other with the contrast; we will see if spm accepts having several
% regressors with the same onsets in the GLM
% Same goes for 'correct' / 'incorrect' ; and for passive blocks (for MW
% answers)
% Also, in passive blocks, I replace 'response screen' by 'question type'
% with the same onset as response screen

%% May 2024 update : doesnt work because SPM considers the model invalid if there are several regressors for a given event
% This is an attempt to simplify by stuyding a matrix with just audibility
% ratings
% But then we really want to have a matrix with one regressor per
% condition, conditions being now a mix of stim intensity and audibility
% ie a total of 40 regressors (5 stim intensities x 4 audibility ratings x 2
% vowels)
% NB: we could even add the correct / incorrect regressors (so 40 x 2 = 80
% regressors...)
% Anyway, for now we exclude parts of the code regarding passive condition
% but leave it commented because i still havent given up on a big global
% matrix <3

%% Update January 2025 (!)
% the last version works for the contrast heard vs not heard, taking into
% account potential missing audibility ratings so that's good.
% now i want to look at heard vs not heard for specific stim intensity,
% namely for snrs 3 and 4 (i plan to make an analysis for all snr 3 and all
% snr 4 and then to individualize threshold snr based on each subject's
% behavioral results and also i might even try to differentiate it as a
% function of the A / E vowel) => for all that i need new timing files
% with regressors that take into account both the audibility and the snr,
% added to the vowel (already done though)
% so now it won't be 13 regressors like this:
% - reg 1 = vowAaudib1
% - ...
% - reg 4 = vowAaudib4
% - ...
% - reg 8 = vowEaudib4
% - reg 9 = fixpoint
% - reg 10 = respScreen 1
% - reg 11 = keypress 1
% - reg 12 = respScreen 2
% - reg 13 = keypress 2
% BUT : 2 vowels (A/E) x 5 snr levels (1/2/3/4/5) x 4 audibility ratings
% (1/2/3/4) = 40 regressors [+ the 5 last ones that don't change] => total
% = 45
% - reg 1 = vowAaudib1snr1
% - reg 2 = vowAaudib1snr2
% - ...
% - reg 5 = vowAaudib1snr5
% - reg 6 = vowAaudib2snr1
% - ...
% - reg 10 = vowAaudib2snr5
% - ...
% - reg 20 = vowAaudib4snr5
% - reg 21 = vowEaudib1snr1
% - ...
% - reg 40 = vowEaudib4snr5
% - reg 41 = FixPoint
% - reg 42 = respScreen 1
% - reg 43 = keypress 1
% - reg 44 = respScreen 2
% - reg 45 = keypress 2
% NB : i get rid of the old parts commented for passive condition and all
% NB2 : no pmod for now (january 2025) i took off these commented parts and
% also the ones for correct / incorrect -- they're still in the original
% "timing files for audib" function

%%
% for debug -> 8/01/25 : there's a problem for now because for ex in subj
% 10A run 0 it doesn't record the 3 first trials (vowAaudib2snr5 onset 5.83
% then vowEaudib1snr4 onset 17.04 then vowAaudib1snr1 onset 26.64) but it
% does take the 4th one : vowEaudib1snr3 -> onset 36.2014 out into
% regressor number 23 which is correct i think



%% SET UP DIRECTORIES AND OUTPUT FILES

Output_directory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/TimingFiles';
% Load subject's behavioral data
filenameTF_active = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/Subject_%d_*.mat', str2double(sub_nb));
files_active = dir(filenameTF_active); % Get a list of all matching files
if ~isempty(files_active)
    active_data = load(fullfile(files_active(1).folder, files_active(1).name)) ; trials_active = active_data.trials;
else
    % Display a message in case no matching file is found
    disp(['No matching active file found for Subject ' sub_nb]);
end

%% SET UP PARAMETERS

% Define main parameters after loading the trials of interest
blocks_nb_active = length(unique(trials_active.block));
%trials_nb_active = max(trials_active.trial); % not used ? try commenting it 08/01/25
trials_per_block_active = max(trials_active.trial_in_block);
% Sanity check -- make sure run numbers match between scans,and behavioral files
run_nb = length(options.Sessions_names.(['subj' sub_nb]));
run_nb_active = 0;
for irun = 1:run_nb
    if contains(options.Sessions_names.(['subj' sub_nb]){irun},'A')
        run_nb_active = run_nb_active + 1;
    end
end
if length(run_nb_active) == length(blocks_nb_active)
    fprintf('\n subj %d active : block nbs match! \n', str2double(sub_nb));
else
    fprinpt('\n subj %d active : block nbs dont match: behav = %d ; scans = %d \n', str2double(sub_nb), length(blocks_nb_active), length(run_nb_active));
end

%% Loop across blocks to get trials data
for iblock = 1:blocks_nb_active
    blocknum = iblock-1;
    % Define onsets, durations, names, +/- pmod if needed (depending on the option)
    if ismember(options.GLMtype,'Classic')
        % Define names and corresponding indices (in case we add or delete regressors!)
        j=1; names = cell(0);
        % Add audibility ratings
        for ivowel = 1:2
            for iaudib = 1:4
                for isnr = 1:5
                    names{j} = sprintf('vowel%d_audib%d_snr%d',ivowel,iaudib,isnr);
                    j = j+1;
                end
            end
        end
        % names = 1x40 dim
        names{j} = 'FixPoint';        j=j+1;
        names{j} = 'RespScreen1';     j=j+1;
        names{j} = 'Keypress1';       j=j+1;
        names{j} = 'RespScreen2';     j=j+1;
        names{j} = 'Keypress2';       % last one
        names = names'; % dim = 45x1 now

        % Define empty cells for onsets and durations
        onsets = cell(j,1); durations = cell(j,1);
        % Define onsets & durations
        i = 1 + blocknum * trials_per_block_active ;
        while i < ((trials_per_block_active + 1)+ blocknum * trials_per_block_active) % going from trial 1 to 50 in each block
            % Vowel A
            if trials_active.stimulus_num(i) == 1
                if ~isnan(trials_active.audib(i)) % if audibility was rated in this trial
                    % Audibility 1
                    if trials_active.audib(i) == 1
                        % SNR 1 -> index 1
                        if trials_active.snr_num(i) == 1
                            index = 1;
                            % SNR 2 -> index 2
                        elseif trials_active.snr_num(i) == 2
                            index = 2;
                            % SNR 3 -> index 3
                        elseif trials_active.snr_num(i) == 3
                            index = 3;
                            % SNR 4 -> index 4
                        elseif trials_active.snr_num(i) == 4
                            index = 4;
                            % SNR 5 -> index 5
                        elseif trials_active.snr_num(i) == 5
                            index = 5;
                        end
                        % Audibility 2
                    elseif trials_active.audib(i) == 2
                        if trials_active.snr_num(i) == 1
                            index = 6;
                        elseif trials_active.snr_num(i) == 2
                            index = 7;
                        elseif trials_active.snr_num(i) == 3
                            index = 8;
                        elseif trials_active.snr_num(i) == 4
                            index = 9;
                        elseif trials_active.snr_num(i) == 5
                            index = 10;
                        end
                        % Audibility 3
                    elseif trials_active.audib(i) == 3
                        if trials_active.snr_num(i) == 1
                            index = 11;
                        elseif trials_active.snr_num(i) == 2
                            index = 12;
                        elseif trials_active.snr_num(i) == 3
                            index = 13;
                        elseif trials_active.snr_num(i) == 4
                            index = 14;
                        elseif trials_active.snr_num(i) == 5
                            index = 15;
                        end
                        % Audibility 4
                    elseif trials_active.audib(i) == 4
                        if trials_active.snr_num(i) == 1
                            index = 16;
                        elseif trials_active.snr_num(i) == 2
                            index = 17;
                        elseif trials_active.snr_num(i) == 3
                            index = 18;
                        elseif trials_active.snr_num(i) == 4
                            index = 19;
                        elseif trials_active.snr_num(i) == 5
                            index = 20;
                        end
                    end
                    % Add onset and duration for Vowel A
                    if exist('index', 'var')
                        onsets{index} = [onsets{index} trials_active.onset_stim(i)];
                        durations{index} = [durations{index} str2double(options.stim_duration)];
                    end
                end
                % Vowel E
            elseif trials_active.stimulus_num(i) == 2
                if ~isnan(trials_active.audib(i)) % if audibility was rated in this trial
                    % Audibility 1
                    if trials_active.audib(i) == 1
                        if trials_active.snr_num(i) == 1
                            index = 21;
                        elseif trials_active.snr_num(i) == 2
                            index = 22;
                        elseif trials_active.snr_num(i) == 3
                            index = 23;
                        elseif trials_active.snr_num(i) == 4
                            index = 24;
                        elseif trials_active.snr_num(i) == 5
                            index = 25;
                        end
                        % Audibility 2
                    elseif trials_active.audib(i) == 2
                        if trials_active.snr_num(i) == 1
                            index = 26;
                        elseif trials_active.snr_num(i) == 2
                            index = 27;
                        elseif trials_active.snr_num(i) == 3
                            index = 28;
                        elseif trials_active.snr_num(i) == 4
                            index = 29;
                        elseif trials_active.snr_num(i) == 5
                            index = 30;
                        end
                        % Audibility 3
                    elseif trials_active.audib(i) == 3
                        if trials_active.snr_num(i) == 1
                            index = 31;
                        elseif trials_active.snr_num(i) == 2
                            index = 32;
                        elseif trials_active.snr_num(i) == 3
                            index = 33;
                        elseif trials_active.snr_num(i) == 4
                            index = 34;
                        elseif trials_active.snr_num(i) == 5
                            index = 35;
                        end
                        % Audibility 4
                    elseif trials_active.audib(i) == 4
                        if trials_active.snr_num(i) == 1
                            index = 36;
                        elseif trials_active.snr_num(i) == 2
                            index = 37;
                        elseif trials_active.snr_num(i) == 3
                            index = 38;
                        elseif trials_active.snr_num(i) == 4
                            index = 39;
                        elseif trials_active.snr_num(i) == 5
                            index = 40;
                        end
                    end

                    % Add onset and duration
                    if exist('index', 'var')
                        onsets{index} = [onsets{index} trials_active.onset_stim(i)];
                        durations{index} = [durations{index} str2double(options.stim_duration)];
                    end
                end
            end
            onsets{41} = [onsets{41} trials_active.onset_start(i)];
            durations{41} = [durations{41} 0];
            onsets{42} = [onsets{42} trials_active.time_quest1(i) - trials_active.scan_start(i)];
            durations{42} = [durations{42} 0];
            if ~isnan(trials_active.rt1(i))
                onsets{43} = [onsets{43} trials_active.time_quest1(i) - trials_active.scan_start(i) + trials_active.rt1(i)];
                durations{43} = [durations{43} 0];
            end
            onsets{44} = [onsets{44} trials_active.time_quest2(i) - trials_active.scan_start(i)];
            durations{44} = [durations{44} 0];
            if ~isnan(trials_active.rt2(i))
                onsets{45} = [onsets{45} trials_active.time_quest2(i) - trials_active.scan_start(i) + trials_active.rt2(i)];
                durations{45} = [durations{45} 0];
            end
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
                fprintf('\n Subject %d - Run %d active : regressor %s was empty and artificially filled \n ', str2double(sub_nb), blocknum, names{ionset});
            end
        end
        %end
    end

    % Save file for each run separately
    filename_base_active = fullfile(Output_directory, sprintf('audibPerSNR_timing_file_active_subject%i_run%i', str2double(sub_nb), blocknum));
    %if ismember(options.GLMtype,'Classic')
        filename_matTF = [filename_base_active '_classic_' '.mat'];
        save(filename_matTF,"names","onsets","durations");
    %elseif ismember(options.GLMtype,'Pmod')
        % if ismember(options.PModVer,'V1')
        %     filename_matTF = [filename_base_active '_pmod_V1_' '.mat'];
        % elseif ismember(options.PModVer,'V2')
        %     filename_matTF = [filename_base_active '_pmod_V2_' '.mat'];
        % end
        % save(filename_matTF,"names","onsets","durations","pmod");
    %end
end
