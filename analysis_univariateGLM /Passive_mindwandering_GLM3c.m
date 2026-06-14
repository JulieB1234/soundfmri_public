%% New pipeline for fMRI processing - SOUNDFMRI -- Mindwandering probes in Passive condition
% May 2024
% juliechezboyer@wanadoo.fr / soundfmri@gmail.fr
% this is inspired from Alizee Lopez-Persem's script

%% This is created because a unique big matrix with all regressors of interest wasn't possible
% indeed, several regressors regarding the same event provide invalid
% contrasts in spm, so we cannot have one matrix with both audibility
% ratings and stimulus intensity apparently
% so the idea is to have:
% - 1 matrix with only audibility ratings to see how it activates
% - 1 matrix allowing to study interaction between audibility ratings and
% stimulus intensity, i guess then we will have to create numerous
% regressors, eg "snr1audib1vowel1", "snr1audib1vowel2", etc. so 4 x 5 x 2
% stim types ie 40 regressors! and then we adapt the contrasts tot est for
% what we want; if it works maybe we can get back to the idea of one big
% matrix for all... 
% Also we have to test both pmod and classical models for audibility
% ratings ; and for pmod, we could do 1/2/3/4 or 0/1 or a mean-centered
% version, ...

%% problem of invalid contrasts: 
% in some cases, for a given run subjects never answer 'audibility 4' so
% the corresponding regressor (either condition 4 or 8, depending on the
% vowel) is missing; in timing_files computing i fixed it by adding an
% onset outside of the scanning timing but it makes contrasts invalid when
% we want to test for them (seems logical); for ex, subj10 run3, has no
% onset for condition 8 (audibility4 / vowelE), therefore the contrast [-1
% 1 1 1 -1 1 1 0 0 0 0 0] is invalid 
% one solution could be to add to the 'options' structure, the list of runs
% of each subject, that are missing a regressor, and then in the contrast
% computing, take it into account (maybe a more efficient way would've been
% to directly suppress the columns with missing onsets ? but we would still
% have to modify the contrasts accordingly so for now let's not do that)

% to do so i tried defining 'options' as a global variable to be able to
% modify it across functions

%%
clear
clc
clear global options

%% Define directories and main names
% first we get scans from the 'ACTIVE' directory (in order not to duplicate very
% heavy files)
% to get the scans: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE';
% our working directory will be: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG';

% Count how many subjects we have in the 'Scans' folder
%folders = dir('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE/Scans');
folders = dir('/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans');
subj_nb_list = [];


% Loop through each item in the folder
for i = 1:numel(folders)
    % Check if it is a directory and not '.' or '..'
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        % Check if the folder name contains 'SOUNDFMRI_SUJET' ; if so, add to subjects list
        if contains(folders(i).name, 'SOUNDFMRI_SUJET') && contains(folders(i).name, 'PASSIVE') %only count each subject once
            subjectNumber = str2double(regexp(folders(i).name, '\d+', 'match'));
            subj_nb_list = [subj_nb_list subjectNumber];
        end
    end
end

% Define the folders where we count the number of scans available for each subject
%active_scan_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Scans';
%passive_scan_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE/Scans';
passive_scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans';

global options;

%Define a subpart of the structure 'options' where we get the runs of each
%subject ; format is options.Sessions_names.subjXX = [RunA0, ..., RunP10]
for isubj = 1:length(subj_nb_list) % loop across subjects of the list
    sub = subj_nb_list(isubj);
    if sub<10
        sub_nb = ['0' num2str(sub)];
    else
        sub_nb = [num2str(sub)];
    end
    %%
    passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE']);
    n = 0;
    for j = 1:numel(passive_folder)
        if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's8wts_OC_run') && ~contains(passive_folder(j).name,'._')
            n = n+1; %m = m+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(n-1)];
        end
    end
end
%%
clear sub_nb;

%% note : for now the fisrt part of the code goes finding the avaialble subjects 
% in the list of active scans anyway.. at the end we can also decide to write the list manually

% Create a structure called 'options' with all the options set up
options.steps_to_run  = {'specify','estimate','contrasts'}; % {'contrasts'}; %{'specify','estimate','contrasts'}; % ,'contrasts' / Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)
options.GLMtype       = {'Classic'}; % Classic or Pmod
options.PModVer       = {'V2'}; % V1 or V2, for pmod
%options.Sessions_names = {}; % The name of your sessions or runs
%options.SecondLevelAnalysis = {'CAconjCP'}; % 'ANOVA', 'CAconjCP', 'CAplusCP', 'CAminusCP', ...
%options.ConjType = {'CAconjCP'}; % 'CAconjCP', 'CAplusCP' or 'CAminusCP'
options.stim_duration = {'0.2'};  % change this to test for other durations
options.contrast_ver  = {'1'}; % version of contrasts' function and directory
%options.contrast_file = {'Contrasts1'};
% if ismember('1',options.contrast_ver)
%     functionContrasts = Contrasts1().m; % chose contrast function
% end
options.missing_regressors = {}; % ATTEMPT 

%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)


    % Specify the contrasts' bases
    %functionContrasts(options) % put all contrasts in a directory
    Contrasts_mw(options);

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
        %options.missing_regressors.(sprintf('subj%i_reg4', subs)) = []; % list of runs missing regressor 4 (audib4vowelA)
        %options.missing_regressors.(sprintf('subj%i_reg8', subs)) = []; % list of runs missing regressor 8 (audib4vowelE)

        % Get the timing files by calling the appropriate function
        timing_files_mw(sub_nb, options); % put the timing files in this directory: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Timing_files'

        % Set up spm : for fMRI, and in job manager and non-interactive, commandline mode
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline',true);

        % call function 'FirstLevelParameters' whose arguments are (options, sub_nb)
        matlabbatch1 = FirstLevelParameters_mw(options,sub_nb);
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
%     for mb=1:length(BIGBATCH)2,, tvs 2
%         spm('defaults', 'FMRI');
%         spm_jobman('run', BIGBATCH{mb});
%     end
% end
