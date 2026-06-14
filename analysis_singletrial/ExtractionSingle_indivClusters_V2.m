%% soundfmri octobre 2025 J Boyer
% new approach to extract single-trial beta estimates
% - from GLM single model C (so no fracridge because it erases the
% potential bimodal distributions)
% - looking at all the snr levels but then subtracting average values for
% snr1 (~ baseline removal)
% - doing it first for whole brain activations
% -> grp activations = done
% -> NOW: individualize the activations to gain preciseness?


%% Set up
clear; clc; close all;

% problem with 32A adjustments, do manually
subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
active = false; passive = false;

%pts = -0.6:0.05:0.6;

colors = [0,0.2,0.9;
    0,0.8,0.9;
    0,1,0;
    1,0.7,0;
    1,0,0
    ];

%% CHANGE IT MANUALLY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/extraction_V2_indivActivFWEcROIs/';
%output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/extraction_V3_indivActivUncROIs/';
output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/V12_indivClusters_onlyHeschl/';
%correction = 'FWE05';
%correction = 'unc001';
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath('/Users/julieboyer/Desktop/GLMsingle/'));
addpath('/Applications/spm12/');
addpath('/Applications/spm12/toolbox/marsbar/');
ref_img = spm_vol('/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET22_PASSIVE/wts_OC_run0.nii'); % random scan so we have the proper dimensions for .nii files handling and the inversion matrix <3
V = ref_img(1).mat; inv_mat = inv(V); dimz = ref_img.dim;
conditions = {'passive'}; %{'active','passive'};

input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/';
SPM_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/';
behav_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/';
mask_dir_base = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/new_ROIs_2/unc001/HO_thr10/onlyA1';


