%% plotting pupil time course - soundfmri data
% J Boyer 2026 - SNR vs Smallest T-tests
%% setup
clear; clc; close all;
addpath('/Applications/fieldtrip-20240916');
ft_defaults;
addpath('/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/functions/');

conditions = {'active','passive'};
plots = {'snr','hnoth'};
nSNR = 5;
snr3_subjs = [2 3 5 6 8 9 10 12 14 15 19 20 21 22 25 29 32];
snr4_subjs = [4 7 13 18 23 24 26 27 28 30];

cols = [0 0.6 0; 0.7 0 0]; 
cols_snrA = [0.2 0.05 0.42; 0.05 0.36 0.81; 0.15 0.9 0.9; 0 1 0; 1 0.34 0.24];
cols_snrP = [0.2 0.05 0.42; 0.15 0.9 0.9; 0 1 0; 1 0.53 0; 0.6353 0.0784 0.1843];

%% parameters
HPfilter = 0; 
twindow = [-1 5];
bsl_methods = {'rmSNR1','bridge1'}; 

for iplot_idx = 1:numel(plots)
    iplot = plots{iplot_idx};
    
    for icon_idx = 1:numel(conditions)
        icon = conditions{icon_idx};
        inputdir = '/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/results/preprocessed_2026/';
        
        subjects = iif(strcmp(icon,'active'), ...
            [2 3 4 5 6 7 8  10 12 13 14 15 19 20 21 22 23 24 26 27 28 29 30], ...
            [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 24 26 27 28 29 30 32]);
        
        condData = iif(strcmp(iplot,'snr'), cell(nSNR, 1), cell(2, 1));

        for isubj = subjects
            fname = [inputdir icon '_' num2str(isubj) '_HPfilter' num2str(HPfilter) '_' num2str(twindow(1)) '_' num2str(twindow(end)) '.mat'];
            if ~exist(fname, 'file'), continue; end
            load(fname);
            
            subj_threshold_snr = iif(ismember(isubj, snr3_subjs), 3, 4);
            cfg = []; cfg.channel = 'EyePupil';
            data = ft_selectdata(cfg, data);
            time = data.time{1};
            
            cfg_tl = []; cfg_tl.keeptrials = 'yes';
            tl = ft_timelockanalysis(cfg_tl, data);
            pupil = squeeze(tl.trial);

            %% --- 1. DETRENDING ---
            if ismember('bridge1', bsl_methods)
                bidx = (time >= -0.5 & time <= 0); eidx = (time >= 4.5 & time <= 5.0);
                for tr = 1:size(pupil, 1)
                    v_start = mean(pupil(tr, bidx), 'omitnan');
                    v_end = mean(pupil(tr, eidx), 'omitnan');
                    pupil(tr,:) = pupil(tr,:) - linspace(v_start, v_end, length(time));
                    pupil(tr,:) = pupil(tr,:) - mean(pupil(tr, bidx), 'omitnan');
                end
            end

            %% --- 2. STORAGE ---
            idx_snr1 = (data.trialinfo(:,1) == 1);
            subj_noise_trace = mean(pupil(idx_snr1,:), 1, 'omitnan');

            if strcmp(iplot,'snr')
                for s = 1:nSNR
                    idx = (data.trialinfo(:,1) == s);
                    if any(idx)
                        m_tr = mean(pupil(idx,:), 1, 'omitnan');
                        condData{s}(end+1,:) = iif(ismember('rmSNR1', bsl_methods), m_tr - subj_noise_trace, m_tr);
                    end
                end
            else
                if strcmp(icon,'active')
                    idx_h = (data.trialinfo(:,5) > 1 & data.trialinfo(:,1) == subj_threshold_snr);
                    idx_nh = (data.trialinfo(:,5) == 1 & data.trialinfo(:,1) == subj_threshold_snr);
                else
                    idx_h = (data.trialinfo(:,6) == 1 & data.trialinfo(:,1) > 1);
                    idx_nh = (data.trialinfo(:,6) == 0 & data.trialinfo(:,1) > 1);
                end
                if any(idx_h) && any(idx_nh)
                    condData{1}(end+1,:) = iif(ismember('rmSNR1', bsl_methods), mean(pupil(idx_h,:),1,'omitnan') - subj_noise_trace, mean(pupil(idx_h,:),1,'omitnan'));
                    condData{2}(end+1,:) = iif(ismember('rmSNR1', bsl_methods), mean(pupil(idx_nh,:),1,'omitnan') - subj_noise_trace, mean(pupil(idx_nh,:),1,'omitnan'));
                end
            end
        end

        %% --- 3. PLOTTING ---
        % WIDER ASPECT RATIO
        figure('Color','w','Position',[100 100 1100 1500]); hold on;
        current_cols = iif(strcmp(iplot,'snr'), iif(strcmp(icon,'active'), cols_snrA, cols_snrP), cols);
        start_s = iif(strcmp(iplot,'snr') && ismember('rmSNR1', bsl_methods), 2, 1);
        
        for i = start_s:numel(condData)
            if isempty(condData{i}), continue; end
            m = movmean(mean(condData{i}, 1, 'omitnan'), 25);
            sem = std(condData{i}, [], 1, 'omitnan') ./ sqrt(size(condData{i},1));
            fill([time fliplr(time)], [m+sem fliplr(m-sem)], current_cols(i,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(time, m, 'Color', current_cols(i,:), 'LineWidth', 3);
        end

        %% --- 4. STATISTICS & BARS ---
        %y_lims = ylim; 
        %sig_base_y = y_lims(1) + 0.05 * diff(y_lims); % Start bars just above the bottom
        if strcmp(iplot,'snr')
            ylim([-0.2 0.6]); % UNIFIED Y-AXIS
        else
            ylim([-0.2 0.4]); % UNIFIED Y-AXIS
        end
        sig_base_y = -0.16; % Higher from the very bottom

        if strcmp(iplot,'snr')
            % Compare each SNR against the smallest one (start_s)
            % baseline_data = condData{start_s};
            bar_offset = 0; 
            for i = (start_s + 1):nSNR
                if isempty(condData{i}), continue; end
                %[~, p_vals] = ttest(condData{i}, baseline_data); MODIF
                %180426
                if ismember('rmSNR1', bsl_methods)
                    % Test if the subtracted trace is significantly different from 0
                    [~, p_vals] = ttest(condData{i});
                else
                    % Test if the trace is significantly different from SNR 1
                    [~, p_vals] = ttest(condData{i}, condData{1});
                end
                sig_mask = p_vals < 0.05 & time > 0;

                % Plot color-coded dots for significance
                if any(sig_mask)
                    % plot(time(sig_mask), (sig_base_y + bar_offset)*ones(1, sum(sig_mask)), '.', ...
                    %     'Color', current_cols(i,:), 'MarkerSize', 8, 'HandleVisibility', 'off');
                    % bar_offset = bar_offset + 0.02 * diff(y_lims); % Shift next bar up
                    % Plotting as a thick line for "wider" appearance
                    plot(time(sig_mask), (sig_base_y + bar_offset)*ones(1, sum(sig_mask)), '-', ...
                        'Color', current_cols(i,:), 'LineWidth', 6);
                    bar_offset = bar_offset + 0.04;
                end
            end
        else % Heard vs Not Heard Paired T-test
            [~, p_vals] = ttest(condData{1}, condData{2});
            sig_mask = p_vals < 0.05 & time > 0;
            if any(sig_mask)
                % plot(time(sig_mask), sig_base_y*ones(1, sum(sig_mask)), '.', ...
                %    'Color', [0.5 0.5 0.5], 'MarkerSize', 8, 'HandleVisibility', 'off');
                plot(time(sig_mask), sig_base_y*ones(1, sum(sig_mask)), '-', ...
                    'Color', [0.4 0.4 0.4], 'LineWidth', 6);
            end

        end
        
        xlabel('Time (s)'); ylabel('Pupil (a.u.)'); %title([upper(icon) ' - ' upper(iplot)]);
        yline(0, 'k--'); xline(0, 'k-'); %axis tight;
        %set(findall(gcf,'-property','FontSize'), 'FontSize', 26);
        set(gca, 'FontSize', 22);
        hold off;
        if strcmp(icon,'active') && strcmp(iplot,'hnoth')
            lgd = legend({'Heard','Not heard'},'Fontsize',20,'Box','off');
            lgd.Title.String = 'Audibility rating:';
            %lgd.Title.Fontsize = 20;
        elseif  strcmp(icon,'passive') && strcmp(iplot,'hnoth')
            lgd = legend({'Sound','Other'},'Fontsize',20,'Box','off');
            lgd.Title.String = 'Mind-wandering response:';
            %lgd.Title.Fontsize = 20;
        end
        saveas(gcf,['stats_' upper(icon) ' - ' upper(iplot) '5.png'])
    end
end

function val = iif(condition, trueVal, falseVal)
    if condition, val = trueVal; else, val = falseVal; end
end