% PUPIL PREPROCESSING
% j boyer 2026 (a urai 2016)

% REQUIRES FIELDTRIP TOOLBOX

%% fixed order
% Interpolate/Clean blinks first (using the raw data)
% Apply High-Pass filter to the continuous, "smooth" pupil trace
% Regress out residuals (if still using blink_regressout)
% Z-score and Epoch.

%% input = indiv .asc eyelink files (ca1.asc for active condition subject 1, cp1.asc for passive condition subject 1, etc.)
%% output = .mat files with pre-processed data

%% setup
clear; clc; close all;
addpath('/Applications/fieldtrip-20240916');
ft_defaults;
addpath('/Volumes/DisqueJulie/JulieBoyer2025/pupil_2025/functions/');
edf2ascPath = '/Users/julieboyer/Desktop/edf2asc-mac';

conditions = {'active','passive'};

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


%% HELPER FUNCTIONS 

function [trl, event] = my_trialfun2026active(cfg)

% header and events are already in the asc structures
% Anne Urai, 2016 / fieldtrip / j Boyer 2025 for soundfmri
% it is the trialfun called by FT function ft_definetrial.m

event   = cfg.event;
value   = {event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).value};
sample  = [event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).sample];

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * cfg.fsample);
posttrig =  round(cfg.trialdef.post * cfg.fsample);

%% collect all events of interest for those that appear for each trial
% indices
trialstart = contains(value,'trial_start');
auditstim = contains(value,'auditory');
vowel = contains(value,'vowel');
audib = contains(value,'audibility');
snr_num = contains(value,'snr_num');
trialend = contains(value,'end of trial');

% check they all have the same number of occurence
total_trials = numel(value(trialstart));

if ~isequal(total_trials,numel(value(auditstim)))
    error('auditstim ≠ trialstart')
end

if ~isequal(total_trials,numel(value(audib)))
    error('audib ≠ trialstart')
end

if ~isequal(total_trials,numel(value(vowel)))
    error('vowel ≠ trialstart')
end

if ~isequal(total_trials,numel(value(snr_num)))
    error('snr_num ≠ trialstart')
end

if ~isequal(total_trials,numel(value(trialend)))
    error('trialend ≠ trialstart')
end

% load behav data
load(cfg.behavpath); % -> trials table

if ~isequal(total_trials,max(trials.trial))
    error('mismatch between behav and pupil trial nb');
end

if ~isequal(total_trials,440) && ~isequal(total_trials,450)
    disp('Warning: not standard number of trials --> check it manually!');
end

trl = [];

sample_auditstim = sample(auditstim);
% for pre stim analyses : sample_trialstart = sample(trialstart);
value_snrnum = value(snr_num);
value_vowelnum = value(vowel);
value_audib = value(audib);

% loop across trials
for itrial = 1:total_trials

    % trlbegin, trlend, offset -> get sample for audit stim
    sample = sample_auditstim(itrial); % OR sample = sample_trialstart(itrial);
    trlbegin = sample - pretrig;
    trlend = sample + posttrig;
    offset = - pretrig;

    % snrnum, vowelnum
    msgsnr = value_snrnum(itrial);
    snr_num = str2double(extractBetween(msgsnr,'snr_num = ',','));
    msgvow = value_vowelnum(itrial);
    vowel_num = str2double(extractBetween(msgvow,'vowel = ',','));
    % sanity check
    snr_num_check = trials.snr_num(itrial);
    vowel_num_check = trials.stimulus_num(itrial);
    if ~isequal(snr_num,snr_num_check) || ~isequal(vowel_num,vowel_num_check)
        error('mismatch behav / pupil')
    end
    

    % trlcnt (in block), blockcnt
    trlcnt = trials.trial_in_block(itrial);
    blockcnt = trials.block(itrial);

    % audibility
    msgaudib = value_audib(itrial);
    audib = str2double(extractBetween(msgaudib,'audibility = ',','));
    % sanity check
    audib_check = trials.audib(itrial);
    if ~isequal(audib,audib_check) && ~isnan(audib_check) % if nan it's fine
        error('mismatch behav / pupil')
    end
    if isnan(audib_check) && ~isnan(audib)
        error('mismatch behav / pupil -- NaN situation')
    end

    newtrl = [trlbegin trlend offset snr_num vowel_num trlcnt blockcnt audib];

    trl = [trl; newtrl];

end

function [trl, event] = my_trialfun2026active_missing(cfg)

% header and events are already in the asc structures
% Anne Urai, 2016 / fieldtrip / j Boyer 2025 for soundfmri
% it is the trialfun called by FT function ft_definetrial.m
caca = false; 
skip = false; 

% blocks shitshow
if isfield(cfg,'subj_id')
    caca = true; 
end

event   = cfg.event;
value   = {event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).value};
sample  = [event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).sample];

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * cfg.fsample);
posttrig =  round(cfg.trialdef.post * cfg.fsample);