%% loop across conditions and subjects to load data
for icond = 1:length(conditions)
    fprintf('\n Condition : %s \n', conditions{icond});
    if strcmp(conditions{icond},'active')
        active = true; passive = false;
    elseif strcmp(conditions{icond},'passive')
        passive = true; active = false;
    end
    for isubj = subjects
        if isubj <10
            sub_nb0 = ['0' num2str(isubj)];
        else
            sub_nb0 = [num2str(isubj)];
        end
        fprintf('\n Subject %i \n', isubj);
        if active == true
            SPM_folder = [SPM_dir '/ACTIVE/Results/Results_indiv_ActiveClassic/results_subj',sub_nb0];
            input_data = [input_dir 'active/subj' num2str(isubj) '/GLMsingle/TYPEC_FITHRF_GLMDENOISE.mat'];
            %output_folder = [output_dir 'active/subj' num2str(isubj) '/'];
            behav = [behav_dir 'ACTIVE/']; behav_folder = dir(behav);
            mask_nii = [mask_dir_base '/subj' num2str(isubj) '/active.nii'];
        elseif passive == true
            SPM_folder = [SPM_dir '/PASSIVE/Results/Results_indiv_CLASSIC/results_subj',sub_nb0];
            input_data = [input_dir 'passive/subj' num2str(isubj) '/GLMsingle/TYPEC_FITHRF_GLMDENOISE.mat'];
            %output_folder = [output_dir 'passive/subj' num2str(isubj) '/'];
            behav = [behav_dir 'PASSIVE/']; behav_folder = dir(behav);
            mask_nii = [mask_dir_base '/subj' num2str(isubj) '/passive.nii'];
        end
        % if ~isfolder(output_folder)
        %     mkdir(output_folder);
        % end
        % for this subject, extract single trial betas for each snr
        load(input_data);
        all_betas = modelmd; clear modelmd; % size 69*83*68*450 (if active and all runs)

        % get behavioral data (trials.mat) (could have been done with
        % stimorder but this adds a sanity check by going back to original data)
        for ifile = 1:numel(behav_folder)
            if behav_folder(ifile).isdir == 0
                tmp = behav_folder(ifile).name;
                if startsWith(tmp,['Subject_' num2str(isubj) '_']) && endsWith(tmp,'.mat')
                    load([behav tmp]); % trials = 450 x 33 table (if active and all runs)
                end
            end
        end

        % reformat trials if S32A
        if isubj == 32 && active
            trials1 = trials(1:397,:);
            trials2 = trials(401:450,:);
            clear trials;
            trials = [trials1; trials2];
        end

        % classify single betas as a function of snr
        % preallocate
        nb_snr1 = size(find(trials.snr_num==1),1); snr1 = zeros(dimz(1),dimz(2),dimz(3),nb_snr1); % 69*83*68 x Ntrials for this SNR
        nb_snr2 = size(find(trials.snr_num==2),1); snr2 = zeros(dimz(1),dimz(2),dimz(3),nb_snr2);
        nb_snr3 = size(find(trials.snr_num==3),1); snr3 = zeros(dimz(1),dimz(2),dimz(3),nb_snr3);
        nb_snr4 = size(find(trials.snr_num==4),1); snr4 = zeros(dimz(1),dimz(2),dimz(3),nb_snr4);
        nb_snr5 = size(find(trials.snr_num==4),1); snr5 = zeros(dimz(1),dimz(2),dimz(3),nb_snr5);
        cnt1 = 0; cnt2 = 0; cnt3 = 0; cnt4 = 0; cnt5 = 0;
        for itrial = 1:size(trials,1)
            if trials.snr_num(itrial) == 1
                cnt1 = cnt1+1;
                snr1(:,:,:,cnt1) = all_betas(:,:,:,itrial);
            elseif trials.snr_num(itrial) == 2
                cnt2 = cnt2+1;
                snr2(:,:,:,cnt2) = all_betas(:,:,:,itrial);
            elseif trials.snr_num(itrial) == 3
                cnt3 = cnt3+1;
                snr3(:,:,:,cnt3) = all_betas(:,:,:,itrial);
            elseif trials.snr_num(itrial) == 4
                cnt4 = cnt4+1;
                snr4(:,:,:,cnt4) = all_betas(:,:,:,itrial);
            elseif trials.snr_num(itrial) == 5
                cnt5 = cnt5+1;
                snr5(:,:,:,cnt5) = all_betas(:,:,:,itrial);
            end
        end
        % display sanity check messages
        fprintf('\n %i trials for snr 1 \n',size(snr1,4));
        fprintf('\n %i trials for snr 2 \n',size(snr2,4));
        fprintf('\n %i trials for snr 3 \n',size(snr3,4));
        fprintf('\n %i trials for snr 4 \n',size(snr4,4));
        fprintf('\n %i trials for snr 5 \n',size(snr5,4));

        % get indiv mask
        % get mask index
        V = spm_vol(mask_nii);
        Y = spm_read_vols(V); % 69*83*68 values of BOLD
        mask_idx = find(Y>0); clear V; clear Y;
        % % size : 10635 voxels
        % 
        % mask_nii_passive = [masks_dir 'binary_passivePMOD_FWEc05.nii'];
        % V = spm_vol(mask_nii_passive);
        % Y = spm_read_vols(V); % 69*83*68 values 0 or 1
        % mask_idx_P = find(Y==1); clear V; clear Y;
        % % size : 4036 voxels


        % apply mask : all activations in grp univariate pmod
        % flat then reshape 3D for indices selection
        snr1_flat = reshape(snr1,[dimz(1)*dimz(2)*dimz(3) size(snr1,4)]); % 389436 * 90
        snr2_flat = reshape(snr2,[dimz(1)*dimz(2)*dimz(3) size(snr2,4)]);
        snr3_flat = reshape(snr3,[dimz(1)*dimz(2)*dimz(3) size(snr3,4)]);
        snr4_flat = reshape(snr4,[dimz(1)*dimz(2)*dimz(3) size(snr4,4)]);
        snr5_flat = reshape(snr5,[dimz(1)*dimz(2)*dimz(3) size(snr5,4)]);
        % nb i dont put all snrs in one big mat because the number of
        % single trials might vary across conditions (e.g. if less than 90
        % trials for some reason, or if later we do HnotH, ...)

        mask_snr1 = snr1_flat(mask_idx,:); % size Nvoxels x Ntrials for this snr, eg 10635*90
        mask_snr2 = snr2_flat(mask_idx,:);
        mask_snr3 = snr3_flat(mask_idx,:);
        mask_snr4 = snr4_flat(mask_idx,:);
        mask_snr5 = snr5_flat(mask_idx,:);


        %% indiv figures - just active so far
        % scatterplot for sanity check
        % figure; hold on;
        % scatter(ones(size(snr1,4),1),mean(mask_snr1,1));
        % scatter(repmat(2,size(snr2,4),1),mean(mask_snr2,1));
        % scatter(repmat(3,size(snr3,4),1),mean(mask_snr3,1));
        % scatter(repmat(4,size(snr4,4),1),mean(mask_snr4,1));
        % scatter(repmat(5,size(snr5,4),1),mean(mask_snr5,1));
        % legend('snr1','snr2','snr3','snr4','snr5');

        %% average all SNRs across voxels, keeping the Ntrials single values
        snr1_avg = mean(mask_snr1,1); % size 1xNtrials, eg 1x90 trials of snr1
        snr2_avg = mean(mask_snr2,1);
        snr3_avg = mean(mask_snr3,1);
        snr4_avg = mean(mask_snr4,1);
        snr5_avg = mean(mask_snr5,1);

        %% now:
        % - substract baseline so average snr1 from all indiv single trial betas
        % for snr 2-5
        % - plot inter trial variability / avg / distrib



        %% 

        %%% figures - all snrs but no bsl removed %%%%%%%%%%%%%%%%%%%%%%%%%%
        labels = {'snr1','snr2','snr3','snr4','snr5'};
        figure; hold on;

        % scatter plot
        subplot(2,2,1); hold on;
        scatter(ones(size(snr1,4),1),snr1_avg);
        scatter(repmat(2,size(snr2,4),1),snr2_avg);
        scatter(repmat(3,size(snr3,4),1),snr3_avg);
        scatter(repmat(4,size(snr4,4),1),snr4_avg);
        scatter(repmat(5,size(snr5,4),1),snr5_avg);
        xticks([1 2 3 4 5]);
        xticklabels(labels)
        subtitle('Single trial beta values for SNR 1-5 - all activations')

        % average per snr
        snr1_grd_avg = squeeze(mean(snr1_avg));
        snr2_grd_avg = squeeze(mean(snr2_avg));
        snr3_grd_avg = squeeze(mean(snr3_avg));
        snr4_grd_avg = squeeze(mean(snr4_avg));
        snr5_grd_avg = squeeze(mean(snr5_avg));
        grd_avg_rmbsl = [snr1_grd_avg; snr2_grd_avg; snr3_grd_avg; snr4_grd_avg; snr5_grd_avg];
        stds = [std(snr1_avg) std(snr2_avg) std(snr3_avg) std(snr4_avg) std(snr5_avg)];
        subplot(2,2,2); hold on;
        errorbar(grd_avg_rmbsl,stds,'LineWidth',2);
        grid on;
        xticks([1 2 3 4 5]);
        xticklabels(labels)
        subtitle('Average values for SNR 1-5 - all activations')

        % inter-trial variability
        subplot(2,2,3); hold on;
        plot(stds,'LineWidth',2);
        grid on;
        xticks([1 2 3 4 5]);
        xticklabels(labels)
        subtitle('Inter-trial variability for SNR 1-5  - all activations')

        % distributions
        minz = min(snr1_avg); maxz = max(snr5_avg);
        t0 = minz-0.5; t1 = maxz+0.5;
        pts = t0:0.05:t1;
        subplot(2,2,4); hold on;
        [f,xi] = ksdensity(snr1_avg,pts);
        plot(xi,f, 'Color', colors(1,:), LineWidth=2);
        [f,xi] = ksdensity(snr2_avg,pts);
        plot(xi,f, 'Color', colors(2,:), LineWidth=2);
        [f,xi] = ksdensity(snr3_avg,pts);
        plot(xi,f, 'Color', colors(3,:), LineWidth=2);
        [f,xi] = ksdensity(snr4_avg,pts);
        plot(xi,f, 'Color', colors(4,:), LineWidth=2);
        [f,xi] = ksdensity(snr5_avg,pts);
        plot(xi,f, 'Color', colors(5,:), LineWidth=2);
        legend('snr1','snr2','snr3','snr4','snr5');
        subtitle('distributions after kernel smoothing');
        saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed.png']);
        close(gcf);

        % distrib alone
        f = figure('Position',[34 287 1300 430]/9*7,'PaperPositionMode','auto','PaperOrientation','landscape');
        hold on;
        [f,xi] = ksdensity(snr1_avg,pts);
        plot(xi,f, 'Color', colors(1,:), LineWidth=2);
        [f,xi] = ksdensity(snr2_avg,pts);
        plot(xi,f, 'Color', colors(2,:), LineWidth=2);
        [f,xi] = ksdensity(snr3_avg,pts);
        plot(xi,f, 'Color', colors(3,:), LineWidth=2);
        [f,xi] = ksdensity(snr4_avg,pts);
        plot(xi,f, 'Color', colors(4,:), LineWidth=2);
        [f,xi] = ksdensity(snr5_avg,pts);
        plot(xi,f, 'Color', colors(5,:), LineWidth=2);
        legend('snr1','snr2','snr3','snr4','snr5');
        grid('on');
        title('Single trial distributions after kernel smoothing -- no bsl removed');
        saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed_distribution.png']);
        close(gcf);

        %% z-score distributions
        % so we have our values BEFORE averaging -> flat them up -> zscore -> reshape back to mask_snr dimensions, ie Nvoxels x Ntrials (eg 10635x90)
        % WHAT NOT TO DO -- zscoring snr by snr erases all differences ............. GNE
        % snr1_all_flat = mask_snr1(:); z_snr1_all_flat = zscore(snr1_all_flat); z_snr1_all = reshape(z_snr1_all_flat,size(mask_snr1,1),size(mask_snr1,2));
        % snr2_all_flat = mask_snr2(:); z_snr2_all_flat = zscore(snr2_all_flat); z_snr2_all = reshape(z_snr2_all_flat,size(mask_snr2,1),size(mask_snr2,2));
        % snr3_all_flat = mask_snr3(:); z_snr3_all_flat = zscore(snr3_all_flat); z_snr3_all = reshape(z_snr3_all_flat,size(mask_snr3,1),size(mask_snr3,2));
        % snr4_all_flat = mask_snr4(:); z_snr4_all_flat = zscore(snr4_all_flat); z_snr4_all = reshape(z_snr4_all_flat,size(mask_snr4,1),size(mask_snr4,2));
        % snr5_all_flat = mask_snr5(:); z_snr5_all_flat = zscore(snr5_all_flat); z_snr5_all = reshape(z_snr5_all_flat,size(mask_snr5,1),size(mask_snr5,2));

        % put all values across snrs together
        snr1_all_flat = mask_snr1(:);
        snr2_all_flat = mask_snr2(:);
        snr3_all_flat = mask_snr3(:);
        snr4_all_flat = mask_snr4(:);
        snr5_all_flat = mask_snr5(:);
        SNR_ALL_FLAT = [snr1_all_flat; snr2_all_flat; snr3_all_flat; snr4_all_flat; snr5_all_flat]; % 5x90xNvoxels (e.g. 10635) = 4785750!

        % zscore it across all dimensions
        ZZZ = zscore(SNR_ALL_FLAT);

        % reshape back to each snr separately
        z_snr1_all_flat = ZZZ(1:size(snr1_all_flat,1));
        tmp = ZZZ(size(snr1_all_flat,1)+1:end);
        z_snr2_all_flat = tmp(1:size(snr2_all_flat,1));
        tmp = tmp(size(snr2_all_flat,1)+1:end);
        z_snr3_all_flat = tmp(1:size(snr3_all_flat,1));
        tmp = tmp(size(snr3_all_flat,1)+1:end);
        z_snr4_all_flat = tmp(1:size(snr4_all_flat,1));
        tmp = tmp(size(snr4_all_flat,1)+1:end);
        z_snr5_all_flat = tmp(1:size(snr5_all_flat,1));
        tmp = tmp(size(snr5_all_flat,1)+1:end);

        % make sure the vector is empty, meaning we removed all data correctly
        if ~isempty(tmp)
            error('error with the repartition of z score data');
        end

        % reshape back each snr to mask_snr dimensions, ie Nvoxels x Ntrials (eg 10635x90)
        z_snr1_all = reshape(z_snr1_all_flat,size(mask_snr1,1),size(mask_snr1,2));
        z_snr2_all = reshape(z_snr2_all_flat,size(mask_snr2,1),size(mask_snr2,2));
        z_snr3_all = reshape(z_snr3_all_flat,size(mask_snr3,1),size(mask_snr3,2));
        z_snr4_all = reshape(z_snr4_all_flat,size(mask_snr4,1),size(mask_snr4,2));
        z_snr5_all = reshape(z_snr5_all_flat,size(mask_snr5,1),size(mask_snr5,2));


        %%

        % then all same but using these z-scored data

        % average all SNRs across voxels, keeping the Ntrials single values
        z_snr1_avg = mean(z_snr1_all,1); % size 1xNtrials, eg 1x90 trials of snr1
        z_snr2_avg = mean(z_snr2_all,1);
        z_snr3_avg = mean(z_snr3_all,1);
        z_snr4_avg = mean(z_snr4_all,1);
        z_snr5_avg = mean(z_snr5_all,1);

        % subtracting average values of snr 1 to all other snrs' single trial betas
        z_snr1_grd_avg = squeeze(mean(z_snr1_avg)); % average snr1 values
        z_snr1_avg_rmbsl = z_snr1_avg - z_snr1_grd_avg;
        z_snr2_avg_rmbsl = z_snr2_avg - z_snr1_grd_avg;
        z_snr3_avg_rmbsl = z_snr3_avg - z_snr1_grd_avg;
        z_snr4_avg_rmbsl = z_snr4_avg - z_snr1_grd_avg;
        z_snr5_avg_rmbsl = z_snr5_avg - z_snr1_grd_avg;

        % distrib alone - bsl removed
        minz = min(z_snr1_avg_rmbsl); maxz = max(z_snr5_avg_rmbsl);
        t0 = minz-0.5; t1 = maxz+0.5;
        pts = t0:0.05:t1;
        f = figure('Position',[34 287 1300 430]/9*7,'PaperPositionMode','auto','PaperOrientation','landscape');
        hold on;
        [f,xi] = ksdensity(z_snr1_avg_rmbsl,pts);
        plot(xi,f, 'Color', colors(1,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr2_avg_rmbsl,pts);
        plot(xi,f, 'Color', colors(2,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr3_avg_rmbsl,pts);
        plot(xi,f, 'Color', colors(3,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr4_avg_rmbsl,pts);
        plot(xi,f, 'Color', colors(4,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr5_avg_rmbsl,pts);
        plot(xi,f, 'Color', colors(5,:), LineWidth=2);
        legend('snr1','snr2','snr3','snr4','snr5');
        grid('on');
        saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_distribution_Zscore.png']);
        close(gcf);

        % distrib alone - bsl NOT removed
        minz = min(z_snr1_avg); maxz = max(z_snr5_avg);
        t0 = minz-0.5; t1 = maxz+0.5;
        pts = t0:0.05:t1;
        f = figure('Position',[34 287 1300 430]/9*7,'PaperPositionMode','auto','PaperOrientation','landscape');
        hold on;
        [f,xi] = ksdensity(z_snr1_avg,pts);
        plot(xi,f, 'Color', colors(1,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr2_avg,pts);
        plot(xi,f, 'Color', colors(2,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr3_avg,pts);
        plot(xi,f, 'Color', colors(3,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr4_avg,pts);
        plot(xi,f, 'Color', colors(4,:), LineWidth=2);
        [f,xi] = ksdensity(z_snr5_avg,pts);
        plot(xi,f, 'Color', colors(5,:), LineWidth=2);
        legend('snr1','snr2','snr3','snr4','snr5');
        grid('on');
        saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_distribution_Zscore_noBSLrm.png']);
        close(gcf);

        % save averaged zscore data w/ and w/o baseline removed
        no_bsl_rm.snr1 = z_snr1_avg;
        no_bsl_rm.snr2 = z_snr2_avg;
        no_bsl_rm.snr3 = z_snr3_avg;
        no_bsl_rm.snr4 = z_snr4_avg;
        no_bsl_rm.snr5 = z_snr5_avg;
        save([output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_zscore_noBSLrm.mat'],'no_bsl_rm');

        bsl_rm.snr1 = z_snr1_avg_rmbsl;
        bsl_rm.snr2 = z_snr2_avg_rmbsl;
        bsl_rm.snr3 = z_snr3_avg_rmbsl;
        bsl_rm.snr4 = z_snr4_avg_rmbsl;
        bsl_rm.snr5 = z_snr5_avg_rmbsl;
        save([output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_zscore_BSLrm.mat'],'bsl_rm');
        %%
    end % end subj loop
end % end cond loop

%% group -- for when everyone's done individually

clear; clc; close all;

%pts = -0.6:0.05:0.6;

colors = [0,0.2,0.9;
    0,0.8,0.9;
    0,1,0;
    1,0.7,0;
    1,0,0
    ];

addpath(genpath('/Users/julieboyer/Desktop/GLMsingle/'));
addpath('/Applications/spm12/');
addpath('/Applications/spm12/toolbox/marsbar/');
ref_img = spm_vol('/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET22_PASSIVE/wts_OC_run0.nii'); % random scan so we have the proper dimensions for .nii files handling and the inversion matrix <3
V = ref_img(1).mat; inv_mat = inv(V); dimz = ref_img.dim;
conditions = {'active'}; %{'active','passive'};

subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];
%input_dir2 = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/extraction_V2_indivActivFWEcROIs/';
input_dir2 = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/extraction_V3_indivActivUncROIs/';


% can't pre allocate in case of trial nb variations
grp_snr1_active = []; grp_snr1_passive = [];
grp_snr2_active = []; grp_snr2_passive = [];
grp_snr3_active = []; grp_snr3_passive = [];
grp_snr4_active = []; grp_snr4_passive = [];
grp_snr5_active = []; grp_snr5_passive = [];

for icond = 1:length(conditions)
    % with baseline removed (don't think it changes a lot of things anyway)
    for isubj = subjects
        % load subject's z-scored data
        load([input_dir2 'subj' num2str(isubj) '_' conditions{icond} '_wholeCLuster_zscore_BSLrm.mat']); % this gets us bsl_rm, a struct with fields snr1, snr2, ... snr5, each is a 1xNtrials (90) vector of values
        if strcmp(conditions{icond},'active')
            grp_snr1_active = [grp_snr1_active bsl_rm.snr1];
            grp_snr2_active = [grp_snr2_active bsl_rm.snr2];
            grp_snr3_active = [grp_snr3_active bsl_rm.snr3];
            grp_snr4_active = [grp_snr4_active bsl_rm.snr4];
            grp_snr5_active = [grp_snr5_active bsl_rm.snr5];
        elseif strcmp(conditions{icond},'passive')
            grp_snr1_passive = [grp_snr1_passive bsl_rm.snr1];
            grp_snr2_passive = [grp_snr2_passive bsl_rm.snr2];
            grp_snr3_passive = [grp_snr3_passive bsl_rm.snr3];
            grp_snr4_passive = [grp_snr4_passive bsl_rm.snr4];
            grp_snr5_passive = [grp_snr5_passive bsl_rm.snr5];
        end
    end
end



%%% figures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% active
% treat them the same as indiv, like a big subject with Nsubj x Ntrials total trials
snr1_avg = grp_snr1_active;
snr2_avg = grp_snr2_active;
snr3_avg = grp_snr3_active;
snr4_avg = grp_snr4_active;
snr5_avg = grp_snr5_active;

labels = {'snr1','snr2','snr3','snr4','snr5'};
figure; hold on;

% scatter plot
subplot(2,2,1); hold on;
%figure; hold on; 
scatter(ones(size(snr1_avg,2)),snr1_avg);
scatter(repmat(2,size(snr2_avg,2),1),snr2_avg);
scatter(repmat(3,size(snr3_avg,2),1),snr3_avg);
scatter(repmat(4,size(snr4_avg,2),1),snr4_avg);
scatter(repmat(5,size(snr5_avg,2),1),snr5_avg);
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Single trial beta values for SNR 1-5 - all activations')

% average per snr
snr1_grd_avg = squeeze(mean(snr1_avg));
snr2_grd_avg = squeeze(mean(snr2_avg));
snr3_grd_avg = squeeze(mean(snr3_avg));
snr4_grd_avg = squeeze(mean(snr4_avg));
snr5_grd_avg = squeeze(mean(snr5_avg));
grd_avg_rmbsl = [snr1_grd_avg; snr2_grd_avg; snr3_grd_avg; snr4_grd_avg; snr5_grd_avg];
stds = [std(snr1_avg) std(snr2_avg) std(snr3_avg) std(snr4_avg) std(snr5_avg)];
subplot(2,2,2); hold on;
errorbar(grd_avg_rmbsl,stds,'LineWidth',2);
grid on;
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Average values for SNR 1-5 - all activations')

% inter-trial variability
subplot(2,2,3); hold on;
plot(stds,'LineWidth',2);
grid on;
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Inter-trial variability for SNR 1-5  - all activations')

% distributions
minz = min(snr1_avg); maxz = max(snr5_avg);
t0 = minz-0.1; t1 = maxz+0.1;
pts = t0:0.05:t1;
subplot(2,2,4); hold on;
[f,xi] = ksdensity(snr1_avg,pts);
plot(xi,f, 'Color', colors(1,:), LineWidth=2);
[f,xi] = ksdensity(snr2_avg,pts);
plot(xi,f, 'Color', colors(2,:), LineWidth=2);
[f,xi] = ksdensity(snr3_avg,pts);
plot(xi,f, 'Color', colors(3,:), LineWidth=2);
[f,xi] = ksdensity(snr4_avg,pts);
plot(xi,f, 'Color', colors(4,:), LineWidth=2);
[f,xi] = ksdensity(snr5_avg,pts);
plot(xi,f, 'Color', colors(5,:), LineWidth=2);
legend('snr1','snr2','snr3','snr4','snr5');
subtitle('distributions after kernel smoothing');
%saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed.png']);
%close(gcf);

% distrib alone
f = figure('Position',[34 287 1300 430]/9*7,'PaperPositionMode','auto','PaperOrientation','landscape');
hold on;
[f,xi] = ksdensity(snr1_avg,pts);
plot(xi,f, 'Color', colors(1,:), LineWidth=2);
[f,xi] = ksdensity(snr2_avg,pts);
plot(xi,f, 'Color', colors(2,:), LineWidth=2);
[f,xi] = ksdensity(snr3_avg,pts);
plot(xi,f, 'Color', colors(3,:), LineWidth=2);
[f,xi] = ksdensity(snr4_avg,pts);
plot(xi,f, 'Color', colors(4,:), LineWidth=2);
[f,xi] = ksdensity(snr5_avg,pts);
plot(xi,f, 'Color', colors(5,:), LineWidth=2);
legend('snr1','snr2','snr3','snr4','snr5');
grid('on');
title('Single trial distributions after kernel smoothing -- no bsl removed');
%saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed_distribution.png']);
%close(gcf);

%% passive
% treat them the same as indiv, like a big subject with Nsubj x Ntrials total trials
snr1_avg = grp_snr1_passive;
snr2_avg = grp_snr2_passive;
snr3_avg = grp_snr3_passive;
snr4_avg = grp_snr4_passive;
snr5_avg = grp_snr5_passive;

labels = {'snr1','snr2','snr3','snr4','snr5'};
figure; hold on;

% scatter plot
subplot(2,2,1); hold on;
%figure; hold on; 
scatter(ones(size(snr1_avg,2)),snr1_avg);
scatter(repmat(2,size(snr2_avg,2),1),snr2_avg);
scatter(repmat(3,size(snr3_avg,2),1),snr3_avg);
scatter(repmat(4,size(snr4_avg,2),1),snr4_avg);
scatter(repmat(5,size(snr5_avg,2),1),snr5_avg);
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Single trial beta values for SNR 1-5 - all activations')

% average per snr
snr1_grd_avg = squeeze(mean(snr1_avg));
snr2_grd_avg = squeeze(mean(snr2_avg));
snr3_grd_avg = squeeze(mean(snr3_avg));
snr4_grd_avg = squeeze(mean(snr4_avg));
snr5_grd_avg = squeeze(mean(snr5_avg));
grd_avg_rmbsl = [snr1_grd_avg; snr2_grd_avg; snr3_grd_avg; snr4_grd_avg; snr5_grd_avg];
stds = [std(snr1_avg) std(snr2_avg) std(snr3_avg) std(snr4_avg) std(snr5_avg)];
subplot(2,2,2); hold on;
errorbar(grd_avg_rmbsl,stds,'LineWidth',2);
grid on;
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Average values for SNR 1-5 - all activations')

% inter-trial variability
subplot(2,2,3); hold on;
plot(stds,'LineWidth',2);
grid on;
xticks([1 2 3 4 5]);
xticklabels(labels)
subtitle('Inter-trial variability for SNR 1-5  - all activations')

% distributions
minz = min(snr1_avg); maxz = max(snr5_avg);
t0 = minz-0.1; t1 = maxz+0.1;
pts = t0:0.05:t1;
subplot(2,2,4); hold on;
[f,xi] = ksdensity(snr1_avg,pts);
plot(xi,f, 'Color', colors(1,:), LineWidth=2);
[f,xi] = ksdensity(snr2_avg,pts);
plot(xi,f, 'Color', colors(2,:), LineWidth=2);
[f,xi] = ksdensity(snr3_avg,pts);
plot(xi,f, 'Color', colors(3,:), LineWidth=2);
[f,xi] = ksdensity(snr4_avg,pts);
plot(xi,f, 'Color', colors(4,:), LineWidth=2);
[f,xi] = ksdensity(snr5_avg,pts);
plot(xi,f, 'Color', colors(5,:), LineWidth=2);
legend('snr1','snr2','snr3','snr4','snr5');
subtitle('distributions after kernel smoothing');
%saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed.png']);
%close(gcf);

% distrib alone
f = figure('Position',[34 287 1300 430]/9*7,'PaperPositionMode','auto','PaperOrientation','landscape');
hold on;
[f,xi] = ksdensity(snr1_avg,pts);
plot(xi,f, 'Color', colors(1,:), LineWidth=2);
[f,xi] = ksdensity(snr2_avg,pts);
plot(xi,f, 'Color', colors(2,:), LineWidth=2);
[f,xi] = ksdensity(snr3_avg,pts);
plot(xi,f, 'Color', colors(3,:), LineWidth=2);
[f,xi] = ksdensity(snr4_avg,pts);
plot(xi,f, 'Color', colors(4,:), LineWidth=2);
[f,xi] = ksdensity(snr5_avg,pts);
plot(xi,f, 'Color', colors(5,:), LineWidth=2);
legend('snr1','snr2','snr3','snr4','snr5');
grid('on');
title('Single trial distributions after kernel smoothing -- no bsl removed');
%saveas(gcf,[output_dir 'subj' num2str(isubj) '_' conditions{icond} '_wholeCluster_allSNRs_nobsl_removed_distribution.png']);
%close(gcf);
