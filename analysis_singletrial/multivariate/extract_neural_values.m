%% soundfmri octobre 2025 - j boyer

% using mvpa's intermediate results 'decoding_out' to extract single-trials
% decision values (ie, distance to hyperplane) ; in decoding snr5 vs snr1
% (our gold standard), ie 2-class classification -> if dval > 0: 1st label
% is predicted so here snr1, if dval < 0: 2nd label so here snr5

% for now i just want to extract all subjects' dvals for a given ROI when
% decoding snr5 / 1 in active and passive conditions -- just test ROI so
% far : left audit I
% and look at the distribution of the trials' decision values for just snr
% 5 and 1

%% nov 25
% new version -> not several ROIs but one big ROI for each subject
% corresponding to full cluster of univariate activations in pmod (for now,
% uncorrected p .001)

%% jan26 using the version with cross classification so values for all snrs

% setup
clear; close all; clc;

input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI2/unc001/';
output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI2/unc001/decision_values_prettier_3/';
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

subjects = [2 3 4 5 6 7 8 10 12 13 14 15 18 19 20 21 23 24 25 26 27 28 30 32]; % no 9 22 29 for A1 only ...
%subjects = [10];
roi_list = {'_NoA1_thr10','_A1_thr10'};
% decoding_out.mat -> decision values
% res_AUC.mat -> AUC -> output -> AUC value
% true_labels.mat -> initial SNR labels (1-5)

%% caution
% if FWEc S29P has no data --> deal w/ this specific case
%%



%% only indiv for now


