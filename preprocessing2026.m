% PUPIL PREPROCESSING
% j boyer 2026 (a urai 2016)

%% fixed order
% Interpolate/Clean blinks first (using the raw data)
% Apply High-Pass filter to the continuous, "smooth" pupil trace
% Regress out residuals (if still using blink_regressout)
% Z-score and Epoch.

%% to do next: epoch to fixpoint to investigate pre stim drift
% must create new trialfun.m functions for that

%% setup
clear; clc; close all;
addpath('/Applications/fieldtrip-20240916');
ft_defaults;
addpath('/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/functions/');
edf2ascPath = '/Users/julieboyer/Desktop/edf2asc-mac';

conditions = {'active','passive'};
%conditions = {'passive'};
datafolder = '/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/data_pupil/';
outputdir = '/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/results/preprocessed_2026/';

if ~isfolder(outputdir); mkdir(outputdir); end

%% parameters:
HPfilter = 0;
twindow = [-1 5];

%% loop across conditions and subjects
for icon = conditions
    act = false; pass = false; 
    if strcmp(icon,'active')
        subjects = [2:8 10 12:15 19:24 26:30];
        %subjects = [15 19:24 26:30];
        act = true; 
        missings = [12 15 19 20 24 28];
        relous = [28];
        merged = [];
    else
        subjects = [2:10 12:15 18:22 24 26:30 32]; % DO 12 /13
        %subjects = [13];
        pass = true; 
        missings = [5 12 13 19:22 24 29:32];
        relous = [12 13 20 24 29 30 32];
        merged = [12 13];
    end

    for isubj = subjects
        %% load behav data
        if act
            behav_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/';
            behav_dir = dir(behav_folder);
        elseif pass
            behav_folder = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/';
            behav_dir = dir(behav_folder);
        end
        for ii = 1:numel(behav_dir)
            tmp = behav_dir(ii).name;
            if ~isfolder(tmp)
                if contains(tmp,sprintf('Subject_%i',isubj))
                    behav_path = [behav_folder tmp];
                end
            end
        end

        %% merge if necessary
        if ismember(isubj,merged)
            asc1 = read_eyelink_ascNK_AU([datafolder 'cp' num2str(isubj) '_1.asc']);
            asc2 = read_eyelink_ascNK_AU([datafolder 'cp' num2str(isubj) '_2.asc']);
            asc = merge_eyelink_asc(asc1, asc2);
        else
            if act
                asc_file = [datafolder 'ca' num2str(isubj) '.asc'];
            elseif pass
                asc_file = [datafolder 'cp' num2str(isubj) '.asc'];
            end
            asc = read_eyelink_ascNK_AU(asc_file);
        end

        %% create fieldtrip structure and all
        
        [data, event, blinksmp, saccsmp] = asc2dat(asc);
        % Store RAW for the QC plot later
        raw_pupil = data.trial{1}(find(strcmp(data.label, 'EyePupil')==1),:);

        %% Calculate Blink Stats
        % Total samples / samples marked as blinks
        blink_prop = (sum(blinksmp(:,2) - blinksmp(:,1))) / length(raw_pupil);
        fprintf('Subject %d: %.2f%% samples are blinks\n', isubj, blink_prop*100);

        %% interpolate Eyelink-defined and additionally detected blinks
        plotMe = false;
        newpupil = blink_interpolate(data, blinksmp, plotMe);
        data.trial{1}(find(strcmp(data.label, 'EyePupil')==1),:) = newpupil;

        %% high pass filtering to prevent slow drift from contaminating all ERPs
        if HPfilter ~= 0
            cfg = [];
            cfg.hpfilter = 'yes';
            cfg.hpfreq = HPfilter;
            cfg.hpfiltord = 1; % Force a lower order to ensure stability
            data = ft_preprocessing(cfg, data);
        end

        %% regress out blink- and saccade-linked pupil response
        data = blink_regressout(data, blinksmp, saccsmp, plotMe, 0);

        %% zscore since we work with the bandpassed signal
        final_pupil = zscore(data.trial{1}(find(strcmp(data.label, 'EyePupil')==1),:));
        data.trial{1}(find(strcmp(data.label, 'EyePupil')==1),:) = final_pupil;

        %% QC PLOT: Before vs After
        fig = figure('visible','off'); % Don't pop up 100 windows
        subplot(2,1,1);
        plot(raw_pupil, 'Color', [0.7 0.7 0.7]); hold on;
        title(['Subject ' num2str(isubj) ' Raw Pupil (Blinks present)']);
        ylabel('Raw Area');
        
        subplot(2,1,2);
        plot(final_pupil, 'b');
        title(['Preprocessed (Interpolated + ' num2str(HPfilter) 'Hz HP + Z-score)']);
        ylabel('Z-score');
        xlabel('Samples');
        
        % Save PNG
        print(fig, [outputdir 'QC_' char(icon) '_' num2str(isubj) '.png'], '-dpng');
        close(fig);

        %% epoch using a custom trial-definition function
        % define trials
        cfg                         = [];
        cfg.behavpath               = behav_path;
        if ismember(isubj,merged)
            cfg.asc1 = asc1;
            cfg.asc2 = asc2;
        else
            cfg.dataset                 = asc_file;
        end
        cfg.event                   = event;
        if ismember(isubj,missings)
            if ismember(isubj,relous) % must individualize more
                if act
                    cfg.subj_id = [num2str(isubj) 'A'];
                else
                    cfg.subj_id = [num2str(isubj) 'P'];
                end
            end
            if act
                cfg.trialfun                = 'my_trialfun2026active_missing';
            elseif pass
                cfg.trialfun                = 'my_trialfun2026passive_missing';
            end
        else
            if act
                cfg.trialfun                = 'my_trialfun2026active';
            elseif pass
                cfg.trialfun                = 'my_trialfun2026passive';
            end
        end
        cfg.trialdef.pre            = twindow(1);
        cfg.trialdef.post           = twindow(end);
        cfg.fsample                 = asc.fsample;
        cfg                         = ft_definetrial(cfg);
        data                        = ft_redefinetrial(cfg, data);

        %% downsample before saving
        cfg             = [];
        cfg.resamplefs  = 100;
        cfg.fsample     = data.fsample;

        samplerows = find(data.trialinfo(1,:)>100); % indices of the rows with sample values (and not event codes)
        data.trialinfo(:,samplerows) = round(data.trialinfo(:,samplerows) * (cfg.resamplefs/cfg.fsample));

        %% use fieldtrip to resample
        data    = ft_resampledata(cfg, data);

        filename_mat = cell2mat([outputdir icon '_' num2str(isubj) '_HPfilter' num2str(HPfilter) '_' num2str(twindow(1)) '_' num2str(twindow(end)) '.mat']);
        save(filename_mat, 'data','blink_prop');
    end
end
