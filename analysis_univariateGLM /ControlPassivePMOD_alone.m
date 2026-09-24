%% 1st attempt of editing a pipeline for fMRI processing
% juliechezboyer@wanadoo.fr / soundfmri@gmail.fr
% this is inspired from Alizee Lopez-Persem's script

% 1st try is for one subject, subj10, in active condition
% so : 1st level specification, estimation, and contrast
% we'll try to use parametric modulation on vowels A and E (as a function
% of the auditory stimulus intensity)

%% eventually we want a unique script for all the steps from preprocessed fMRI data to 2nd level results
% So it has to include / call functions that take care of :
% - defining output directory and where to find input data (ie, scans,
% multiple regressors, behavioural data, contrasts, ..) ; each subject must
% have a given directory
% - creating timing files <-- behavioural data (juste integrate the
% existing script)
% - renaming scans and multiple regressors for each run
% - checking multiple regressors files for dimension (nb of scan x nb of
% regressors ; must match the .nii files and the contrast)
% - creating the appropriate contrast ; depends on what we want to study +
% nb of runs and multiple regressors and other regressors such as keypress,
% etc.
% - specifying the 1st level model for each subject
% - estimating the model <-- SPM.mat for each subject
% - then 2nd level <-- all subjects' contrast files

%%
clear
clc
close all;
clear all;
addpath('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24');
addpath('/Applications/spm12/');

%% Define directories and main names

% 2 main files = 'ACTIVE' and 'PASSIVE' ; each containing all subjects'
% data for conditions active and passive
% we begin with the active condition

%cd '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE';
%cd '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE';
%cd '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE'
cd '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE';
% Count how many subjects we have in the 'Scans' folder
folders = dir('Scans');
%subj_nb = 0;
%subj_list = {};
subj_nb_list = [];

% Loop through each item in the folder
% for i = 1:numel(folders)
%     % Check if it is a directory and not '.' or '..'
%     if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
%         % Check if the folder name contains 'SOUNDFMRI_SUJET' (adjust as needed)
%         if contains(folders(i).name, 'SOUNDFMRI_SUJET')
%             % Increment the subject count and subjects list
%             %subj_nb = subj_nb + 1;
%             subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match')); %regexp(folders(i).name, '\d+', 'match'):
%             % Uses the regexp function to search for all occurrences of one or more digits (\d+) in the folder name (folders(i).name).
%             % The result is a cell array containing the matched substrings (which are sequences of digits).
%             subjectName = ['subject' num2str(subjectNumber)];
%             subj_list.(subjectName) = folders(i).name;
%             subj_nb_list = [subj_nb_list subjectNumber];
%         end
%     end
% end
for i = 1:numel(folders)
    % Check if it is a directory and not '.' or '..'
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        % Check if the folder name contains 'SOUNDFMRI_SUJET'
        if contains(folders(i).name, 'SOUNDFMRI_SUJET') && contains(folders(i).name, 'PASSIVE') %only count each subject once
            subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match'));
            subj_nb_list = [subj_nb_list subjectNumber];
        end
    end
end
%%
passive_scan_folder =  '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans';
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
    %active_folder = dir([active_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_ACTIVE']);
    n = 0;
    options.Sessions_names.(['subj' sub_nb]) = {};
    % for i = 1:numel(active_folder)
    %     if ~active_folder(i).isdir && contains(active_folder(i).name, 's8wts_OC_run')
    %         n = n+1;
    %         options.Sessions_names.(['subj' sub_nb]){n} = ['RunA' num2str(n-1)];
    %     end
    % end
    % loop across each subject's scans file and list the number of
    % available runs ; add it to the list / PASSIVE
    passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE']);
    %m = 0;
    for j = 1:numel(passive_folder)
        if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's8wts_OC_run') && ~contains(passive_folder(j).name, '._')
            n = n+1; %m = m+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(n-1)];
        end
    end
end
clear sub_nb;

%%
% Create a structure called 'options' with all the options set up

options.steps_to_run = {'specify','estimate','contrasts'};% Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
%options.modelName     = 'StimIntensityPmod1'; % parametric modulation on stimulus intensity, 1st version
options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)
options.FIRorder     = NaN; % IF FIR
options.TimeDeriv    = 0; %if HRF
options.DispersDeriv = 0; %if HRF
options.GLMtype = {'Pmod'}; % Pmod or Classic
options.PModVer = {'V2'}; % V1 or V2, for pmod
%options.Sessions_names = {}; % The name of your sessions or runs
% for irun = 1:11
%     run = ['Run' num2str(irun-1)];
%     options.Sessions_names{irun} = run;
%     irun = irun+1;
% end

% maybe not useful:
% options.study_code = 'SoundF1';
% options.RootOnsets = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Timing_files';
% options.RootMriData = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans';

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
            sub_nb=['0' num2str(subs)];
        else
            sub_nb=num2str(subs)  ;
        end

        % get the timing files by calling the appropriate function
        timing_files_passive(sub_nb, options); % put the timing files ..
        % in this directory: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/...
        % new_scripts_and_tests/Pipelines_tests/ACTIVE/Timing_files'

        % call function 'FirstLevelParameters' whose arguments are
        % (options, sub_nb), sub_nb being a character number, ex : '02'
        matlabbatch1 = FirstLevelParameters_SF2(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end

%% 2nd level analysis -- NOT READY YET

% options.serial=0; % With FIR, if this option is set to 1, and if parfor is not used, it will be slow
%
% if ismember('secondLevel',options.steps_to_run)
%     % mkdir for 2nd level results
%     % if exist([options.rootModels 'model' options.modelName filesep 'Second_level' filesep ''],'dir')
%     %     rmdir([options.rootModels 'model' options.modelName filesep 'Second_level' filesep ''])
%     % end
%     BIGBATCH = SecondLevelParameters(options);
%     % Loop across contrasts for the second level
%     for mb=1:length(BIGBATCH)
%         spm('defaults', 'FMRI');
%         spm_jobman('run', BIGBATCH{mb});
%     end
% end
