%% for conjunction analyses, ie integrating both active and passive conditions
% 1st attempt = treat all subjects as if they had all their active and
% passive sessions following each other --> GLM including both types of
% conditions, which seems possible as long as the timing files and
% regressors match the scans
% for the record we will then have :
% - 11 passive blocks
% - 9 active blocks
% so we make a 'mega GLM' of 20 blocks / runs / sessions for each subject
% we will keep the 'PMOD V2' analysis, which seems to be the most powerful
% so far

%% for now: 8 smoothed, not 5
% tried 5mm now (january 4th)

%%
clear
clc
close all;
clear all;
addpath('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24');

%% Define directories and main names

% 2 main files = 'ACTIVE' and 'PASSIVE' ; each containing all subjects'
% data for conditions active and passive
% we begin with the active condition

% ======================================================================================================================
% update march 24 : get the scans always from the active directory in order
% not to have the scans in more than one directory and save space
% ======================================================================================================================

cd '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE';

% Count how many subjects we have in the 'Scans' folder
folders = dir('Scans');
subj_nb_list = [];

for i = 1:numel(folders)
    % Check if it is a directory and not '.' or '..'
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        % Check if the folder name contains 'SOUNDFMRI_SUJET'
        if contains(folders(i).name, 'SOUNDFMRI_SUJET') && contains(folders(i).name, 'ACTIVE') %only count each subject once
            subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match'));
            subj_nb_list = [subj_nb_list subjectNumber];
        end
    end
end


% Define the folders where we count the nulber of scans available for each subject
active_scan_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Scans';
%passive_scan_folder =  '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE/Scans'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans';
passive_scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans';

%Define a subpart of the structure 'options' where we get the runs of each
%subject ; format is options.Sessions_names.subjXX = [RunA0, ..., RunP10]
for isubj = 1:length(subj_nb_list) % loop across subjects of the list
    sub = subj_nb_list(isubj);
    if sub<10
        sub_nb = ['0' num2str(sub)];
    else
        sub_nb = [num2str(sub)];
    end
    % loop across each subject's scans file and list the number of
    % available runs ; add it to the list / ACTIVE
    active_folder = dir([active_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_ACTIVE']);
    n = 0;
    options.Sessions_names.(['subj' sub_nb]) = {};
    for i = 1:numel(active_folder)
        if ~active_folder(i).isdir && contains(active_folder(i).name, 's5wts_OC_run') %'s8wts_OC_run')
            n = n+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunA' num2str(n-1)];
        end
    end
    % loop across each subject's scans file and list the number of
    % available runs ; add it to the list / PASSIVE
    passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE']);
    m = 0;
    for j = 1:numel(passive_folder)
        if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's5wts_OC_run') && ~contains(passive_folder(j).name, '._s') %'s8wts_OC_run')
            n = n+1; m = m+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(m-1)];
        end
    end
end
clear sub_nb;

%%
% Create a structure called 'options' with all the options set up

options.steps_to_run = {'specify','estimate','contrasts'}; %{'contrasts'}; % Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
options.modelName     = 'StimIntensityPmodConj'; % parametric modulation on stimulus intensity, 1st version
options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)
options.FIRorder     = NaN; % IF FIR
options.TimeDeriv    = 0; %if HRF
options.DispersDeriv = 0; %if HRF
options.GLMtype = {'Pmod'}; % Pmod or Classic
options.PModVer = {'V2'}; % V1 or V2, for pmod
%options.Sessions_names = {}; % The name of your sessions or runs
options.ConjType = {'CAconjCP'}; % 'CAconjCP', 'CAplusCP' or 'CAminusCP'

%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)

    % Set up spm : for fMRI, and in job manager and non-interactive,
    % commandline mode
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_get_defaults('cmdline',true);

    % Loop across subjects for the first level
    for sub_idx=1:length(subj_nb_list)
        %sub_idx = 1 ; % for tests
        % define subject nb
        subs=subj_nb_list(sub_idx);
        if subs<10
            sub_nb = ['0' num2str(subs)];
        else
            sub_nb = [num2str(subs)];
        end

        % get the timing files by calling the appropriate function
        timing_files_active(sub_nb, options);
        timing_files_passive(sub_nb, options);

        % call function 'FirstLevelParameters' whose arguments are
        % (options, sub_nb), sub_nb being a character number, ex : '02'
        matlabbatch1 = FirstLevelParameters_SF3(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end