%% collect all events of interest for those that appear for each trial
% indices
trialstart = contains(value,'trial_start');
auditstim = contains(value,'auditory');
vowel = contains(value,'vowel');
audib = contains(value,'audibility');
snr_num = contains(value,'snr_num');
trialend = contains(value,'end of trial');

% check they all have the same number of occurence
total_trials = numel(value(trialstart));

% load behav data
load(cfg.behavpath); % -> trials table

trl = [];

sample_auditstim = sample(auditstim);
value_snrnum = value(snr_num);
value_vowelnum = value(vowel);
value_audib = value(audib);

% loop across trials

for itrial = 1:(total_trials - 1)
    % trlbegin, trlend, offset -> get sample for audit stim
    sample = sample_auditstim(itrial);
    trlbegin = sample - pretrig;
    trlend = sample + posttrig;
    offset = - pretrig;
    % snrnum, vowelnum
    msgsnr = value_snrnum(itrial);
    snr_num = str2double(extractBetween(msgsnr,'snr_num = ',','));
    msgvow = value_vowelnum(itrial);
    vowel_num = str2double(extractBetween(msgvow,'vowel = ',','));
    % audibility
    msgaudib = value_audib(itrial);
    audib = str2double(extractBetween(msgaudib,'audibility = ',','));
    % sanity check
    if caca == 1 % blocks shitshow
        sbj = cfg.subj_id;
        % define ii
        if strcmp(sbj,'28A')
            ii = itrial + 300;
        elseif strcmp(sbj,'12P')
            if itrial < 201
                ii = itrial;
            else
                ii = itrial + 320;
            end
        elseif strcmp(sbj,'13P')
            if itrial < 241
                ii = itrial;
            elseif itrial > 240 && itrial < 247
                skip = true; % extra trials to remove: 241 242 243 244 245 246
            elseif itrial > 246
                ii = itrial - 6;
            end
        elseif strcmp(sbj,'20P')
            ii = itrial + 280;
        elseif strcmp(sbj,'24P')
            ii = itrial + 240;
        elseif strcmp(sbj,'29P')
            ii = itrial + 200;
        elseif strcmp(sbj,'30P') || strcmp(sbj,'32P')
            ii = itrial + 360;
        end
    else
        ii = itrial;
    end
    if skip == false
        snr_num_check = trials.snr_num(ii);
        vowel_num_check = trials.stimulus_num(ii);
        if ~isequal(snr_num,snr_num_check) || ~isequal(vowel_num,vowel_num_check)
            error('mismatch behav / pupil')
        end
        audib_check = trials.audib(ii);
        if ~isequal(audib,audib_check) && ~isnan(audib_check) % if nan it's fine
            error('mismatch behav / pupil')
        end
        if isnan(audib_check) && ~isnan(audib)
            error('mismatch behav / pupil -- NaN situation')
        end
        blockcnt = trials.block(ii);
        trlcnt = itrial;
        newtrl = [trlbegin trlend offset snr_num vowel_num trlcnt blockcnt audib];
        trl = [trl; newtrl];
    end
end

function [trl, event] = my_trialfun2026passive(cfg)

% header and events are already in the asc structures
% Anne Urai, 2016 / fieldtrip / j Boyer 2025 for soundfmri
% it is the trialfun called by FT function ft_definetrial.m

event   = cfg.event;
value   = {event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).value};
sample  = [event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).sample];

% nb in event we have:
% - type: 'question', 'keypress', etc.
% - sample: value for sample timepoint of eyelink corresponding to the
% event
% - value: full message, also gives info about trial nb, eg 'MSG	3250633	question, trial 23 / 40 _ block 0 / 10'


% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * cfg.fsample);
posttrig =  round(cfg.trialdef.post * cfg.fsample);


%% collect all events of interest for those that appear for each trial
% indices
trialstart = contains(value,'trial_start');
auditstim = contains(value,'auditory');
question = contains(value,'question');
vowel = contains(value,'vowel');
snr_num = contains(value,'snr_num');
trialend = contains(value,'end of trial');

% check they all have the same number of occurence
total_trials = numel(value(trialstart));

if ~isequal(total_trials,numel(value(auditstim)))
    error('auditstim ≠ trialstart')
end

if ~isequal(total_trials,numel(value(question)))
    error('question ≠ trialstart')
end

if ~isequal(total_trials,numel(value(vowel)))
    error('vowel ≠ trialstart')
end

if ~isequal(total_trials,numel(value(snr_num)))
    error('snr_num ≠ trialstart')
end

if ~isequal(total_trials,numel(value(trialend)))
    error('trialend ≠ trialstart')
end

% load behav data
load(cfg.behavpath); % -> trials table

if ~isequal(total_trials,max(trials.trial))
    error('mismatch between behav and pupil trial nb');
end


trl = [];

sample_auditstim = sample(auditstim);
value_snrnum = value(snr_num);
value_vowelnum = value(vowel);

