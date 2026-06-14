function timing_files_active(sub_nb, options)

% ACTIVE SESSION

% update 2023 : instead of classical 1st level GLM we want to make a
% parametric modulation, ie add a "continuous regressor" that will modulate
% our "stimulus" condition
% so instead of the timing files that had one regressor per stim type (n =
% 10, 5 stim levels x 2 vowels) we'll make only 2 stim regressors : A and
% E, and we'll first try with that and one parametric modulator "pmod" file
% that must be a structure array, one for each vowel then so 2
% the format needed by spm is :
% - 'name' : cell array of strings --> vowelA and vowelE ?
% - 'param' : cell array containing vectors of parameters (1 or more per
% condition)
% - 'poly' : each cell = single nber from 1 to 6, depending on the
% polynomial order we want (in the tuto they said 1 we'll try that first)

%CAUTION: conditions' onsets, durations and names must be in the same file
%(structure array) as the pmod's names, parameters and polynomial order

%manual mean centering : from (0 1 2 3 5) to (-2.2 -1.2 -0.2 0.8 2.8) so
%that there is collinearity between regressors and we don't have to use
%shitty orthogonalisation option by spm

%%

% for tests

% clear; clc; close all; %not if it is a function ;)
% sub_nb = '2';
% options.GLMtype = {'Pmod'};
% options.PModVer = {'V1'};

%% THERE IS A MISTAKE FOR THE CLASSICAL ANALYSIS -- FEB 24

%% CLASSIC OR PARAMETRIC MODULATION

% Load subject's behavioral data and define output directory
filenameTF = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/Subject_%d_*.mat', str2double(sub_nb));
files = dir(filenameTF); % Get a list of all matching files
%Output_directory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/Timing_files';

% Check if there are any matching files
if ~isempty(files)
    % Use the first matching file
    current_file = fullfile(files(1).folder, files(1).name);
    load(current_file);
else
    % Display a message in case no matching file is found
    disp(['No matching file found for Subject ' sub_nb]);
