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

        %timing_files_FIRactive(sub_nb);
        timing_files_FIRactive_noSNR1(sub_nb);
        matlabbatch1 = FirstLevelParameters_FIRactive(options,sub_nb);
        spm_jobman('run', matlabbatch1);

    end
end
%% ----------------------------------------------------------------


%% Extract FIR timecourses - roi 1 --- 
%load(fullfile(resultsFolderPath,'SPM.mat'));
%load('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/1stLevel/results_subj02activeSNR_left_audit_II/SPM.mat');
% 
% nBins = 12;                       % options.FIRorder         
% TR    = SPM.xY.RT;                % 1.66 s
% time  = (0:nBins-1)*TR;           % time axis in sec
% nStim = 2;                        % 2 vowels
% nRuns = 9;
% 
% % find regressors of interest using SPM
% idx_snr5 = find(contains(SPM.xX.name, 'snr5'));  % n = 216 -> 2 vowels x 9 runs x 12 bins (because this condition appears twice in every run) 
% 
% % ROI results so no need to extract betas from a given roi
% betas = spm_data_read(SPM.Vbeta(idx_snr5)); % size 69*83*68x216 but with 388857/389436 NANs (so i guess given roi -- left audit II -- has 579 voxels) - actually it's 914 but okay lol
% 
% % reshape into 1D
% Y = reshape(betas, [], size(betas,4)); % size  389436x216
% 
% % keep only not nans
% Y = Y(~any(isnan(Y),2),:); % size 579x216
% 
% % Average across voxels
% beta_vals = mean(Y,1); % size 1x216 -> 216 values that are averaged across all ROI's voxels
% 
% % beta_vals = [1 × 216] after voxel averaging
% % Reshape into [bins × stim × runs]
% beta_vals = reshape(beta_vals, [nBins, nStim, nRuns]);
% 
% % Merge vowA + vowE by averaging across stim dimension
% beta_vals_merged = squeeze(mean(beta_vals, 2)); % 12 time bins x 9 runs
% 
% fir_mean1 = mean(beta_vals_merged, 2);         % [nBins × 1]
% fir_sem1  = std(beta_vals_merged, [], 2) ./ sqrt(nRuns);
% 
% % Convert to % signal change (baseline = first 2 bins)
% %baseline = mean(fir_mean(1:2));
% %fir_pct  = 100 * (fir_mean - baseline) / baseline;
% %fir_sem_pct = 100 * fir_sem / baseline;
% 
% % baseline = mean(fir_mean);  % average across all bins
% % fir_pct  = 100 * (fir_mean - baseline) / baseline;
% % fir_sem_pct = 100 * fir_sem / baseline;
% 
% %% roi 2
% clear beta_vals; clear beta_vals_merged; clear betas; clear Y; clear SPM;
% load('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/1stLevel/results_subj02activeSNR_left_audit_I/SPM.mat');
% 
% 
% nBins = 12;                       % options.FIRorder         
% TR    = SPM.xY.RT;                % 1.66 s
% time  = (0:nBins-1)*TR;           % time axis in sec
% nStim = 2;                        % 2 vowels
% nRuns = 9;
% 
% % find regressors of interest using SPM
% idx_snr5 = find(contains(SPM.xX.name, 'snr5'));  % n = 216 -> 2 vowels x 9 runs x 12 bins (because this condition appears twice in every run) 
% 
% % ROI results so no need to extract betas from a given roi
% betas = spm_data_read(SPM.Vbeta(idx_snr5)); % size 69*83*68x216 but with 388857/389436 NANs (so i guess given roi -- left audit II -- has 579 voxels) - actually it's 914 but okay lol
% 
% % reshape into 1D
% Y = reshape(betas, [], size(betas,4)); % size  389436x216
% 
% % keep only not nans
% Y = Y(~any(isnan(Y),2),:); % size 579x216
% 
% % Average across voxels
% beta_vals = mean(Y,1); % size 1x216 -> 216 values that are averaged across all ROI's voxels
% 
% % beta_vals = [1 × 216] after voxel averaging
% % Reshape into [bins × stim × runs]
% beta_vals = reshape(beta_vals, [nBins, nStim, nRuns]);
% 
% % Merge vowA + vowE by averaging across stim dimension
% beta_vals_merged = squeeze(mean(beta_vals, 2)); % 12 time bins x 9 runs
% 
% fir_mean2 = mean(beta_vals_merged, 2);         % [nBins × 1]
% fir_sem2  = std(beta_vals_merged, [], 2) ./ sqrt(nRuns);
% 
% % Convert to % signal change (baseline = first 2 bins)
% %baseline = mean(fir_mean(1:2));
% %fir_pct  = 100 * (fir_mean - baseline) / baseline;
% %fir_sem_pct = 100 * fir_sem / baseline;
% 
% % baseline = mean(fir_mean);  % average across all bins
% % fir_pct  = 100 * (fir_mean - baseline) / baseline;
% % fir_sem_pct = 100 * fir_sem / baseline;
% 
% %%
% 
% % Plot
% figure; hold on
% %errorbar(time, fir_pct, fir_sem_pct, 'o-', 'LineWidth', 1.5);
% errorbar(time, fir_mean1, fir_sem1, 'o-', 'LineWidth', 1.5);
% errorbar(time, fir_mean2, fir_sem2, 'o-', 'LineWidth', 1.5);
% xlabel('Time (s)');
% ylabel('Beta value');
% title('FIR for snr5 (vowA+vowE, ROI averaged)');
% grid on
% 
% 
% %%
% % nBins   = 12;
% % nConds  = 5;
% % condNames = {'snr1','snr2','snr3','snr4','snr5'};
% % nRuns  = length(SPM.Sess);
% % 
% % pos = cell(1,nConds);
% % for c = 1:nConds
% %     pos{c} = (c-1)*nBins+1 : c*nBins;
% % end
% % 
% % betas = SPM.xX.Beta; % GLM betas
% % all_betas = nan(nBins, nConds, nRuns);
% % 
% % betaIndex = 0;
% % constants  = nan(1,nRuns);
% % 
% % for r = 1:nRuns
% %     % condition regressors
% %     for c = 1:nConds
% %         for b = 1:nBins
% %             betaIndex = betaIndex+1;
% %             all_betas(b,c,r) = betas(betaIndex);
% %         end
% %     end
% % 
% %     % nuisance regressors
% %     betaIndex = betaIndex + size(SPM.Sess(r).C.C,2);
% % 
% %     % constant regressor (baseline) for this run
% %     betaIndex = betaIndex+1;
% %     constants(r) = betas(betaIndex);
% % end
% % 
% % % average FIR across runs, convert to % signal change
% % avg_betas = mean(all_betas,3);
% % mean_constant = mean(constants);
% % 
% % fir_snr1 = (avg_betas(:,1) ./ mean_constant) * 100;
% % fir_snr5 = (avg_betas(:,5) ./ mean_constant) * 100;
% % fir_diff = fir_snr5 - fir_snr1;
% % 
% % %% Plot
% % timeAxis = (0:nBins-1) * SPM.xX.U(1).u(2); % time in sec (bin length)
% % figure;
% % plot(timeAxis,fir_snr1,'-o','DisplayName','snr1');
% % hold on;
% % plot(timeAxis,fir_snr5,'-o','DisplayName','snr5');
% % plot(timeAxis,fir_diff,'-x','DisplayName','snr5 - snr1');
% % xlabel('Time (s)');
% % ylabel('% Signal Change');
% % legend('show');
% % title('FIR timecourses (%BOLD)');
% % grid on;
