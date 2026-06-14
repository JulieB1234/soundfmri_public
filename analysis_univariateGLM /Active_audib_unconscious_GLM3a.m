%% New pipeline for fMRI processing - SOUNDFMRI -- Audibility ratings in active condition, snr by snr (Jan 2025)


%%
clear
clc

clear; clc; close all;
addpath('/Applications/spm12/');
%subjects = [7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
% errors : 6
active_scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Scans/';


global options;

%Define a subpart of the structure 'options' where we get the runs of each
%subject ; format is options.Sessions_names.subjXX = [RunA0, ..., RunP10]
%%
for isubj = subjects 
    if isubj<10
        sub_nb = ['0' num2str(isubj)];
    else
        sub_nb = [num2str(isubj)];
    end
    % loop across each subject's scans file and list the number of
    % available runs ; add it to the list / ACTIVE
    active_folder = dir([active_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_ACTIVE']);
    n = 0;
    options.Sessions_names.(['subj' sub_nb]) = {};
    for i = 1:numel(active_folder)
        if ~active_folder(i).isdir && contains(active_folder(i).name, 's8wts_OC_run') && ~contains(active_folder(i).name, '._')
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
%options.PModVer       = {'V2'}; % V1 or V2, for pmod
options.stim_duration = {'0.2'};  % change this to test for other durations
%options.contrast_ver  = {'1'}; % version of contrasts' function and directory
options.missing_regressors = {}; 


%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)

    % Specify the contrasts' bases -- JUST ONCE
    %Contrasts_audibPerSNR_unconscious(options);

    % Loop across subjects for the first level
    for isubj = subjects 
        % define subject nb
        if isubj<10
            sub_nb = ['0' num2str(isubj)];
        else
            sub_nb = [num2str(isubj)];
        end
        options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))) = {}; % list of runs missing regressor

        %% done already
        % Get the timing files by calling the appropriate function
        timing_files_audibPerSNR_unc2_nosave(sub_nb, options); % put the timing files in this directory: '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Timing_files'
        %%

        % Set up spm : for fMRI, and in job manager and non-interactive, commandline mode
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline',true);

        % call function 'FirstLevelParameters' whose arguments are (options, sub_nb)
        % keep only contrast step & replace SPM.mat path by other one
        % already done (they're the same)

        matlabbatch1 = FirstLevelParameters_audibPerSNR_unconscious2(options,sub_nb);
        %% modif jan 2026
        %spm_jobman('run', matlabbatch1);

        % save contrasts and apply them manually on already processed SPMs

        % tmp=matlabbatch1;
        % matlabbatch1={};
        % matlabbatch1{1}=tmp{3};
        %matlabbatch1{1, 1}.spm.stats.con.spmmat = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/with_snr1/results_1stLevel/results_subj' sub_nb '/SPM.mat'];
       
        cons = struct();
        cons.con11 = matlabbatch1{3}.spm.stats.con.consess{11};
        % cons.con8 = matlabbatch1{3}.spm.stats.con.consess{8};
        % cons.con9 = matlabbatch1{3}.spm.stats.con.consess{9};

        resultsRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/with_snr1/results_1stLevelnew2';
        resultsFolderPath = fullfile(resultsRootPath, ['results_subj' sub_nb]);

        save([resultsFolderPath 'newcontr.mat'],'cons');
        %%


    end
end
