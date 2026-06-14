%% Trying to manually average FIR data across subjects - soundfmri J Boyer 2025
% extract betas and z-score across all SNRs for each subject
% save as z_subj in '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI
% 2025/FIR/FIRdata_wholebrain_indiv_perSNR_2_ZscoreAcrossSNRs/' for each
% subj

% setup
clear; clc; close all;
addpath('/Applications/spm12');
subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
%input_dirP = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/2ndLevel_V2_passiveSNR/';
%input_dirA = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/2ndLevel_V2_activeSNR/';
output_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/2ndLevel_V2_APSNR/';
scan_file = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/wts_OC_run8.nii';
where = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/FIRdata_wholebrain_indiv_perSNR_2_ZscoreAcrossSNRs/';
%result_fig_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/Grp_figures_FIR_snrAP_V2_ZscoreAcrossSNRs/';
temp = spm_vol(scan_file);
ref_img = temp(1); vol_dim = ref_img.dim;
clear temp;

% cols_snr = [
%     0.8 0.2 0.2;  % SNR1 red
%     0.9 0.5 0.2;  % SNR2 orange
%     0.4 0.7 0.2;  % SNR3 green
%     0.2 0.6 0.8;  % SNR4 turquoise
%     0.2 0.3 0.6   % SNR5 blue
% ];

cols_snr = [0,0.2,0.9;
    0,0.8,0.9;
    0,1,0;
    1,0.7,0;
    1,0,0
    ];


nSubj = numel(subjects);
nBins = 7; %12;
TR = 1.66;

ROI_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/ROI_analyses/Atlas_rois_ref_coords_2/';

ROI_dir = dir(ROI_folder);
stringos = {}; cnt = 0;
for ifile = 1:numel(ROI_dir)
    tmp = ROI_dir(ifile).name;
    if contains(tmp,'.mat') && ~contains(tmp,'._')  && ~strcmp(tmp,'.mat')
        cnt = cnt+1;
        stringos{cnt} = [ROI_folder tmp];
    end
end

% DONE 9/10/25
%% Save all indiv data
input_dirP = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/1stLevel_new_allSNRs_12_7_preOnset/'; input_dirA = input_dirP;

nSnrs = 5;
bigsize = ref_img.dim(1)*ref_img.dim(2)*ref_img.dim(3);
grp_firA = zeros(nSubj, nSnrs, nBins, bigsize); % 27 subj x 5 snrs x 7 timepoints x 389436 voxels
grp_firP = zeros(nSubj, nSnrs, nBins, bigsize);
sbj_cnt = 0;

% active
disp('Active');
for isubj = subjects
    subj_5snr = zeros(nSnrs,nBins,bigsize); % 5 x 7 x Nvoxels
    fprintf('\n Subject %i ... \n', isubj);
    sbj_cnt = sbj_cnt + 1;
    clear SPM;
    if isubj<10
        load([input_dirA 'results_subj0' num2str(isubj) 'activeSNR_wholebrain/SPM.mat']);
        cd([input_dirA 'results_subj0' num2str(isubj) 'activeSNR_wholebrain']);
    else
        load([input_dirA 'results_subj' num2str(isubj) 'activeSNR_wholebrain/SPM.mat']);
        cd([input_dirA 'results_subj' num2str(isubj) 'activeSNR_wholebrain']);
    end
    for isnr = 1:5
        % pick betas for cond of interest
        beta_names = SPM.xX.name;
        idx_snr = find(contains(beta_names,['snr' num2str(isnr)])); % 1x126 -> 2 vowels x 9 runs x 7 bins (because this condition appears twice in every run)
        nreg = numel(idx_snr);
        ngroup = nreg/nBins; % 126 / 7 ? = 18 (2 vowels x 9 runs)

        subj_fir = zeros(nBins,bigsize); % dim 7 timepoints x 389436 voxels
        for ibin = 1:nBins
            bin_vals = zeros(bigsize, ngroup); % dim 389436 voxels x 18 regressors
            for ireg = 1:ngroup
                r = (ireg-1)*nBins + ibin;
                idx = idx_snr(r);
                Vtmp = SPM.Vbeta(idx);
                tmp = spm_vol(Vtmp);
                betas = spm_read_vols(tmp); % size 69x83x68 = 3D (1 per voxel) beta value for this given regressor
                flat_betas = betas(:); % size 389436
                bin_vals(:,ireg) = flat_betas; % size 389436 voxels x 18 regressors we want to average for each timebin
            end
            subj_fir(ibin,:) = mean(bin_vals,2,'omitnan');
        end
        % z-score for each subjects -- keeping bins x voxels format -- NOT YET
        % mu  = mean(subj_fir, 2,'omitnan'); % bins x 1
        % stdz = std(subj_fir,0,2,'omitnan'); % bins x 1
        % z_subj_firA = (subj_fir - mu) ./ stdz; % size 7 x 389436

        %subj_5snr(isnr,:,:) = z_subj_firA; % size 5 x 7 x 389436
        subj_5snr(isnr,:,:) = subj_fir; % store before zscoring

    end

    % ---- Z-score across ALL SNRs and timebins for this subject ----
    subj_flat = subj_5snr(:); %  5*7*389436 = 13630260
    mu = mean(subj_flat,'omitnan'); su = std(subj_flat,'omitnan');
    z_subj_flat = (subj_flat - mu) ./ su;


    % reshape back to [5 × 7 × Nvox]
    z_subj = reshape(z_subj_flat, [5, nBins, bigsize]);
    %grp_firA(sbj_cnt,:,:,:) = z_subj;

    %save([where 'sbj' num2str(isubj) 'A.mat'], 'subj_5snr');
    save([where 'sbj' num2str(isubj) 'A.mat'], 'z_subj');
    fprintf('\n Subject %i - done \n', isubj);