min_var = 0.7; max_var = 1;
for iroi = 1:numel(roi_list)
    active_all_zscored = cell(3,numel(subjects)); % 1 = all dvals per snr, 2 = mean per snr, 3 = std per snr
    passive_all_zscored = cell(3,numel(subjects));
    % load decoding_out file (contains model and decision_values)
    sbj = 0;
    for sbj_nb = subjects % do both active and passive for each
        sbj=sbj+1;
        %% 1/ active shit
        % decision values + true labels + decoding performance (AUC) -- stim (snr 2-5) vs no stim
        if sbj_nb < 10
            input_dir_tmp = [input_dir 'subj0' num2str(sbj_nb) '_active' roi_list{iroi} '/'];
        else
            input_dir_tmp = [input_dir 'subj' num2str(sbj_nb) '_active' roi_list{iroi} '/'];
        end
        if isfolder(input_dir_tmp)
            load([input_dir_tmp 'decoding_out.mat']);
            load([input_dir_tmp 'true_labels.mat']);
            load([input_dir_tmp 'res_AUC.mat']);

            dvals = []; preds = []; labels = [];
            for i = 1:size(decoding_out,2)
                dvals = [dvals; -decoding_out(i).decision_values];
            end

            % compute mean and std per SNR
            snr_dvals = cell(1,5);
            mean_across_trials = []; sd_across_trials = [];
            for isnr=1:5
                snr_dvals{isnr} = dvals(true_labels==isnr);
                mean_across_trials(isnr) = mean(snr_dvals{isnr});
                sd_across_trials(isnr) = std(snr_dvals{isnr});
            end

            % zscore across all SNRs for each subject
            z_dvals = (dvals - mean(dvals))/std(dvals);
            % re compute mean and std per SNR
            z_snr_dvals = cell(1,5);
            z_mean_across_trials = []; z_sd_across_trials = [];
            for isnr=1:5
                z_snr_dvals{isnr} = z_dvals(true_labels==isnr);
                z_mean_across_trials(isnr) = mean(z_snr_dvals{isnr});
                z_sd_across_trials(isnr) = std(z_snr_dvals{isnr});
            end

            % (optional: zscore but with SNR1 parameters : substract avgSNR1 and
            % divide by stdSNR1)
            zz_dvals = (dvals - mean_across_trials(1)/sd_across_trials(1));

            % rename everyone to be labelled ACTIVE
            active_dvals = dvals; clear dvals;
            active_snr_dvals = snr_dvals; clear snr_dvals;
            active_mean_snr = mean_across_trials; clear mean_across_trials;
            active_std_snr = sd_across_trials; clear sd_across_trials;
            active_z_dvals = z_dvals; clear z_dvals;
            active_z_snr_dvals = z_snr_dvals; clear snr_dvals;
            active_z_mean_snr = z_mean_across_trials; clear z_mean_across_trials;
            active_z_std_snr = z_sd_across_trials; clear z_sd_across_trials;
            active_auc = results.AUC.output; clear results;

            active_all_zscored{1,sbj} = active_z_snr_dvals;
            active_all_zscored{2,sbj} = active_z_mean_snr;
            active_all_zscored{3,sbj} = active_z_std_snr;
        else % empty folder because no activation
            active_all_zscored{1,sbj} = [];
            active_all_zscored{2,sbj} = [];
            active_all_zscored{3,sbj} = [];
        end


        %% 2/ passive
        % decision values + true labels + decoding performance (AUC) -- stim (snr 2-5) vs no stim
        if sbj_nb < 10
            input_dir_tmp = [input_dir 'subj0' num2str(sbj_nb) '_passive' roi_list{iroi} '/'];
        else
            input_dir_tmp = [input_dir 'subj' num2str(sbj_nb) '_passive' roi_list{iroi} '/'];
        end
        if isfolder(input_dir_tmp)
            load([input_dir_tmp 'decoding_out.mat']);
            load([input_dir_tmp 'true_labels.mat']);
            load([input_dir_tmp 'res_AUC.mat']);

            dvals = []; preds = []; labels = [];
            for i = 1:size(decoding_out,2) % 9 runs in general if active
                dvals = [dvals; -decoding_out(i).decision_values];
                %preds = [preds; decoding_out(i).predicted_labels];
                %labels = [labels; decoding_out(i).true_labels];
            end

            % compute mean and std per SNR
            snr_dvals = cell(1,5);
            mean_across_trials = []; sd_across_trials = [];
            for isnr=1:5
                snr_dvals{isnr} = dvals(true_labels==isnr);
                mean_across_trials(isnr) = mean(snr_dvals{isnr});
                sd_across_trials(isnr) = std(snr_dvals{isnr});
            end

            % zscore across all SNRs for each subject
            %z_dvals = zscore(dvals);
            z_dvals = (dvals - mean(dvals))/std(dvals);
            % re compute mean and std per SNR
            z_snr_dvals = cell(1,5);
            z_mean_across_trials = []; z_sd_across_trials = [];
            for isnr=1:5
                z_snr_dvals{isnr} = z_dvals(true_labels==isnr);
                z_mean_across_trials(isnr) = mean(z_snr_dvals{isnr});
                z_sd_across_trials(isnr) = std(z_snr_dvals{isnr});
            end

            % (optional: zscore but with SNR1 parameters : substract avgSNR1 and
            % divide by stdSNR1)
            % zz_dvals = (dvals - mean_across_trials(1)/sd_across_trials(1));

            % rename everyone to be labelled PASSIVE
            passive_dvals = dvals; clear dvals;
            passive_snr_dvals = snr_dvals; clear snr_dvals;
            passive_mean_snr = mean_across_trials; clear mean_across_trials;
            passive_std_snr = sd_across_trials; clear sd_across_trials;
            passive_z_dvals = z_dvals; clear z_dvals;
            passive_z_snr_dvals = z_snr_dvals; clear snr_dvals;
            passive_z_mean_snr = z_mean_across_trials; clear z_mean_across_trials;
            passive_z_std_snr = z_sd_across_trials; clear z_sd_across_trials;
            passive_auc = results.AUC.output; clear results;

            passive_all_zscored{1,sbj} = passive_z_snr_dvals;
            passive_all_zscored{2,sbj} = passive_z_mean_snr;
            passive_all_zscored{3,sbj} = passive_z_std_snr;
        else
            passive_all_zscored{1,sbj} = [];
            passive_all_zscored{2,sbj} = [];
            passive_all_zscored{3,sbj} = [];
        end


        %% 3/ figure with both - zscored

        %pts = -3:0.05:3;
        pts = -4:0.05:4;

        %var_interv = [0.5361;1.1195];

        % A/ active
        X = [-20, -11.5, -9.5, -7.5, -3];
        % I. distributions
        subplot(2,4,[1,2]); hold on;
        for isnr=1:5
            [f,xi] = ksdensity(active_z_snr_dvals{isnr},pts);
            plot(xi,f, "LineWidth",3,'Color', cols_snrA(isnr, :));
        end
        legend('No sound','Level 2','Level 3','Level 4','Level 5');
        %title(['Active ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(active_auc)]);
        if iroi == 1  % no A1
            title(['Active ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(active_auc) ' no A1'],'FontSize',20);
        else % A1
            title(['Active ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(active_auc) ' A1'],'FontSize',20);
        end

        ax = gca;                 
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        % II. mean for averaged data
        subplot(2,4,5); hold on;
        plot(X,active_z_mean_snr,'Color', 'black', LineStyle='-', LineWidth=2,  Marker='.', MarkerSize = 15) ;
        %xticklabels({'snr1', 'snr2', 'snr3', 'snr4', 'snr5'});
        %set(gca,'FontSize',11,'XTick',[-20, -11.5, -9.5, -7.5, -3],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
        set(gca,'FontSize',15,'XTick',[-20, -11.5, -9.5, -7.5, -3],'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
        xlabel('Intensity Levels (dB)','FontSize',15);
        ylabel('Mean Decision Value','FontSize',15);
        title('Average vs Intensity','FontSize',15);
        ax = gca;                 
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        % III. inter-trial standard deviation
        subplot(2,4,6); hold on;
        plot(X,active_z_std_snr, 'Color', 'black', LineStyle='-', LineWidth=2,  Marker='.', MarkerSize=15);
        %ylim([var_interv(1);var_interv(2)]);
        ylim([0.5 1.2]);
        %xticklabels({'snr1', 'snr2', 'snr3', 'snr4', 'snr5'});
        %set(gca,'FontSize',11,'XTick',[-20, -11.5, -9.5, -7.5, -3],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
        set(gca,'FontSize',15,'XTick',[-20, -11.5, -9.5, -7.5, -3],'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
        xlabel('Intensity Levels (dB)','FontSize',15);
        ylabel('Standard Deviation','FontSize',15);
        title('Inter-Trial Standard Deviation','FontSize',15);
        ax = gca;                 
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        % B/ passive
        X = [-20, -10, -7.5, -5, -1];
        % I. distributions
        subplot(2,4,[3,4]); hold on;
        for isnr=1:5
            [f,xi] = ksdensity(passive_z_snr_dvals{isnr},pts);
            plot(xi,f, "LineWidth",3,'Color', cols_snrP(isnr, :));
        end
        %legend('snr1','snr2','snr3','snr4','snr5');
        legend('No sound','Level 2','Level 3','Level 4','Level 5');
        %title(['Passive ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(passive_auc)]);
        if iroi == 1  % no A1
            title(['Passive ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(passive_auc) ' no A1'],'FontSize',20);
        else % A1
            title(['Passive ZSCORED - subj ' num2str(sbj_nb) ' - AUC: ' num2str(passive_auc) ' A1'],'FontSize',20);
        end
        ax = gca;                 
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        % II. mean for averaged data
        subplot(2,4,7); hold on;
        plot(X,passive_z_mean_snr,'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize = 15);
        %set(gca,'FontSize',11,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
        set(gca,'FontSize',15,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
        %xticklabels({'snr1', 'snr2', 'snr3', 'snr4', 'snr5'});
        xlabel('Intensity Levels (dB)','FontSize',15);
        ylabel('Mean Decision Value','FontSize',15);
        title('Average vs Intensity','FontSize',15);
        ax = gca;
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        % III. inter-trial standard deviation
        subplot(2,4,8); hold on;
        plot(X,passive_z_std_snr, 'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize=15);
        %ylim([var_interv(1);var_interv(2)]);
        ylim([0.5 1.2]);
        %xticklabels({'snr1', 'snr2', 'snr3', 'snr4', 'snr5'});
        %set(gca,'FontSize',11,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
        set(gca,'FontSize',15,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
        xlabel('Intensity Levels (dB)','FontSize',15);
        ylabel('Standard Deviation','FontSize',15);
        title('Inter-Trial Standard Deviation','FontSize',15);

        ax = gca;                 
        ax.FontSize = 20;        
        ax.XLabel.FontSize = 22;  
        ax.YLabel.FontSize = 22;

        set(gcf,'Position',[1 48 1512 818]);
        saveas(gcf,[output_dir 'subj' num2str(sbj_nb) roi_list{iroi} '_zscored_fixedVarAxis_2.png']);
        close(gcf);



    end

    % save data for group plots
    %save([output_dir roi_list{iroi} 'active_all_zscored.mat'], 'active_all_zscored');
    %save([output_dir roi_list{iroi} 'passive_all_zscored.mat'], 'passive_all_zscored');
end
%% group avg (only zscored values)

clear; close all; clc;

input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI2/unc001/';
output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI2/unc001/decision_values_prettier_3/';
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


subjects = [2 3 4 5 6 7 8 10 12 13 14 15 18 19 20 21 23 24 25 26 27 28 30 32]; % no 9 22 29 for A1 only ...
%subjects = [10];
roi_list = {'_NoA1_thr10','_A1_thr10'};

iroi = 1; % no A1
%iroi = 2; % only A1
load([output_dir roi_list{iroi} 'active_all_zscored.mat']);
load([output_dir roi_list{iroi} 'passive_all_zscored.mat']);


%% Active grp
X = [-20, -11.5, -9.5, -7.5, -3]; pts = -3.5:0.05:3.5;
active_all_snr = {};
active_all_mean_snr = [];
active_all_std_snr = [];

active_all_sem_mean_snr = zeros(1,5);
active_all_sem_std_snr  = zeros(1,5);

for j = 1:5
    meta_tmp = [];

    subj_mean = nan(1,numel(subjects));
    subj_std  = nan(1,numel(subjects));

    for i = 1:numel(subjects)
        tmp = cell2mat(active_all_zscored{1,i}(j));
        meta_tmp = [meta_tmp tmp'];

        % subject-level measures
        subj_mean(i) = mean(tmp,'omitmissing');
        subj_std(i)  = std(tmp,'omitmissing');

    end
    % group mean/std (across pooled trials, not used for SEM)
    active_all_snr{j} = meta_tmp;
    active_all_mean_snr(j) = mean(meta_tmp,'omitmissing');
    active_all_std_snr(j) = std(meta_tmp,'omitmissing');

    % SEM across subjects (for errorbars)
    active_all_sem_mean_snr(j) = std(subj_mean,'omitmissing') / sqrt(numel(subjects));
    active_all_sem_std_snr(j)  = std(subj_std,'omitmissing') / sqrt(numel(subjects));

end

% I. distrib
subplot(2,2,1); hold on;
for isnr=1:5
    [f,xi] = ksdensity(active_all_snr{isnr},pts);
    plot(xi,f, "LineWidth",3,'Color', cols_snrA(isnr, :));
end
%title(['active group distrib - ' roi_list{iroi}]);
%legend('No sound','Level 2','Level 3','Level 4','Level 5','FontSize',17);
% if iroi == 1  % no A1
%     title('Active - group - no Heschl','FontSize',20);
% else % A1
%     title('Active - group - only Heschl','FontSize',20);
% end
title('Single-trial values distribution', 'Fontsize',20)
xlabel('Group averaged Z-scored decision values','FontSize',20)
ylabel('Probability density','FontSize',20)

ax = gca;
ax.FontSize = 20;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;

% II. avg
subplot(2,2,3); hold on;
%plot(X,active_all_mean_snr,'Color', 'black', LineStyle='-', LineWidth=1.5, Marker='.', MarkerSize = 20);
errorbar(X,active_all_mean_snr,active_all_sem_mean_snr,'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize = 10);
set(gca,'FontSize',15,'XTick',X,'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
xlabel('Intensity Levels (dB)','FontSize',20);
ylabel('Mean Decision Value','FontSize',20);
title('Average vs Intensity level','FontSize',20);

ax = gca;
ax.FontSize = 18;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;
xtickangle(45)

% III. std
subplot(2,2,4); hold on;
%plot(X,active_all_std_snr,'Color', 'black', LineStyle='-', LineWidth=1.5, Marker='.', MarkerSize = 20);
errorbar(X,active_all_std_snr,active_all_sem_std_snr,'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize = 10);
ylim([0.7;1]);
set(gca,'FontSize',15,'XTick',X,'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
xlabel('Intensity Levels','FontSize',20);
ylabel('Standard deviation','FontSize',20);
title('Inter-trial variability vs Intensity level','FontSize',20);

ax = gca;
ax.FontSize = 18;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;
xtickangle(45)

if iroi == 1  % no A1
    sgtitle('Active - group - no Heschl','FontSize',25);
else % A1
    sgtitle('Active - group - only Heschl','FontSize',25);
end

set(gcf,'Position',[1 48 1512 818]);
hold off;

%% Passive grp

X = [-20, -10, -7.5, -5, -1]; pts = -3:0.05:3;

passive_all_snr = {};
passive_all_mean_snr = [];
passive_all_std_snr = [];

passive_all_sem_mean_snr = zeros(1,5);
passive_all_sem_std_snr  = zeros(1,5);

for j = 1:5
    meta_tmp = [];

    subj_mean = nan(1,numel(subjects));
    subj_std  = nan(1,numel(subjects));

    for i = 1:numel(subjects)
        tmp = cell2mat(passive_all_zscored{1,i}(j));
        meta_tmp = [meta_tmp tmp'];

        % subject-level measures
        subj_mean(i) = mean(tmp,'omitmissing');
        subj_std(i)  = std(tmp,'omitmissing');

    end
    passive_all_snr{j} = meta_tmp;
    passive_all_mean_snr(j) = mean(meta_tmp,'omitmissing');
    passive_all_std_snr(j) = std(meta_tmp,'omitmissing');

    % SEM across subjects (for errorbars)
    passive_all_sem_mean_snr(j) = std(subj_mean,'omitmissing') / sqrt(numel(subjects));
    passive_all_sem_std_snr(j)  = std(subj_std,'omitmissing') / sqrt(numel(subjects));

end

% I. distrib
subplot(2,2,1); hold on;
for isnr=1:5
    [f,xi] = ksdensity(passive_all_snr{isnr},pts);
    plot(xi,f, "LineWidth",3,'Color', cols_snrP(isnr, :));
end
%title(['passive group distrib - ' roi_list{iroi}]);
%legend('No sound','Level 2','Level 3','Level 4','Level 5','FontSize',17);
% if iroi == 1  % no A1
%     title('Passive - group - no Heschl','FontSize',25);
% else % A1
%     title('Passive - group - only Heschl','FontSize',25);
% end
title('Single-trial values distribution', 'Fontsize',20)

xlabel('Group averaged Z-scored decision values','FontSize',20)
ylabel('Probability density','FontSize',20)

ax = gca;
ax.FontSize = 20;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;

% II. avg
subplot(2,2,3); hold on;
%plot(X,passive_all_mean_snr,'Color', 'black', LineStyle='--', LineWidth=1, Marker='.', MarkerSize = 15);
errorbar(X,passive_all_mean_snr,passive_all_sem_mean_snr,'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize = 10);
set(gca,'FontSize',15,'XTick',X,'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
xlabel('Intensity Levels (dB)','FontSize',20);
ylabel('Mean Decision Value','FontSize',20);
title('Average vs Intensity level','FontSize',20);

ax = gca;
ax.FontSize = 18;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;
xtickangle(45)

% III. std
subplot(2,2,4); hold on;
%plot(X,passive_all_std_snr,'Color', 'black', LineStyle='--', LineWidth=1, Marker='.', MarkerSize = 15);
errorbar(X,passive_all_std_snr,passive_all_sem_std_snr,'Color', 'black', LineStyle='-', LineWidth=2, Marker='.', MarkerSize = 10);
ylim([0.7;1]);
set(gca,'FontSize',15,'XTick',X,'XTickLabel',{'No sound'; 'Level 2'; 'Level 3'; 'Level 4'; 'Level 5'});
xlabel('Intensity Levels (dB)','FontSize',20);
ylabel('Standard deviation','FontSize',20);
title('Inter-trial variability vs Intensity level','FontSize',20);

ax = gca;
ax.FontSize = 18;
ax.XLabel.FontSize = 22;
ax.YLabel.FontSize = 22;
xtickangle(45)

if iroi == 1  % no A1
    sgtitle('Passive - group - no Heschl','FontSize',25);
else % A1
    sgtitle('Passive - group - only Heschl','FontSize',25);
end

set(gcf,'Position',[1 48 1512 818]);
disp('pause');

%end