% loop across trials
for itrial = 1:total_trials
    % trlbegin, trlend, offset -> get sample for audit stim
    sample = sample_auditstim(itrial);
    trlbegin = sample - pretrig;
    trlend = sample + posttrig;
    offset = - pretrig;
    % snrnum, vowelnum
    msgsnr = value_snrnum(itrial);
    snr_num = str2double(extractBetween(msgsnr,'snr_num = ',','));
    msgvow = value_vowelnum(itrial);
    vowel_num = str2double(extractBetween(msgvow,'vowel = ',','));
    % sanity check
    snr_num_check = trials.snr_num(itrial);
    vowel_num_check = trials.stimulus_num(itrial);
    if ~isequal(snr_num,snr_num_check) || ~isequal(vowel_num,vowel_num_check)
        error('mismatch behav / pupil')
    end
    % trlcnt (in block), blockcnt
    trlcnt = trials.trial_in_block(itrial);
    blockcnt = trials.block(itrial);
    % question_type, HnotH
    question_type = trials.question_num(itrial);
    if question_type == 3 % mindwander
        if trials.answer_num(itrial) == 1 % sound
            HnotH = 1; % heard
        else
            HnotH = 0; % not heard
        end
    else
        HnotH = NaN; % not probed
    end
    newtrl = [trlbegin trlend offset snr_num vowel_num trlcnt blockcnt question_type HnotH];
    trl = [trl; newtrl];
end

function [trl, event] = my_trialfun2026passive_missing(cfg)

% header and events are already in the asc structures
% Anne Urai, 2016 / fieldtrip / j Boyer 2025 for soundfmri
% it is the trialfun called by FT function ft_definetrial.m

caca = false; 
skip = false; 

% blocks shitshow
if isfield(cfg,'subj_id')
    caca = true; 
end

event   = cfg.event;
value   = {event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).value};
sample  = [event(find(~cellfun(@isempty,strfind({event.value},'MSG')))).sample];

% nb in event we have:
% - type: 'question', 'keypress', etc.
% - sample: value for sample timepoint of eyelink corresponding to the
% event
% - value: full message, also gives info about trial nb, eg 'MSG	3250633	question, trial 23 / 40 _ block 0 / 10'


% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * cfg.fsample);
posttrig =  round(cfg.trialdef.post * cfg.fsample);


%% collect all events of interest for those that appear for each trial
% indices
trialstart = contains(value,'trial_start');
auditstim = contains(value,'auditory');
question = contains(value,'question');
vowel = contains(value,'vowel');
snr_num = contains(value,'snr_num');
trialend = contains(value,'end of trial');

% check they all have the same number of occurence
total_trials = numel(value(trialstart));


% load behav data
load(cfg.behavpath); % -> trials table

trl = [];

sample_auditstim = sample(auditstim);
value_snrnum = value(snr_num);
value_vowelnum = value(vowel);

% loop across trials
for itrial = 1:(total_trials - 1)
    % trlbegin, trlend, offset -> get sample for audit stim
    sample = sample_auditstim(itrial);
    trlbegin = sample - pretrig;
    trlend = sample + posttrig;
    offset = - pretrig;
    % snrnum, vowelnum
    msgsnr = value_snrnum(itrial);
    snr_num = str2double(extractBetween(msgsnr,'snr_num = ',','));
    msgvow = value_vowelnum(itrial);
    vowel_num = str2double(extractBetween(msgvow,'vowel = ',','));
    % sanity check
    if caca == 1 % blocks shitshow
        sbj = cfg.subj_id;
        % define ii
        if strcmp(sbj,'28A')
            ii = itrial + 300;
        elseif strcmp(sbj,'12P')
            if itrial < 201
                ii = itrial;
            else % >200
                ii = itrial + 120;
            end
        elseif strcmp(sbj,'13P')
            if itrial < 241
                ii = itrial;
            elseif itrial > 240 && itrial < 247
                skip = true; % extra trials to remove: 241 242 243 244 245 246
            elseif itrial > 246
                ii = itrial - 6;
            end
        elseif strcmp(sbj,'20P')
            ii = itrial + 280;
        elseif strcmp(sbj,'24P')
            ii = itrial + 240;
        elseif strcmp(sbj,'29P')
            ii = itrial + 200;
        elseif strcmp(sbj,'30P') || strcmp(sbj,'32P')
            ii = itrial + 360;
        end
    else
        ii = itrial;
    end
    if skip == false
    snr_num_check = trials.snr_num(ii);
    vowel_num_check = trials.stimulus_num(ii);
    if ~isequal(snr_num,snr_num_check) || ~isequal(vowel_num,vowel_num_check)
        error('mismatch behav / pupil')
    end
    % trlcnt (in block), blockcnt
    trlcnt = trials.trial_in_block(ii);
    blockcnt = trials.block(ii);
    % question_type, HnotH
    question_type = trials.question_num(ii);
    if question_type == 3 % mindwander
        if trials.answer_num(ii) == 1 % sound
            HnotH = 1; % heard
        else
            HnotH = 0; % not heard
        end
    else
        HnotH = NaN; % not probed
    end
    newtrl = [trlbegin trlend offset snr_num vowel_num trlcnt blockcnt question_type HnotH];
    trl = [trl; newtrl];
    end
end