end


clear subj_fir; clear tmp;


sbj_cnt = 0;

% passive
disp('Passive');
for isubj = subjects
    subj_5snr = zeros(nSnrs,nBins,bigsize); % 5 x 7 x Nvoxels
    fprintf('\n Subject %i ... \n', isubj);
    sbj_cnt = sbj_cnt + 1;
    clear SPM;
    if isubj<10
        load([input_dirP 'results_subj0' num2str(isubj) 'passiveSNR_wholebrain/SPM.mat']);
        cd([input_dirP 'results_subj0' num2str(isubj) 'passiveSNR_wholebrain']);
    else
        load([input_dirP 'results_subj' num2str(isubj) 'passiveSNR_wholebrain/SPM.mat']);
        cd([input_dirP 'results_subj' num2str(isubj) 'passiveSNR_wholebrain']);
    end
    for isnr = 1:5
        % pick betas for cond of interest
        beta_names = SPM.xX.name;
        idx_snr = find(contains(beta_names,['snr' num2str(isnr)])); % 1x216 -> 2 vowels x 9 runs x 12 bins (because this condition appears twice in every run)
        nreg = numel(idx_snr);
        ngroup = nreg/nBins; % 216 / 12 = 18 (2 vowels x 9 runs)

        subj_fir = zeros(nBins,bigsize); % dim 12 timepoints x 389436 voxels
        %z_subj_fir = zeros(nBins,bigsize);
        for ibin = 1:nBins
            bin_vals = zeros(bigsize, ngroup); % dim 389436 voxels x 18 regressors
            for ireg = 1:ngroup
                r = (ireg-1)*nBins + ibin;
                idx = idx_snr(r);
                Vtmp = SPM.Vbeta(idx);
                tmp = spm_vol(Vtmp);
                betas = spm_read_vols(tmp); % size 69x83x68 = 3D (1 per voxel) beta value for this given regressor
                flat_betas = betas(:); % size 389436
                bin_vals(:,ireg) = flat_betas; % size 389436 voxels x 18 regressors we want to average for each timebin
            end
            subj_fir(ibin,:) = mean(bin_vals,2,'omitnan');

        end
        subj_5snr(isnr,:,:) = subj_fir;

    end

    % zscore
    subj_flat = subj_5snr(:); %  5*7*389436 = 13630260
    mu = mean(subj_flat,'omitnan'); su = std(subj_flat,'omitnan');
    z_subj_flat = (subj_flat - mu) ./ su;

    % reshape back to [5 × 7 × Nvox]
    z_subj = reshape(z_subj_flat, [5, nBins, bigsize]);

    save([where 'sbj' num2str(isubj) 'P.mat'], 'z_subj');
    fprintf('\n Subject %i - done \n', isubj);
end


