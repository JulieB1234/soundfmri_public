%% Soundfmri 2025 - finite impulse response - J Boyer
% We've done the classical univariate SPM GLM analyses where 
% basis functions (HRF) are convolved with onset times to best fit the time-series
% -> what if instead we wanted to examine the average time-course of the activity 
% after the onset of the condition?

% This method is known as a Finite Impulse Response (FIR) model, in which you 
% specify the length of the time window and how many time-points you want to estimate.
% Instead of a single estimate of the average amplitude of the response, 
% which is done in most analyses, you will estimate the activity at each time-point.
% For example, if you want to estimate the activity for a condition across
% a ten-second window every two seconds, this would generate five beta estimates;
% you could then compare the activity for the condition at certain time-points, 
% instead of the overall amplitude of the condition.

% 1st level specification and estimate should be very similar to classical
% univariate scripting EXCEPT:
% - Basis Functions, change the function from Canonical HRF to Finite
% Impulse Response.This generates two fields:
%   > Window Length = total time in seconds of the FIR, eg 20
%   > Order = number of time points over the time window, eg 10 --> then it
%   should give a model with 10 regressors per condition (one beta per time
%   point per condition)
% - apparently requires F contrast for inference

% Why F-contrast here?
% A FIR GLM creates multiple betas per condition (one per time bin) 
% If you want to test whether condition A ≠ condition B at any time point 
% (i.e. anywhere across the temporal profile), an F-contrast that tests the 
% set of binwise differences is appropriate (omnibus)
% A T-contrast that sums bins (e.g. average across bins) can test directional
% effect averaged across time, or you can create separate T tests for each bin
% So: use F to detect any timepoint difference, and T to test specific 
% directional hypotheses.


%% for now -- 1/10/25
% snr-wise, active condition first
% then add passive in a common pipeline?

% no ROI here, whole brain

%% CCL
% only 1st level (also done for Passive in different code) w/ SPM
% then manual 2nd level = extract betas across whole volume for each time
% bin and each snr level
% DONE

%% 12/01/26
% modif for noSNR1

%% setups

clear; clc; close all; 
addpath('/Applications/spm12');
subjects = [3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
%subjects = [2];
%scan_folder = '/Volumes/Ultra Touch/Julie/SOUNDFMRI_2025_2/scans/'; % temporary
scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Scans';


% define options struct

for isubj = subjects
    if isubj<10
        sub_nb = ['0' num2str(isubj)];
    else
        sub_nb = num2str(isubj);
    end
    
    tmp_folder = dir([scan_folder '/SOUNDFMRI_SUJET' sub_nb '_ACTIVE/']);
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

options.steps_to_run  = {'specify','estimate'}; %,'contrasts'}; % we dont actually use the contrast
options.contrast_type = 'F'; 
options.bases         = 'FIR';
options.FIRwindow     = 12; %20;
options.FIRorder      = 7; %12;

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

        timing_files_FIRactive(sub_nb);

        matlabbatch1 = FirstLevelParameters_FIRactive(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end
%% ----------------------------------------------------------------

