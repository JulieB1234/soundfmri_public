%% Soundfmri 2025 - finite impulse response - J Boyer
% FIR analysis
% requires SPM univariate with modification = regressors x Nbins (number of
% time points to model) instead of convolving their onsets with a canonical
% HRF

%% this is 1st level
% - active snr - done n = 32
% - passive snr - here
% - then : do active and passive HnotH

%% 3/10/25 - passive version, SNR wise

%% 12/01/26
% modif for noSNR1

%% setups

clear; clc; close all; 
addpath('/Applications/spm12');
subjects = [3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
%subjects = [2];
%scan_folder = '/Volumes/Ultra Touch/Julie/SOUNDFMRI_2025_2/scans/'; % temporary
scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans';


% define options struct

for isubj = subjects
    if isubj<10
        sub_nb = ['0' num2str(isubj)];
    else
        sub_nb = num2str(isubj);
    end
    
    tmp_folder = dir([scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE/']);
    n = 0;
    options.Sessions_names.(['subj' sub_nb]) = {};
    for i = 1:numel(tmp_folder)
        if ~tmp_folder(i).isdir && contains(tmp_folder(i).name, 's8wts_OC_run') && ~contains(tmp_folder(i).name,'._')
            n = n+1;
            options.Sessions_names.(['subj' sub_nb]){n} = ['RunA' num2str(n-1)];
        end
    end
end

clear sub_nb; clear isubj;

options.steps_to_run  = {'specify','estimate'}; %'contrasts'};
options.contrast_type = 'F'; 
options.bases         = 'FIR';
options.FIRwindow     = 12; %20; try also 13
options.FIRorder      = 7; %12; try also 8

%% 1st level job

if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)

    % Set up spm
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_get_defaults('cmdline',true);

    % Loop across subjects for the first level
    for isubj = subjects
        if isubj<10
            sub_nb = ['0' num2str(isubj)];
        else
            sub_nb = num2str(isubj);
        end

        %timing_files_FIRpassive(sub_nb); % do the FIR specific timing files if needed
        timing_files_FIRpassive_noSNR1(sub_nb);
        matlabbatch1 = FirstLevelParameters_FIRpassive(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end