% %% plot without stats
% % starting from indiv data per SNR
% rootdir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/FIRdata_wholebrain_indiv_perSNR_2_ZscoreAcrossSNRs/';
% 
% for iroi = 1:numel(stringos) % loop across ROIs
%     ROI_name = extractBefore(stringos{iroi},'.mat');
%     ROI_name = extractAfter(ROI_name,'coords_2/');
%     fprintf('\n \n Working on ROI %i / %i : %s \n \n', iroi, numel(stringos), ROI_name);
% 
%     % Get ROI and its coordinates
%     load(stringos{iroi}); % load
% 
%     roi_coords = ref_vox_inds; % 3 x Nvox in ROI
%     roi_idx = sub2ind(vol_dim, roi_coords(1,:), roi_coords(2,:), roi_coords(3,:)); % 1 x Nvox in ROI
% 
%     % Extract active and passive data within ROI and average them 
% 
% 
%     all_snrA = zeros(5, nSubj, nBins);
%     all_snrP = zeros(5, nSubj, nBins);
% 
%     for isnr = 1:5 % loop across stim intensity
%         cnt = 0;
%         roi_firA_snr = zeros(nSubj, nBins);
%         roi_firP_snr = zeros(nSubj, nBins);
%         for isub = subjects % loop across subjects
%             cnt = cnt + 1;
%             % load indiv data and keep the given SNR
%             active = load([rootdir 'sbj' num2str(isub) 'A.mat']); % variable : tmp ; dim = 1 (subj) x 5 SNRs x 7 time bins x N voxels
%             tmp = active.subj_5snr;
%             tmp = tmp(isnr,:,:); % size 1 x 7 x Nvoxels
%             tmp_active = squeeze(tmp); % size 7 x Nvoxels
%             clear tmp;
%             passive = load([rootdir 'sbj' num2str(isub) 'P.mat']);
%             tmp = passive.subj_5snr;
%             tmp = squeeze(tmp); % size 5 x 7 x Nvoxels
%             tmp = tmp(isnr,:,:); % size 1 x 7 x Nvoxels
%             tmp_passive = squeeze(tmp); % size 7 x Nvoxels
%             clear tmp;
%             indiv_roiA = tmp_active(:, roi_idx); % size 7 x nVoxels in ROI
%             indiv_roiP = tmp_passive(:, roi_idx);
%             % average across voxels and put in a common cell for all
%             % subjects
%             roi_firA_snr(cnt,:) = mean(indiv_roiA,2,'omitnan'); % 27 subj x 7 bins
%             roi_firP_snr(cnt,:) = mean(indiv_roiP,2,'omitnan');
%         end
% 
%         % for common figure later
%         all_snrA(isnr,:,:) = roi_firA_snr;
%         all_snrP(isnr,:,:) = roi_firP_snr; % 5 snrs x 27 subj x 7 bins
% 
%         % for a given ROI and SNR - average and plot group
%         meanA = mean(roi_firA_snr, 1);
%         meanP = mean(roi_firP_snr, 1);
%         semA = std(roi_firA_snr, 0, 1) / sqrt(nSubj);
%         semP = std(roi_firP_snr, 0, 1) / sqrt(nSubj);
% 
%         col_active  = [0.6 0.05 0.3];
%         col_passive = [0.1 0.3 0.6];
%         time = (-1 * TR) + (0:nBins-1) * TR;
% 
%         figure; hold on;
%         errorbar(time, meanA, semA, '-o', 'LineWidth',2, 'Color',col_active); % dark blue
%         errorbar(time, meanP, semP, '-o', 'LineWidth',2, 'Color',col_passive); % bordeaux
%         xline(0,'--k','LineWidth',1.2); yline(0,'--k','LineWidth',1.2);
%         %text(0.2, max([meanA meanP])*0.95, 'Stim onset', 'FontSize',10,'Color','k');
%         xlabel('Time (s)');
%         ylabel('Z-scored beta (a.u.)');
%         title(['FIR - ' strrep(ROI_name,'_',' ') ' SNR ' num2str(isnr)]);
%         legend({'Active','Passive'});
%         saveas(gcf, [result_fig_dir ROI_name '_SNR' num2str(isnr) '.png']);
%         close(gcf);
%     end
% 
%     % plot all SNRs together for active
%     figure; hold on;
%     for ii = 1:5
%         snr_data = squeeze(all_snrA(ii,:,:));
% 
%         % Mean and SEM across subjects
%         mean_snr = mean(snr_data, 1, 'omitnan');      % [1 × 7]
%         sem_snr  = std(snr_data, 0, 1, 'omitnan') ./ sqrt(nSubj); % [1 × 7]
% 
%         % Plot with color for each SNR
%         errorbar(time, mean_snr, sem_snr, '-o', 'Color', cols_snr(ii,:), ...
%             'LineWidth', 2, 'MarkerFaceColor', cols_snr(ii,:), 'CapSize', 6);
% 
%         xlabel('Time (s)');
%         ylabel('Z-scored beta estimates (a.u.)');
%         legend({'SNR1','SNR2','SNR3','SNR4','SNR5'}, 'Location', 'best');
%         title(['Active condition: FIR per SNR level ' strrep(ROI_name,'_',' ')]);
%         set(gca, 'FontSize', 12, 'LineWidth', 1.2);
% 
%         grid on;
%     end
% 
%     saveas(gcf,[result_fig_dir ROI_name 'active_allSNR.png'])
%     close(gcf);
% 
%     % plot all SNRs together for passive
%     figure; hold on;
%     for ii = 1:5
%         snr_data = squeeze(all_snrP(ii,:,:));
% 
%         % Mean and SEM across subjects
%         mean_snr = mean(snr_data, 1, 'omitnan');      % [1 × 7]
%         sem_snr  = std(snr_data, 0, 1, 'omitnan') ./ sqrt(nSubj); % [1 × 7]
% 
%         % Plot with color for each SNR
%         errorbar(time, mean_snr, sem_snr, '-o', 'Color', cols_snr(ii,:), ...
%             'LineWidth', 2, 'MarkerFaceColor', cols_snr(ii,:), 'CapSize', 6);
% 
%         xlabel('Time (s)');
%         ylabel('Z-scored beta estimates (a.u.)');
%         legend({'SNR1','SNR2','SNR3','SNR4','SNR5'}, 'Location', 'best');
%         title(['Passive condition: FIR per SNR level ' strrep(ROI_name,'_',' ')]);
% 
%         grid on;
%         set(gca, 'FontSize', 12, 'LineWidth', 1.2);
%     end
% 
%     saveas(gcf,[result_fig_dir ROI_name 'passive_allSNR.png'])
%     close(gcf);
% 
% end
% 
% %% old stuff
% 
% for iroi = 1:numel(stringos) % loop across ROIs
%     ROI_name = extractBefore(stringos{iroi},'.mat');
%     ROI_name = extractAfter(ROI_name,'coords_2/');
%     fprintf('\n \n Working on ROI %i / %i : %s \n \n', iroi, numel(stringos), ROI_name);
% 
%     % Load active mean and sem
%     meanA = load([input_dirA 'mean_fir_grp1_activeSNR_' ROI_name '.mat']);
%     semA = load([input_dirA 'sem_fir_grp1_activeSNR_' ROI_name '.mat']);
% 
%     % Load active mean and sem
%     meanP = load([input_dirP 'mean_fir_grp1_passiveSNR_' ROI_name '.mat']);
%     semP = load([input_dirP 'sem_fir_grp1_passiveSNR_' ROI_name '.mat']);
% 
%     % Plot them together
%     %time = (0:nBins-1) * TR;
%     time = (-1 * TR) + (0:nBins-1) * TR;
% 
%     %%
%     col_active  = [0.6 0.05 0.3]; 
%     col_passive = [0.1 0.3 0.6];   
% 
%     figure; hold on;
%     %errorbar(time, meanA.mean_fir, semA.sem_fir, '-o','LineWidth',2,'Color',[1,0,0]);
%     %errorbar(time, meanP.mean_fir, semP.sem_fir, '-o','LineWidth',2,'Color',[0,0,1]);
% 
%     errorbar(time, meanA.mean_fir, semA.sem_fir, '-o', 'LineWidth', 2, 'Color', col_active, ...
%     'MarkerFaceColor', col_active, 'CapSize', 6);
%     errorbar(time, meanP.mean_fir, semP.sem_fir, '-o', 'LineWidth', 2, 'Color', col_passive, ...
%     'MarkerFaceColor', col_passive, 'CapSize', 6);
% 
%     xlabel('Time (s)');
%     ylabel('Z-scored beta estimates (a.u.)');
%     roiname2 = strrep(ROI_name,'_',' ');
%     title(['FIR in ROI ' roiname2 ' - Betas averaged across subjects']);
% 
%     % xline(0); yline(0);
%     % legend({'ActiveSNR5','PassiveSNR5'})
% 
%     % xline(0, ':k', 'Stim onset', 'LineWidth', 1.2, ...
%     %     'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
%     yline(0, ':k', 'LineWidth', 1.2);
%     xline(0, ':k', 'LineWidth', 1.2);
% 
% 
%     legend({'Active SNR5', 'Passive SNR5'}) %, 'Location', 'best');
%     %grid on;
%     box off;
%     set(gca, 'FontSize', 13, 'LineWidth', 1.2);
% 
% 
%     %%
%     saveas(gcf,[output_dir 'zscored_avgFIR_APSNR_' ROI_name '.png']);
% 
% 
% end
% 
% %% T-test Active vs chance and Passive vs chance and Active vs Passive
% % ROI per ROI
% 
% basisdir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/2ndLevel_V2_APSNR/';
% load([basisdir 'active_grp_indiv.mat']); % grp_firA 27x12x389436 (nSubj x nBins x nVoxels)
% load([basisdir 'passive_grp_indiv.mat']); % grp_firB 27x12x389436 (nSubj x nBins x nVoxels)
% 
% nSubj = size(grp_firA,1);
% nBins = size(grp_firA,2);
% vol_dim = ref_img.dim;
% 
% for iroi = 1:numel(stringos)
%     ROI_name = extractBefore(stringos{iroi},'.mat');
%     ROI_name = extractAfter(ROI_name,'coords_2/');
%     fprintf('\n \n Working on ROI %i / %i : %s \n \n', iroi, numel(stringos), ROI_name);
%     load(stringos{iroi}); % load
% 
%     roi_coords = ref_vox_inds; % 3 x Nvox in ROI
%     roi_idx = sub2ind(vol_dim, roi_coords(1,:), roi_coords(2,:), roi_coords(3,:)); % 1 x Nvox in ROI
% 
%     % Extract and average FIR in ROI
% 
%     roi_firA = zeros(nSubj, nBins);
%     roi_firP = zeros(nSubj, nBins);
% 
%     for s = 1:nSubj
%         subjA = squeeze(grp_firA(s,:,:));  % [nBins × nVox]
%         subjP = squeeze(grp_firP(s,:,:));
% 
%         subj_roiA = subjA(:, roi_idx);     % [nBins × nRoiVox]
%         subj_roiP = subjP(:, roi_idx);
% 
%         roi_firA(s,:) = mean(subj_roiA, 2, 'omitnan');
%         roi_firP(s,:) = mean(subj_roiP, 2, 'omitnan');
%     end
%     % --- T-tests per bin ---
%     pA = nan(1, nBins);
%     pP = nan(1, nBins);
%     pDiff = nan(1, nBins);
% 
%     for b = 1:nBins
%         [~, pA(b)] = ttest(roi_firA(:,b), 0);
%         [~, pP(b)] = ttest(roi_firP(:,b), 0);
%         [~, pDiff(b)] = ttest(roi_firA(:,b), roi_firP(:,b));
%     end
% 
%     % FDR correction
%     [~,~,~,pA_fdr] = fdr_bh(pA);
%     [~,~,~,pP_fdr] = fdr_bh(pP);
%     [~,~,~,pDiff_fdr] = fdr_bh(pDiff);
% 
%     % --- Group stats ---
%     meanA = mean(roi_firA, 1);
%     meanP = mean(roi_firP, 1);
%     semA = std(roi_firA, 0, 1) / sqrt(nSubj);
%     semP = std(roi_firP, 0, 1) / sqrt(nSubj);
% 
%     % --- Plot ---
% 
%     col_active  = [0.6 0.05 0.3];
%     col_passive = [0.1 0.3 0.6];
%     time = (-1 * TR) + (0:nBins-1) * TR;
% 
%     figure; hold on;
%     errorbar(time, meanA, semA, '-o', 'LineWidth',2, 'Color',col_active); % dark blue
%     errorbar(time, meanP, semP, '-o', 'LineWidth',2, 'Color',col_passive); % bordeaux
%     xline(0,'--k','LineWidth',1.2); yline(0,'--k','LineWidth',1.2);
%     %text(0.2, max([meanA meanP])*0.95, 'Stim onset', 'FontSize',10,'Color','k');
%     xlabel('Time (s)');
%     ylabel('Z-scored beta (a.u.)');
%     title(['FIR - ' strrep(ROI_name,'_',' ')]);
%     legend({'Active','Passive'});
% 
% 
%     % Add significance stars for A vs P
%     sigBins = find(pDiff_fdr < 0.05);
%     for sb = sigBins
%         plot(time(sb), max([meanA meanP])*1.05, 'k*', 'MarkerSize', 8);
%     end
% 
%     % --- Save stats & figure ---
%     saveas(gcf, fullfile(output_dir, ['FIR_AP_snr5_1stTryStat_' ROI_name '.png']));
%     save(fullfile(output_dir, ['stats_' ROI_name '.mat']), ...
%         'roi_firA','roi_firP','meanA','meanP','semA','semP', ...
%         'pA','pP','pDiff','pA_fdr','pP_fdr','pDiff_fdr');
% 
% end
% 
% 
