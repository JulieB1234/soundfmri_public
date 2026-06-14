function timing_files_FIRpassive(sub_nb)



%% CLASSIC  ONLY
% FIR version = start at onset - TR (so minus 1.66 sec)
preTR = 1.66;

% Load subject's behavioral data and define output directory
filenameTF = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/Subject_%d_*.mat', str2double(sub_nb));
files = dir(filenameTF); % Get a list of all matching files

% Check if there are any matching files
if ~isempty(files)
    % Use the first matching file
    current_file = fullfile(files(1).folder, files(1).name);
    load(current_file);
else
    % Display a message in case no matching file is found
    disp(['No matching file found for Subject ' sub_nb]);
end
Output_directory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/TimingFiles/';

% Define main parameters after loading the trials of interest
blocks_nb = length(unique(trials.block));
trials_nb = max(trials.trial);
trials_per_block = max(trials.trial_in_block);
trial = (1:trials_nb)';

% define 'blocknum' as iblock - 1 because they're listed from 0 to
% n-1 (don't call it 'block' it seems in matlab 2023b it calls some
% new fancy toolbox function i don't have and it gets all confused)
% instead of from 1 to n in the machine


for iblock = 1:blocks_nb
    blocknum = iblock-1;
    % Define onsets, durations, names, +/- pmod if needed (depending on the option)

    % Classic timing files
    onsets = cell(12,1);
    durations = cell(12,1);
    names = cell(12,1);
    % define the names
    j = 1;k = 1;
    for i = 1:10
        if i < 6
            names{i} = sprintf('vowel1snr%i',j);
            j = j+1;
        elseif i > 5
            names{i} = sprintf('vowel2snr%i',k);
            k = k+1;
        end
    end
    names{11} = 'FixPoint';
    names{12} = 'Keypress1';
    % define the onsets and durations
    i = 1 + blocknum * trials_per_block ;
    while i < ((trials_per_block + 1)+blocknum*trials_per_block)
        if trials.stimulus_num(i) == 1
            if trials.snr_num(i) == 1
                onsets{1} = [onsets{1} trials.onset_stim(i)-preTR];
                durations{1} = [durations{1} 0.2];
            elseif trials.snr_num(i) == 2
                onsets{2} = [onsets{2} trials.onset_stim(i)-preTR];
                durations{2} = [durations{2} 0.2];
            elseif trials.snr_num(i) == 3
                onsets{3} = [onsets{3} trials.onset_stim(i)-preTR];
                durations{3} = [durations{3} 0.2];
            elseif trials.snr_num(i) == 4
                onsets{4} = [onsets{4} trials.onset_stim(i)-preTR];
                durations{4} = [durations{4} 0.2];
            elseif trials.snr_num(i) == 5
                onsets{5} = [onsets{5} trials.onset_stim(i)-preTR];
                durations{5} = [durations{5} 0.2];
            end
        elseif trials.stimulus_num(i) == 2
            if trials.snr_num(i) == 1
                onsets{6} = [onsets{6} trials.onset_stim(i)-preTR];
                durations{6} = [durations{6} 0.2];
            elseif trials.snr_num(i) == 2
                onsets{7} = [onsets{7} trials.onset_stim(i)-preTR];
                durations{7} = [durations{7} 0.2];
            elseif trials.snr_num(i) == 3
                onsets{8} = [onsets{8} trials.onset_stim(i)-preTR];
                durations{8} = [durations{8} 0.2];
            elseif trials.snr_num(i) == 4
                onsets{9} = [onsets{9} trials.onset_stim(i)-preTR];
                durations{9} = [durations{9} 0.2];
            elseif trials.snr_num(i) == 5
                onsets{10} = [onsets{10} trials.onset_stim(i)-preTR];
                durations{10} = [durations{10} 0.2];
            end
        end
        onsets{11} = [onsets{11} trials.onset_start(i)];
        durations{11} = [durations{11} 0];
        if trials.question_num(i) == 1 && ~isnan(trials.rt1(i)) %quiz
            onsets{12} = [onsets{12} trials.time_quest(i) - trials.scan_start(i) + trials.rt1(i)];
            durations{12} = [durations{12} 0];
        elseif trials.question_num(i) == 2 %RT
            if ~isnan(trials.rt1(i))
                onsets{12} = [onsets{12} trials.time_quest(i) - trials.scan_start(i) + trials.rt1(i)];
                durations{12} = [durations{12} 0];
            end
        elseif trials.question_num(i) == 3 && ~isnan(trials.rt1(i)) %mindwandering
            onsets{12} = [onsets{12} trials.time_quest(i) - trials.scan_start(i) + trials.rt1(i)];
            durations{12} = [durations{12} 0];
        elseif trials.question_num(i) == 4 && ~isnan(trials.rt2(i)) %none
            onsets{12} = [onsets{12} trials.time_pause(i) - trials.scan_start(i) + trials.rt2(i)];
            durations{12} = [durations{12} 0];
        end
        i = i+1;
    end


    filename_baseTF = fullfile(Output_directory, sprintf('timing_file_passive_subject%i_run%i', str2double(sub_nb), blocknum));

    filename_matTF = [filename_baseTF '_FIRpreTR.mat'];
    save(filename_matTF,"names","onsets","durations");

end
