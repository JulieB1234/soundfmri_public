%% Trying to manually average FIR data across subjects - soundfmri J Boyer 2025

% part 2 (use z_subj already extracted and zscored for each participant
% (dim 5 snrs x 7 timepoints x 389436 voxels)

% setup
clear; clc; close all;
addpath('/Applications/spm12');
subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
scan_file = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/wts_OC_run8.nii';
result_fig_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/2ndLevel_V3_conjunctionROIs/for_fig/';

if ~isfolder(result_fig_dir)
    mkdir(result_fig_dir);
end

temp = spm_vol(scan_file);
ref_img = temp(1); vol_dim = ref_img.dim;
clear temp;


% cols_snr = [0,0.2,0.9;
%     0,0.8,0.9;
%     0,1,0;
%     1,0.7,0;
%     1,0,0
%     ];

% new colors for the 7 snrs
% 0.2 0.05 0.42; % deep purple snr0
% 0.05 0.36 0.81; % king blue snr1
% 0.15 0.9 0.9; % turquoise snr2
% 0.21 1 0.53; % green snr3 v1
% 0.58 1 0.09; % green snr3 v2
% 0 1 0; % green snr3 v3
% 1 0.73 0; % orange snr4 v1
% 1 0.53 0; % orange snr4 v2
% 1 0.24 0.19; % red snr5 v1
% 1 0.34 0.24; % red snr5 v2
% 0.56 0 0.22 % bordeaux snr6 v1
% 0.8 0 0 % bordeaux snr6 v2
% 0.6353 0.0784 0.1843 % bordeaux snr6 v3

cols_snrA = [
    0.2 0.05 0.42; % deep purple snr0
    0.05 0.36 0.81; % king blue snr1
    0.15 0.9 0.9; % turquoise snr2
    0 1 0; % green snr3 v3
    1 0.34 0.24]; % red snr5 v2

cols_snrP = [
    0.2 0.05 0.42; % deep purple snr0
    0.15 0.9 0.9; % turquoise snr2
    0 1 0; % green snr3 v3
    1 0.53 0; % orange snr4 v2
    0.6353 0.0784 0.1843]; % bordeaux snr6 v3


nSubj = numel(subjects);
nBins = 7; %12;
TR = 1.66;

%ROI_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/ConjBasedRois/corrected/';
ROI_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/ConjBasedRois/new_FWE05/';

ROI_dir = dir(ROI_folder);
stringos = {}; cnt = 0;
for ifile = 1:numel(ROI_dir)
    tmp = ROI_dir(ifile).name;
    if contains(tmp,'.nii') && ~contains(tmp,'._')  && ~strcmp(tmp,'.mat')
        cnt = cnt+1;
        stringos{cnt} = [ROI_folder tmp];
    end
end

%% fixing snr legends
% snr0 : snr 1 A & P
% snr1 : snr 2 A
% snr2 : snr 2 P & 3 A
% snr3 : snr 3 P & 4 A
% snr4 : snr 4 P
% snr5 : snr 5 A
% snr6 : snr 5 P

% so :
% - active:
% snr1 -> snr0
% snr2 -> snr1
% snr3 -> snr2
% snr4 -> snr3
% snr5 -> snr5
% - passive:
% snr1 -> snr0
% snr2 -> snr2
% snr3 -> snr3
% snr4 -> snr4
% snr5 -> snr6

%% all indiv data already saved ++ 
% cf rootdir

%% plot without stats
% starting from indiv data per SNR
%rootdir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/FIRdata_wholebrain_indiv_perSNR/';
rootdir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/FIRdata_wholebrain_indiv_perSNR_2_ZscoreAcrossSNRs/'; % ZSCORE

for iroi = 1:numel(stringos)
    ROI_name = extractBefore(stringos{iroi},'.nii');
    ROI_name = extractAfter(ROI_name,'new_FWE05/');
    fprintf('\n \n Working on ROI %i / %i : %s \n \n', iroi, numel(stringos), ROI_name);

    % --- Load ROI mask ---
    thisroi = spm_vol(stringos{iroi});
    thisroi_vol = spm_read_vols(thisroi);
    roi_idx = find(thisroi_vol > 0);

    % --- Extract active and passive data ---
    all_snrA = zeros(5, nSubj, nBins);
    all_snrP = zeros(5, nSubj, nBins);

    for isnr = 1:5
        cnt = 0;
        roi_firA_snr = zeros(nSubj, nBins);
        roi_firP_snr = zeros(nSubj, nBins);

        for isub = subjects
            cnt = cnt + 1;
            % Load subject-level data
            active = load([rootdir 'sbj' num2str(isub) 'A.mat']);
            passive = load([rootdir 'sbj' num2str(isub) 'P.mat']);
            tmpA = squeeze(active.z_subj(isnr,:,:));   % [7 x Nvox]
            tmpP = squeeze(passive.z_subj(isnr,:,:));  % [7 x Nvox]

            indiv_roiA = tmpA(:, roi_idx);
            indiv_roiP = tmpP(:, roi_idx);

            % Mean across voxels
            roi_firA_snr(cnt,:) = mean(indiv_roiA, 2, 'omitnan');
            roi_firP_snr(cnt,:) = mean(indiv_roiP, 2, 'omitnan');
        end

        all_snrA(isnr,:,:) = roi_firA_snr;
        all_snrP(isnr,:,:) = roi_firP_snr;
    end

    % === NEW PART: define common y-limits per ROI ===
    % all_values = [all_snrA(:); all_snrP(:)];
    % y_min = min(all_values, [], 'omitnan');
    % y_max = max(all_values, [], 'omitnan');

    all_means = [];
    active_all_data = cell(1,5);
    passive_all_data = cell(1,5);
    for ii = 1:5
        % active mean
        Atmp_snr_data = squeeze(all_snrA(ii,:,:));
        active_all_data{ii} = Atmp_snr_data;
        Atmp_mean_snr = mean(Atmp_snr_data, 1, 'omitnan');
        % passive mean
        Ptmp_snr_data = squeeze(all_snrP(ii,:,:));
        Ptmp_mean_snr = mean(Ptmp_snr_data, 1, 'omitnan');
        passive_all_data{ii} = Ptmp_snr_data;
        all_means = [all_means Atmp_mean_snr Ptmp_mean_snr];
    end
    % all means together to find extremes
    %all_means = [Atmp_mean_snr Ptmp_mean_snr];
    y_min = min(all_means(:), [], 'omitnan');
    y_max = max(all_means(:), [], 'omitnan');
%%
    % Add a little padding
    y_pad = 0.1 * (y_max - y_min);
    y_limits = [y_min - y_pad, y_max + y_pad];

    % compute the TIME
    time = (-1 * TR) + (0:nBins-1) * TR;
    %

    %% save all
    save([result_fig_dir '/' ROI_name '.mat'], 'active_all_data', 'passive_all_data');
end
%%
time = (-1 * TR) + (0:nBins-1) * TR;
for iroi = 1:numel(stringos)

    if (iroi == 1 || iroi == 4)
        y_limits = [-0.5 2];
    else
        y_limits = [-2.4 1.8];
    end

    
    ROI_name = extractBefore(stringos{iroi},'.nii');
    ROI_name = extractAfter(ROI_name,'new_FWE05/');
    load_data = load([result_fig_dir '/' ROI_name '.mat']);
    % --- Plot all SNRs together for Active ---
    data = load_data.active_all_data;
    %figure; hold on;
    %subplot(1,2,1); hold on; 
    f = figure('Position',[796 1168 393 680],'PaperPositionMode','auto','PaperOrientation','landscape');
    subplot(2,1,1); hold on; 
    for ii = 1:5
        snr_data = data{ii};
        mean_snr = mean(snr_data, 1, 'omitnan');
        sem_snr  = std(snr_data, 0, 1, 'omitnan') ./ sqrt(nSubj);
        errorbar(time, mean_snr, sem_snr, '-o', 'Color', cols_snrA(ii,:), ...
            'LineWidth', 2, 'MarkerFaceColor', cols_snrA(ii,:), 'CapSize', 6);
    end
    xline(0, '-', 'LineWidth', 1); % mark the stim onset
    yline(0,'-', 'LineWidth', 1);
    if iroi == 1
        xlabel('Time (s)','FontSize',30);
        ylabel('Beta estimates (a.u.)','FontSize',30);
    end
    %legend({'SNR1','SNR2','SNR3','SNR4','SNR5',' '}, 'Location', 'best');
    %legend({'SNR0','SNR1','SNR2','SNR3','SNR5'}, 'Location', 'best');
    %title(['Active condition: FIR per SNR level - ' strrep(ROI_name,'_',' ')]);
    %subtitle('Active condition');
    set(gca, 'FontSize', 20, 'LineWidth', 1.2);
    ylim(y_limits);
    
    %grid on;
    %saveas(gcf, [result_fig_dir ROI_name '_active_allSNR.png']);
    %close(gcf);

    % --- Plot all SNRs together for Passive ---
    %figure; hold on;
    %subplot(1,2,1); hold on; 
    data = load_data.passive_all_data;
    subplot(2,1,2); hold on;
    for ii = 1:5
        snr_data = data{ii};
        mean_snr = mean(snr_data, 1, 'omitnan');
        sem_snr  = std(snr_data, 0, 1, 'omitnan') ./ sqrt(nSubj);
        errorbar(time, mean_snr, sem_snr, '-o', 'Color', cols_snrP(ii,:), ...
            'LineWidth', 2, 'MarkerFaceColor', cols_snrP(ii,:), 'CapSize', 6);
    end
    xline(0, '-', 'LineWidth', 1); % mark the stim onset
    yline(0,'-', 'LineWidth', 1);
    if iroi == 1
        xlabel('Time (s)','FontSize',30);
        ylabel('Beta estimates (a.u.)','FontSize',30);
    end
    %legend({'SNR1','SNR2','SNR3','SNR4','SNR5',' '}, 'Location', 'best');
    %legend({'SNR0','SNR2','SNR3','SNR4','SNR6'}, 'Location', 'best');
    %title(['Passive condition: FIR per SNR level - ' strrep(ROI_name,'_',' ')]);
    %subtitle('Passive condition');
    set(gca, 'FontSize', 20, 'LineWidth', 1.2);
    ylim(y_limits);  % same as active!
    
    %grid on;
    %saveas(gcf, [result_fig_dir ROI_name '_passive_allSNR.png']);
    %close(gcf);

    %sgtitle(['FIR per SNR level - ' strrep(ROI_name,'_',' ')]);

    saveas(gcf, [result_fig_dir ROI_name '_allSNR.png']);
    close(gcf);

end
