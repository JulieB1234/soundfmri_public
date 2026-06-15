%% New new pipeline for fMRI processing - SOUNDFMRI -- Mindwandering probes in Passive condition
% feb 2026  J Boyer


%% 20 02 26 last model bis
% apply the minus no stim only for probed trials
% SO
% 1 stim heard
% 2 pmod
% 3 stim not heard
% 4 pmod 
% 5 stim not probed
% 6 pmod
% 7 stim probed but snr1
% 8 fix point
% 9 10 11 12 resp screens
% 13 keypress


clear;
%clear global options;
close all;
clc;

addpath('/Applications/spm12/');


%subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
subjects = [22 23 24 25 26 27 28 29 30 32];

passive_scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans';

% Define Options and start filling it with subject's sessions numbers
for isubj = subjects % loop across subjects of the list
    if isubj<10
        sub_nb = ['0' num2str(isubj)];
    else
        sub_nb = [num2str(isubj)];
    end
    passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE']);
    n = 0;
    for j = 1:numel(passive_folder)
        if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's8wts_OC_run') && ~contains(passive_folder(j).name,'._')
            n = n+1; %m = m+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(n-1)];
        end
    end
end
clear sub_nb;

% Complete Options
options.steps_to_run  = {'specify','estimate','contrasts'}; % {'contrasts'}; %{'specify','estimate','contrasts'}; % ,'contrasts' / Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)

options.stim_duration = {'0.2'};  % change this to test for other durations
options.missing_regressors = {};

%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)

    % Loop across subjects for the first level
    for isubj = subjects
        % define subject nb
        if isubj<10
            sub_nb = ['0' num2str(isubj)];
        else
            sub_nb = [num2str(isubj)];
        end
        options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))) = {}; % list of runs missing regressor

        % Get the timing files and fill info about missing regressors
        options = timing_files_mw3_ai_unc2(sub_nb, options);

        % Set up spm : for fMRI, and in job manager and non-interactive, commandline mode
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline',true);

        % call function 'FirstLevelParameters' whose arguments are (options, sub_nb)
        [matlabbatch1, options] = FirstLevelParameters_mw3_unc2(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end
