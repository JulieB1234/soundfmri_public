%% New pipeline for fMRI processing - SOUNDFMRI -- Audibility ratings in active condition, snr by snr (Jan 2025)


%%
clear
clc

%% Define directories and main names
% Count how many subjects we have in the 'Scans' folder
folders = dir('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans');

subj_nb_list = [];


% Loop through each item in the folder
for i = 1:numel(folders)
    % Check if it is a directory and not '.' or '..'
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        % Check if the folder name contains 'SOUNDFMRI_SUJET' ; if so, add to subjects list
        if contains(folders(i).name, 'SOUNDFMRI_SUJET') && contains(folders(i).name, 'ACTIVE') %only count each subject once
            subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match'));
            subj_nb_list = [subj_nb_list subjectNumber];
        end
    end
end

% Define the folders where we count the number of scans available for each subject
active_scan_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans';

global options;

%Define a subpart of the structure 'options' where we get the runs of each
%subject ; format is options.Sessions_names.subjXX = [RunA0, ..., RunP10]
%%
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
        if ~active_folder(i).isdir && contains(active_folder(i).name, '_OC_run')
            n = n+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunA' num2str(n-1)];
        end
    end
end
clear sub_nb;

% Create a structure called 'options' with all the options set up
options.steps_to_run  = {'specify','estimate','contrasts'}; % ,'contrasts' / Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)
options.GLMtype       = {'Classic'}; % Classic or Pmod
options.PModVer       = {'V2'}; % V1 or V2, for pmod
options.stim_duration = {'0.2'};  % change this to test for other durations
options.contrast_ver  = {'1'}; % version of contrasts' function and directory
options.missing_regressors = {}; % ATTEMPT 


%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)
    % Specify the contrasts' bases
    Contrasts_audibPerSNR(options);
    % Loop across subjects for the first level
    for sub_idx = 1:length(subj_nb_list)
        % Define subject nb as strings
        subs = subj_nb_list(sub_idx);
        if subs<10
            sub_nb = ['0' num2str(subs)];
        else
            sub_nb = [num2str(subs)];
        end
        options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))) = {}; % list of runs missing regressor
        % Get the timing files by calling the appropriate function
        timing_files_audibPerSNR(sub_nb, options); % put the timing files in this directory: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Timing_files'
        % Set up spm : for fMRI, and in job manager and non-interactive, commandline mode
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline',true);
        % call function 'FirstLevelParameters' whose arguments are (options, sub_nb)
        matlabbatch1 = FirstLevelParameters_audibPerSNR(options,sub_nb);
        spm_jobman('run', matlabbatch1);
        % empty the Contrast folder
        % folderPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts';
        % fileList = dir(folderPath);
        % for k = 1:length(fileList)
        %     if ~strcmp(fileList(k).name, '.') && ~strcmp(fileList(k).name, '..')
        %         fullPath = fullfile(folderPath, fileList(k).name);
        %         % If it's a file, delete it
        %         if isfile(fullPath)
        %             delete(fullPath);
        %             % If it's a folder, delete recursively
        %         elseif isdir(fullPath)
        %             rmdir(fullPath, 's');
        %         end
        %     end
        % end

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
