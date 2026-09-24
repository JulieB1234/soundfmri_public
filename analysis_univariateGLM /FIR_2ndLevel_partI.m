%% Trying to manually average FIR data across subjects - soundfmri J Boyer 2025
% extract betas and z-score across all SNRs for each subject
% save as z_subj in '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI
% 2025/FIR/FIRdata_wholebrain_indiv_perSNR_2_ZscoreAcrossSNRs/' for each
% subj

%% INPUT = 1st level FIR files (SPM.mat) + conjunction based ROIs + scans (just for ref image)
%% OUPUT = z-scored values for each time-point and each ROI voxel and each subject and each condition (.mat files) => then partII

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