end
Output_directory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE/TimingFiles'; %sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Timing_files');

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
    if ismember(options.GLMtype,'Classic')
        % Classic timing files
            onsets = cell(13,1);
            durations = cell(13,1);
            names = cell(13,1);
            % Define names
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
            names{13} = 'Keypress2';
            % define the onsets and durations
            i = 1 + blocknum * trials_per_block ;
            while i < ((trials_per_block + 1)+blocknum*trials_per_block)
                if trials.stimulus_num(i) == 1
                    if trials.snr_num(i) == 1
                        onsets{1} = [onsets{1} trials.onset_stim(i)];
                        durations{1} = [durations{1} 0.2];
                    elseif trials.snr_num(i) == 2
                        onsets{2} = [onsets{2} trials.onset_stim(i)];
                        durations{2} = [durations{2} 0.2];
                    elseif trials.snr_num(i) == 3
                        onsets{3} = [onsets{3} trials.onset_stim(i)];
                        durations{3} = [durations{3} 0.2];
                    elseif trials.snr_num(i) == 4
                        onsets{4} = [onsets{4} trials.onset_stim(i)];
                        durations{4} = [durations{4} 0.2];
                    elseif trials.snr_num(i) == 5
                        onsets{5} = [onsets{5} trials.onset_stim(i)];
                        durations{5} = [durations{5} 0.2];
                    end
                elseif trials.stimulus_num(i) == 2
                    if trials.snr_num(i) == 1
                        onsets{6} = [onsets{6} trials.onset_stim(i)];
                        durations{6} = [durations{6} 0.2];
                    elseif trials.snr_num(i) == 2
                        onsets{7} = [onsets{7} trials.onset_stim(i)];
                        durations{7} = [durations{7} 0.2];
                    elseif trials.snr_num(i) == 3
                        onsets{8} = [onsets{8} trials.onset_stim(i)];
                        durations{8} = [durations{8} 0.2];
                    elseif trials.snr_num(i) == 4
                        onsets{9} = [onsets{9} trials.onset_stim(i)];
                        durations{9} = [durations{9} 0.2];
                    elseif trials.snr_num(i) == 5
                        onsets{10} = [onsets{10} trials.onset_stim(i)];
                        durations{10} = [durations{10} 0.2];
                    end
                end
                onsets{11} = [onsets{11} trials.onset_start(i)];
                durations{11} = [durations{11} 0];
                if ~isnan(trials.rt1(i))
                    onsets{12} = [onsets{12} trials.time_quest1(i) - trials.scan_start(i) + trials.rt1(i)];
                    durations{12} = [durations{12} 0];
                end
                if ~isnan(trials.rt2(i))
                    onsets{13} = [onsets{13} trials.time_quest2(i) - trials.scan_start(i) + trials.rt2(i)];
                    durations{13} = [durations{13} 0];
                end
                i = i+1;
            end
    elseif ismember(options.GLMtype,'Pmod')
        % Timing files for pmod
        onsets = cell(5,1);
        durations = cell(5,1);
        names = cell(5,1);
        % Define names
        names{1} = 'stim_vowel1'; %vowel A
        names{2} = 'stim_vowel2'; %vowel E
        names{3} = 'FixPoint';
        names{4} = 'Keypress1';
        names{5} = 'Keypress2';
        % For pmod --> 2 parametric modulators (LATER WE MUST ADD AUDIBILITY)
        % Create structure array 'pmod'such that pmod(1) gives info for condition 1, etc.
        pmod = struct('name',{' '}, 'param', {}, 'poly', {});
        pmod(1).name{1} = 'stim_vowel1'; %vowel A
        pmod(1).param{1} = []; %must be determined later as a function of stimulus intensity (SNR)
        pmod(1).poly{1} = 1;
        pmod(2).name{1} = 'stim_vowel2'; %vowel E
        pmod(2).param{1} = []; % must be determined later as a function of stimulus intensity (SNR)
        pmod(2).poly{1} = 1;
        if ismember(options.PModVer,'V1') %[-30 -11.5 -9.5 -7.5 -3] for both vowels
            % define onsets, durations and pmods (for version 1)
            i = 1 + blocknum * trials_per_block ;
            while i < ((trials_per_block + 1)+blocknum*trials_per_block)
                if trials.stimulus_num(i) == 1 %vowel A
                    onsets{1} = [onsets{1} trials.onset_stim(i)];
                    durations{1} = [durations{1} 0.2];
                    if trials.snr_num(i) == 1
                        pmod(1).param{1} = [pmod(1).param{1} -30];
                    elseif trials.snr_num(i) == 2
                        pmod(1).param{1} = [pmod(1).param{1} -11.5];
                    elseif trials.snr_num(i) == 3
                        pmod(1).param{1} = [pmod(1).param{1} -9.5];
                    elseif trials.snr_num(i) == 4
                        pmod(1).param{1} = [pmod(1).param{1} -7.5];
                    elseif trials.snr_num(i) == 5
                        pmod(1).param{1} = [pmod(1).param{1} -3];
                    end
                elseif trials.stimulus_num(i) == 2 % vowel E
                    onsets{2} = [onsets{2} trials.onset_stim(i)];
                    durations{2} = [durations{2} 0.2];
                    if trials.snr_num(i) == 1
                        pmod(2).param{1} = [pmod(2).param{1} -30];
                    elseif trials.snr_num(i) == 2
                        pmod(2).param{1} = [pmod(2).param{1} -11.5];
                    elseif trials.snr_num(i) == 3
                        pmod(2).param{1} = [pmod(2).param{1} -9.5];
                    elseif trials.snr_num(i) == 4
                        pmod(2).param{1} = [pmod(2).param{1} -7.5];
                    elseif trials.snr_num(i) == 5
                        pmod(2).param{1} = [pmod(2).param{1} -3];
                    end
                end
                onsets{3} = [onsets{3} trials.onset_start(i)];
                durations{3} = [durations{3} 0];
                if ~isnan(trials.rt1(i))
                    onsets{4} = [onsets{4} trials.time_quest1(i) - trials.scan_start(i) + trials.rt1(i)];
                    durations{4} = [durations{4} 0];
                end
                if ~isnan(trials.rt2(i))
                    onsets{5} = [onsets{5} trials.time_quest2(i) - trials.scan_start(i) + trials.rt2(i)];
                    durations{5} = [durations{5} 0];
                end
                i = i+1;
            end
        elseif ismember(options.PModVer,'V2')%[-2.2 -1.2 -0.2 0.8 2.8] for both vowels
            % define onsets, durations and pmods (for version 1)
            i = 1 + blocknum * trials_per_block ;
            while i < ((trials_per_block + 1)+blocknum*trials_per_block)
                if trials.stimulus_num(i) == 1 %vowel A
                    onsets{1} = [onsets{1} trials.onset_stim(i)];
                    durations{1} = [durations{1} 0.2];
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
                elseif trials.stimulus_num(i) == 2 % vowel E
                    onsets{2} = [onsets{2} trials.onset_stim(i)];
                    durations{2} = [durations{2} 0.2];
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
                onsets{3} = [onsets{3} trials.onset_start(i)];
                durations{3} = [durations{3} 0];
                if ~isnan(trials.rt1(i))
                    onsets{4} = [onsets{4} trials.time_quest1(i) - trials.scan_start(i) + trials.rt1(i)];
                    durations{4} = [durations{4} 0];
                end
                if ~isnan(trials.rt2(i))
                    onsets{5} = [onsets{5} trials.time_quest2(i) - trials.scan_start(i) + trials.rt2(i)];
                    durations{5} = [durations{5} 0];
                end
                i = i+1;
            end
        end
    end
    filename_baseTF = fullfile(Output_directory, sprintf('timing_file_active_subject%i_run%i', str2double(sub_nb), blocknum));
    if ismember(options.GLMtype,'Classic')
        filename_matTF = [filename_baseTF '_classic_' '.mat'];
        save(filename_matTF,"names","onsets","durations");
    elseif ismember(options.GLMtype,'Pmod')
        if ismember(options.PModVer,'V1')
            filename_matTF = [filename_baseTF '_pmod_V1_' '.mat'];
        elseif ismember(options.PModVer,'V2')
            filename_matTF = [filename_baseTF '_pmod_V2_' '.mat'];
        end
        save(filename_matTF,"names","onsets","durations","pmod");
    end
    %save(filename_matTF,"names","onsets","durations","pmod");
end
