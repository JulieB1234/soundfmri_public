%% Pipeline for fMRI processing — TRUE 1st-level Fixed-Effects (FFX) Model
% Adapted for Fixed-Effects Group Analysis across all subjects

%% INPUT = 8mm smoothed pre-processed scans for each subject and condition (.nii files) + indiv multiple nuisance regressors .txt files + indiv behav .mat files
%% OUPUT = 1st level SPM .mat files and contrasts ==> for SPM GUI


clear; clc; close all;
addpath('/Applications/spm12/');

%% Define directories and main names

%cd '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24';
ScanDir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE_DC/Scans';

folders = dir(ScanDir);
subj_list = {}; subj_nb_list = [];

for i = 1:numel(folders)
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        if contains(folders(i).name, 'SOUNDFMRI_SUJET')
            subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match'));
            subjectName = ['subject' num2str(subjectNumber)];
            subj_list.(subjectName) = folders(i).name;
            subj_nb_list = [subj_nb_list subjectNumber];
        end
    end
end

passive_scan_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE_DC/Scans';

for isubj = 1:length(subj_nb_list)
    sub = subj_nb_list(isubj);
    if sub < 10
        sub_nb = ['0' num2str(sub)];
    else
        sub_nb = num2str(sub);
    end
    n = 0;
    options.Sessions_names.(['subj' sub_nb]) = {};
    passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE_DC']);
    for j = 1:numel(passive_folder)
        if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's5wts_OC_run') && ~contains(passive_folder(j).name, '._')
            n = n + 1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(n-1)];
        end
    end
end
clear sub_nb;

%% Pipeline Options (Pmod Only)
options.steps_to_run = {'specify','estimate','contrasts'};
options.modelName     = 'StimIntensityPmod1_FFX';
options.contrast_type = 'T';
options.bases         = 'HRF';
options.GLMtype       = {'Pmod'};
options.PModVer       = {'V2'};

%% Step 1: Generate All Timing Files First
for sub_idx = 1:length(subj_nb_list)
    subs = subj_nb_list(sub_idx);
    if subs < 10
        sub_nb = ['0' num2str(subs)];
    else
        sub_nb = num2str(subs);
    end
    timing_files_passiveDC_justpmod(sub_nb, options);
end

%% Step 2: Build and Run Single Concatenated FFX Batch
if ismember('specify', options.steps_to_run) || ismember('estimate', options.steps_to_run) || ismember('contrasts', options.steps_to_run)
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_get_defaults('cmdline', true);

    % Generate single concatenated batch for all subjects
    matlabbatch = FirstLevelParameters_FFX(options, subj_nb_list);
    
    % Execute SPM job
    spm_jobman('run', matlabbatch);
end
