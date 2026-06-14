function options = timing_files_mw3_ai(sub_nb, options)
% 1:H, 2:H-int, 3:NH, 4:NH-int, 5:NP, 6:NP-int, 7:Fix, 8-11:Resp, 12:Key
Output_directory = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_MWnewER_3/timing_files';
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
    names = {'stim_heard','stim_notheard','stim_notprobed','fixpoint',...
        'respscreen_quiz','respscreen_rt','respscreen_mw','respscreen_none','keypress'}';
    onsets = cell(9,1); durations = cell(9,1);
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
        if trials.question_num(i) == 3 && ~isnan(trials.answer_num(i)) % MW (ANSWERED) = regressor 1
            % what answer
            if trials.answer_num(i) == 1 % sound = HEARD
                onsets{1} = [onsets{1} trials.onset_stim(i)];
                durations{1} = [durations{1} durz];
                % what intensity
                if trials.snr_num(i) == 1
                    pmod(1).param{1} = [pmod(1).param{1} -2.2];
                elseif trials.snr_num(i) == 2
                    pmod(1).param{1} = [pmod(1).param{1} -1.2];
                elseif trials.snr_num(i) == 3
                    pmod(1).param{1} = [pmod(1).param{1} -0.2];
                elseif trials.snr_num(i) == 4
                    pmod(1).param{1} = [pmod(1).param{1} 0.8];
                elseif trials.snr_num(i) == 5
                    pmod(1).param{1} = [pmod(1).param{1} 2.8];
                end
            elseif trials.answer_num(i) > 1 % other answer = NOT HEARD
                onsets{2} = [onsets{2} trials.onset_stim(i)];
                durations{2} = [durations{2} durz];
                % what intensity
                if trials.snr_num(i) == 1
                    pmod(2).param{1} = [pmod(2).param{1} -2.2];
                elseif trials.snr_num(i) == 2
                    pmod(2).param{1} = [pmod(2).param{1} -1.2];
                elseif trials.snr_num(i) == 3
                    pmod(2).param{1} = [pmod(2).param{1} -0.2];
                elseif trials.snr_num(i) == 4
                    pmod(2).param{1} = [pmod(2).param{1} 0.8];
                elseif trials.snr_num(i) == 5
                    pmod(2).param{1} = [pmod(2).param{1} 2.8];
                end
            end
            % then add response screen regressor for mindwanering (#7)
            onsets{7} = [onsets{7} trials.time_quest(i) - trials.scan_start(i)];
            durations{7} = [durations{7} 0];

        else %if trials.question_num(i) ~= 3 % no MW = regressor 2
            onsets{3} = [onsets{3} trials.onset_stim(i)];
            durations{3} = [durations{3} durz];
            % what intensity
            if trials.snr_num(i) == 1
                pmod(3).param{1} = [pmod(3).param{1} -2.2];
            elseif trials.snr_num(i) == 2
                pmod(3).param{1} = [pmod(3).param{1} -1.2];
            elseif trials.snr_num(i) == 3
                pmod(3).param{1} = [pmod(3).param{1} -0.2];
            elseif trials.snr_num(i) == 4
                pmod(3).param{1} = [pmod(3).param{1} 0.8];
            elseif trials.snr_num(i) == 5
                pmod(3).param{1} = [pmod(3).param{1} 2.8];
            end
            % add resp screen regressors (#5 6 and 8)
            if trials.question_num(i) == 1  % quiz
                onsets{5} = [onsets{5} trials.time_quest(i) - trials.scan_start(i)];
                durations{5} = [durations{5} 0];
            elseif trials.question_num(i) == 2 % RT
                onsets{6} = [onsets{6} trials.time_quest(i) - trials.scan_start(i)];
                durations{6} = [durations{6} 0];
            elseif    trials.question_num(i) == 4 % none
                onsets{8} = [onsets{8} trials.time_quest(i) - trials.scan_start(i)];
                durations{8} = [durations{8} 0];
            end
        end
        % --- other regressors ---
        % Fixation point
        onsets{4} = [onsets{4} trials.onset_start(i)];
        durations{4} = [durations{4} 0];

        % Keypress
        if ~isnan(trials.rt1(i)) % answer given for quest 1 2 or 3
            onsets{9} = [onsets{9} trials.time_quest(i) - trials.scan_start(i) + trials.rt1(i)];
            durations{9} = [durations{9} 0];
        else
            if ~isnan(trials.rt2(i)) % RT available for question 4 ('none')
                onsets{9} = [onsets{9} trials.time_quest(i) - trials.scan_start(i) + trials.rt2(i)];
                durations{9} = [durations{9} 0];
            end
        end
    end

    % --- THE STABILITY FIX ---
    options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock} = zeros(1,12);
    for ionset = 1:9
        target_cols = ionset + 3; % default shift
        if ionset <= 3; target_cols = [ionset*2-1, ionset*2]; end

        is_constant = (ionset <= 3 && ~isempty(onsets{ionset}) && length(unique(pmod(ionset).param{1})) < 2);

        if isempty(onsets{ionset}) || is_constant
            onsets{ionset} = 1000; durations{ionset} = 0;
            options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){iblock}(target_cols) = 1;
            if ionset <= 3; pmod(ionset).param{1} = 0; end
        end
    end
    save(fullfile(Output_directory, sprintf('mw3_timing_file_passive_subject%i_run%i.mat', str2double(sub_nb), blocknum)), "names", "onsets", "durations", "pmod");
end
end
