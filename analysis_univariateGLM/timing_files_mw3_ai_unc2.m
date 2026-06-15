function options = timing_files_mw3_ai_unc2(sub_nb, options)
% 1:H, 2:H-int, 3:NH, 4:NH-int, 5:NP, 6:NP-int, 7:Fix, 8-11:Resp, 12:Key
%% new
% 1:H, 2:H-int, 3:NH, 4:NH-int, 5:NP, 6:NP-int, 7: noStim, 8:Fix, 9-12:Resp, 13:Key
% so 10 + 3 pmod
% onsets
% 1 stim heard
% 2 stim not heard
% 3 stm not probed
% 4 no stim
% 5 fix point
% 6 rs1
% 7 rs2
% 8 rs3
% 9 rs4
% 10 kp

Output_directory = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_MWnewER_3/unconscious2/timing_files';
filenameTF_passive = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/Subject_%d_*.mat', str2double(sub_nb));
files_passive = dir(filenameTF_passive);

if ~isempty(files_passive)
    load(fullfile(files_passive(1).folder, files_passive(1).name));
else
    error(['No matching file for Subject ' sub_nb]);
end

durz = str2double(options.stim_duration);
blocks_nb = length(unique(trials.block));
trials_per_block = max(trials.trial_in_block);

for iblock = 1:blocks_nb
    blocknum = iblock-1;
    names = {'stim_heard','stim_notheard','stim_notprobed','no_stim_probed','fixpoint',...
        'respscreen_quiz','respscreen_rt','respscreen_mw','respscreen_none','keypress'}';
    onsets = cell(10,1); durations = cell(10,1);
    pmod = struct('name',{}, 'param', {}, 'poly', {});
    for p = 1:3
        pmod(p).name{1} = [names{p} '_int'];
        pmod(p).param{1} = [];
        pmod(p).poly{1} = 1;
    end

    % FILL DATA
    i_start = 1 + blocknum * trials_per_block;
    i_end = i_start + trials_per_block - 1;
    for i = i_start:i_end
        if trials.snr_num(i) > 1
            if trials.question_num(i) == 3 && ~isnan(trials.answer_num(i)) % MW (ANSWERED) = regressor 1
                % what answer
                if trials.answer_num(i) == 1 % sound = HEARD #1
                    onsets{1} = [onsets{1} trials.onset_stim(i)];
                    durations{1} = [durations{1} durz];
                    % what intensity
                    % if trials.snr_num(i) == 1
                    %     pmod(1).param{1} = [pmod(1).param{1} -2.2];
                    if trials.snr_num(i) == 2
                        pmod(1).param{1} = [pmod(1).param{1} -1.2];
                    elseif trials.snr_num(i) == 3
                        pmod(1).param{1} = [pmod(1).param{1} -0.2];
                    elseif trials.snr_num(i) == 4
                        pmod(1).param{1} = [pmod(1).param{1} 0.8];
                    elseif trials.snr_num(i) == 5
                        pmod(1).param{1} = [pmod(1).param{1} 2.8];
                    end
                elseif trials.answer_num(i) > 1 % other answer = NOT HEARD #2
                    onsets{2} = [onsets{2} trials.onset_stim(i)];
                    durations{2} = [durations{2} durz];
                    % what intensity
                    % if trials.snr_num(i) == 1
                    %     pmod(2).param{1} = [pmod(2).param{1} -2.2];
                    if trials.snr_num(i) == 2
                        pmod(2).param{1} = [pmod(2).param{1} -1.2];
                    elseif trials.snr_num(i) == 3
                        pmod(2).param{1} = [pmod(2).param{1} -0.2];
                    elseif trials.snr_num(i) == 4
                        pmod(2).param{1} = [pmod(2).param{1} 0.8];
                    elseif trials.snr_num(i) == 5
                        pmod(2).param{1} = [pmod(2).param{1} 2.8];
                    end
                end
                % then add response screen regressor for mindwanering (#8)
                onsets{8} = [onsets{8} trials.time_quest(i) - trials.scan_start(i)];
                durations{8} = [durations{8} 0];

            else %if trials.question_num(i) ~= 3 % no MW = NOT PROBED #3
                onsets{3} = [onsets{3} trials.onset_stim(i)];
                durations{3} = [durations{3} durz];
                % what intensity
                % if trials.snr_num(i) == 1
                %     pmod(3).param{1} = [pmod(3).param{1} -2.2];
                if trials.snr_num(i) == 2
                    pmod(3).param{1} = [pmod(3).param{1} -1.2];
                elseif trials.snr_num(i) == 3
                    pmod(3).param{1} = [pmod(3).param{1} -0.2];
                elseif trials.snr_num(i) == 4
                    pmod(3).param{1} = [pmod(3).param{1} 0.8];
                elseif trials.snr_num(i) == 5
                    pmod(3).param{1} = [pmod(3).param{1} 2.8];
                end
                % add resp screen regressors (#6 7 and 9)
                if trials.question_num(i) == 1  % quiz
                    onsets{6} = [onsets{6} trials.time_quest(i) - trials.scan_start(i)];
                    durations{6} = [durations{6} 0];
                elseif trials.question_num(i) == 2 % RT
                    onsets{7} = [onsets{7} trials.time_quest(i) - trials.scan_start(i)];
                    durations{7} = [durations{7} 0];
                elseif trials.question_num(i) == 4 % none
                    onsets{9} = [onsets{9} trials.time_quest(i) - trials.scan_start(i)];
                    durations{9} = [durations{9} 0];
                end
            end
        elseif trials.snr_num(i) == 1 && trials.question_num(i) == 3 % 1/4th OF RIALS PROBED BUT NO STIM #4
            onsets{4} = [onsets{4} trials.onset_stim(i)];
            durations{4} = [durations{4} durz];
            % add resp screen regressors
            if trials.question_num(i) == 3 % mw
                onsets{8} = [onsets{8} trials.time_quest(i) - trials.scan_start(i)];
                durations{8} = [durations{8} 0];
            elseif trials.question_num(i) == 1  % quiz
                onsets{6} = [onsets{6} trials.time_quest(i) - trials.scan_start(i)];
                durations{6} = [durations{6} 0];
            elseif trials.question_num(i) == 2 % RT
                onsets{7} = [onsets{7} trials.time_quest(i) - trials.scan_start(i)];
                durations{7} = [durations{7} 0];
            elseif    trials.question_num(i) == 4 % none
                onsets{9} = [onsets{9} trials.time_quest(i) - trials.scan_start(i)];
                durations{9} = [durations{9} 0];
            end
        end
        % --- other regressors ---
        % Fixation point #5
        onsets{5} = [onsets{5} trials.onset_start(i)];
        durations{5} = [durations{5} 0];

        % Keypress #10
        if ~isnan(trials.rt1(i)) % answer given for quest 1 2 or 3
            onsets{10} = [onsets{10} trials.time_quest(i) - trials.scan_start(i) + trials.rt1(i)];
            durations{10} = [durations{10} 0];
        else
            if ~isnan(trials.rt2(i)) % RT available for question 4 ('none')
                onsets{10} = [onsets{10} trials.time_quest(i) - trials.scan_start(i) + trials.rt2(i)];
                durations{10} = [durations{10} 0];
            end
        end
    end

    % % --- THE STABILITY FIX ---
    % options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock} = zeros(1,12);
    % for ionset = 1:9
    %     target_cols = ionset + 3; % default shift
    %     if ionset <= 3; target_cols = [ionset*2-1, ionset*2]; end
    % 
    %     is_constant = (ionset <= 3 && ~isempty(onsets{ionset}) && length(unique(pmod(ionset).param{1})) < 2);
    % 
    %     if isempty(onsets{ionset}) || is_constant
    %         onsets{ionset} = 1000; durations{ionset} = 0;
    %         options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock}(target_cols) = 1;
    %         if ionset <= 3; pmod(ionset).param{1} = 0; end
    %     end
    % end
    
    % --- THE STABILITY FIX (Updated for 13 columns) ---
    % 10 onsets total, but 13 columns because of 3 pmods
    options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock} = zeros(1,13);

    for ionset = 1:10
        % Calculate the correct column index in the 13-column matrix
        if ionset <= 3
            target_cols = [ionset*2-1, ionset*2]; % Heard, Not Heard, Not Probed + Pmods
        else
            target_cols = ionset + 3; % Shift all others by the 3 pmod columns
        end

        % Check if Pmod is problematic (constant values)
        is_constant = (ionset <= 3 && ~isempty(onsets{ionset}) && length(unique(pmod(ionset).param{1})) < 2);

        if isempty(onsets{ionset}) || is_constant
            onsets{ionset} = 1000;
            durations{ionset} = 0;

            % Mark these specific columns as "dead"
            options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock}(target_cols) = 1;

            if ionset <= 3
                pmod(ionset).param{1} = 0; % Dummy for SPM GUI stability
            end
        end
    end
    save(fullfile(Output_directory, sprintf('mw3_timing_file_passive_subject%i_run%i.mat', str2double(sub_nb), blocknum)), "names", "onsets", "durations", "pmod");
end
end