function timing_files_passiveDC_justpmod(sub_nb, options)

filenameTF = sprintf('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVEDC/Subject_%d_*.mat', str2double(sub_nb));
files = dir(filenameTF);

if ~isempty(files)
    current_file = fullfile(files(1).folder, files(1).name);
    load(current_file);
else
    disp(['No matching file found for Subject ' sub_nb]);
end

Output_directory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVEDC/Results/pmod/ffx_try1/TimingFiles';

blocks_nb = length(unique(trials.block));
trials_nb = max(trials.trial);
trials_per_block = max(trials.trial_in_block);

for iblock = 1:blocks_nb
    blocknum = iblock-1;
    onsets = cell(3,1);
    durations = cell(3,1);
    names = cell(3,1);

    names{1} = 'stim_vowel1'; 
    names{2} = 'stim_vowel2'; 
    names{3} = 'targetDot'; 

    pmod = struct('name',{' '}, 'param', {}, 'poly', {});
    pmod(1).name{1} = 'stim_vowel1';
    pmod(1).param{1} = [];
    pmod(1).poly{1} = 1;
    pmod(2).name{1} = 'stim_vowel2';
    pmod(2).param{1} = [];
    pmod(2).poly{1} = 1;

    i = 1 + blocknum * trials_per_block;
    while i < ((trials_per_block + 1) + blocknum * trials_per_block)
        if trials.stimulus_num(i) == 1
            onsets{1} = [onsets{1} trials.onset_stim(i)];
            durations{1} = [durations{1} 0.2];
            snr_vals = [-2.2, -1.2, -0.2, 0.8, 2.8];
            pmod(1).param{1} = [pmod(1).param{1} snr_vals(trials.snr_num(i))];
        elseif trials.stimulus_num(i) == 2
            onsets{2} = [onsets{2} trials.onset_stim(i)];
            durations{2} = [durations{2} 0.2];
            snr_vals = [-2.2, -1.2, -0.2, 0.8, 2.8];
            pmod(2).param{1} = [pmod(2).param{1} snr_vals(trials.snr_num(i))];
        end

        if ~isnan(trials.onset_targetDot(i))
            onsets{3} = [onsets{3} trials.onset_targetDot(i)];
            durations{3} = [durations{3} trials.duration_targetDot(i)];
        end
        i = i + 1;
    end

    filename_baseTF = fullfile(Output_directory, sprintf('timing_file_passiveDC_subject%i_run%i', str2double(sub_nb), blocknum));
    filename_matTF = [filename_baseTF '_pmod_V2_' '.mat'];
    save(filename_matTF, "names", "onsets", "durations", "pmod");
end
