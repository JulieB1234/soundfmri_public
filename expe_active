
%CENIR answer box: HHSC - 2x4 - c // HID NAR BYGRT

% -------------- What remains to do ---------------------------------------
% - LoadParameters before or after Calibration ?
% - measure delays and time lost because of the CheckFix loop
% - get rid of feedback stuff ?

%Clear workspace
close all;
clear all;
clc;
sca;

%Set up PTB and stuff
PsychDefaultSetup(1);
dummymode=0;

%% ---- Eyelink Setup ----
% Open a graphics window on the main screen
%screenNumber=max(Screen('Screens')); %for computers
screenNumber = 1; %for MRI CENIR
dimXwindow=800;
dimYwindow=500;
%[window,screenRect] = Screen('OpenWindow', screenNumber, [], [0 0 dimXwindow dimYwindow]); %for tests and debug
[window, screenRect] = Screen('OpenWindow', screenNumber); %full screen
[xCenter, yCenter] = RectCenter(screenRect);
[width, height] = Screen('WindowSize', screenNumber);

% Provide Eyelink with details about the graphics environment
el=EyelinkInitDefaults(window);

% Disable key output to Matlab window
ListenChar(2);

% Initialization of the connection with the Eyelink Gazetracker
if ~EyelinkInit(dummymode, 1)
    fprintf('Eyelink Init aborted.\n');
end
WaitSecs(0.001);

%Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
%Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

[v, vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

% Calibrate the eye tracker
%EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
%EyelinkDoDriftCorrection(el);

%fprintf('\n Calibration done ! \n');

%Use CENIR's setup for Eyelink
LoadParameters;

% Restore keyboard output to Matlab:
ListenChar(0);

EXIT = 0; %for loop quit

ppd = 32; %pixels per degree = per centimeter at 57cm distance
white = [255 255 255];
black = [0 0 0];
grey = [128 128 128];
rad = 64; %MUST BE ADAPTED !!
% 40 if gazeRect=[xCenter-20 yCenter-20 xCenter+20 yCenter+20];
% 20 if gazeRect=[xCenter-10 yCenter-10 xCenter+10 yCenter+10];

if Eyelink('isconnected') ~= 1
    Eyelink('initialize');
else
    fprintf('\nEyelink is connected\n');
end

% Open Eyelink file to record data to
edfFile='ca3.edf';
Eyelink('Openfile', edfFile);

% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('Message', 'SYNCTIME');
eye_used = -1;

%% --- Other setups ---
% Complementary screen setup
text_size = round(1.5*ppd);
Current_directory = pwd;
%Screen('Preference', 'SkipSyncTests', 1);
[screenWidth, screenHeight] = RectSize(screenRect);
[xCenter, yCenter] = RectCenter(screenRect);

% Stimuli and data setup
stimuli = {'A'; 'E'};
stimuli_nb = length(stimuli);
prompt = ('What is the staircase volume for this participant? \n\n');
vol_noise = input(prompt); %must be adapted to staircase >> enter subject's staircase value
noise_ramp_time = 1; %seconds needed to bring noise up or down
noise_ramp_steps = 10; %steps of volume variation
%snr_levels = [-Inf;-11.5;-9.5;-7.5;-3]; %full manip
snr_levels_A = [-Inf;-11.5;-9.5;-7.5;-3];
snr_levels_E = [-Inf;-14;-12;-9;-2];
snr_nb = length(snr_levels_A);
trials_per_cond = 5; %5 for full manip - nb of repetition within each block, for a given SNR and stimulus (trials / cond / block)
trials_per_block = trials_per_cond * snr_nb * stimuli_nb; %50, for total = 450 trials, 9 blocks
blocks_nb = 8; %type 8 for full manip ==> 9 (total = +1)
trials_nb = (blocks_nb+1) * trials_per_block; %+1

%Answer rectangles - identification
rect_size = 4 * ppd;
rect_margin = round(rect_size / 8);
answer_rect = [
    -rect_margin-rect_size,  rect_margin          ;
    -rect_size/2          , -rect_size/2          ;
    -rect_margin          ,  rect_margin+rect_size;
    rect_size/2          ,  rect_size/2          ;
    ];

answer_rect = answer_rect + repmat([xCenter ; yCenter], 2, stimuli_nb);

%Answer rectangles - audibility << for PAS-like response options
rect_marg_2 = rect_margin/2;
audib_rect = [...
    -3*rect_marg_2-2*rect_size, -rect_marg_2-rect_size, rect_marg_2          , 3*rect_marg_2+rect_size  ;
    -rect_size/2              , -rect_size/2          , -rect_size/2         , -rect_size/2             ;
    -3*rect_marg_2-rect_size  , -rect_marg_2          , rect_marg_2+rect_size, 3*rect_marg_2+2*rect_size;
    rect_size/2              ,  rect_size/2          , rect_size/2          , rect_size/2              ;
    ];

audib_rect = audib_rect + repmat([xCenter ; yCenter], 2, 4);

%Answer keys // fMRI = B / Y / G / R
KbName('UnifyKeyNames');
answer_keys = [KbName('b'),KbName('y')]; %for mri buttons
audib_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')]; %for mri buttons
validation_key = KbName('space'); %only for the experimenter
scan_key = KbName('t'); %make sure it's the right letter for the scan
exit_key = KbName('escape');

%Timing, in secs
timing_blockstart = 1; %wait for it at block begining (to be confirmed)
timing_soa = [1 3]; %for MRI, fixation [1 3] - stim - qdelay 5 sec; total ISI must be around 8-10
timing_qdelay = [4 6];
timing_rtmax = 3;
timing_resphl = .2; %time to highlight selected answer
timing_blockend = 2; %fixation at the end of block

%Noise files and loading
audiodir = 'Sounds/';
for i = 0:blocks_nb %to use different TEN file for each block
    audiofile_noise{i+1} = [audiodir 'LF_TEN_SPL_' num2str(i) '.wav'];
end
for i = 1:stimuli_nb
    audiofile_stim{i} = [audiodir char(stimuli(i)) '.wav'];
end

nrchannels = 2;

%Opening and setting audio devices
soundcardNumber = []; %for MRI or eyelink PC; depends on the device; Julie's laptop = 1; Thea's laptotp = 2

InitializePsychSound(1);
[audiodata, noisefreq] = audioread(audiofile_noise{1});
rms_noise = rms(audiodata(:,1)); 
stim_buffer = [];
stim_rms = [];
for i = 1:stimuli_nb
    [audiodata, infreq] = audioread(char(audiofile_stim(i)));
    stim_rms(i) = rms(audiodata(:,1)); 
end
rms_stim = min(stim_rms);
for i = 1:stimuli_nb
    [audiodata, infreq] = audioread(audiofile_stim{i});
    if infreq ~= noisefreq
        fprinf('Resampling from %i to %i Hz', infreq, noisefreq);
        audiodata = resample(audiodata,noisefreq, infreq);
    end
    [samplecount, ninchannels] = size(audiodata);
    audiodata = repmat(transpose(audiodata), nrchannels/ninchannels, 1);
    audiodata = audiodata * rms_stim/stim_rms(i);
    stim_buffer(i) = PsychPortAudio('CreateBuffer', [], audiodata);
    fprintf('Filled audiobuffer handle %i with soundfile %s \n', stim_buffer(i), audiofile_stim{i});
end

pamaster = PsychPortAudio('Open', soundcardNumber, 9, 3, noisefreq, nrchannels);
panoise = PsychPortAudio('OpenSlave', pamaster);
PsychPortAudio('Volume', panoise, 0); %start with volume 0
pastim = PsychPortAudio('OpenSlave', pamaster);

%% --- Enter Subj_nb and prepare data ---

%Compute subject number
prompt = ('\n Subject number? \n');
subject_nb = input(prompt);

%Prepare data
trial = (1:trials_nb)';
trial_in_block = repmat((1:trials_per_block)', blocks_nb+1,1);
block = kron((0:blocks_nb)', ones(trials_per_block,1));
stimulus_num = repmat((1:stimuli_nb)',trials_per_block/stimuli_nb,1); %produce a vertical array of 1 and 2 (if n = 2)  , corresponding to stim type
stimulus = repmat(stimuli,trials_per_block/stimuli_nb,1); %produce a vertical array of (A,E) * (nb trials)
snr_num = repmat(kron((1:snr_nb)', ones(stimuli_nb, 1)), trials_per_cond, 1); %produce a vertical array of repeating variables from 1 to 5 (= nb SNR), each one * 2 (= nb stim), 5 times (nb trials per cond)
%snr = repmat(kron(snr_levels, ones(stimuli_nb,1)), trials_per_cond, 1); %produce a vertical array of repeating pairs of SNR levels, 5 times (nb trials per cond)
snr_A = repmat(kron(snr_levels_A, ones(stimuli_nb,1)), trials_per_cond, 1);
snr_E = repmat(kron(snr_levels_E, ones(stimuli_nb,1)), trials_per_cond, 1);
%vol_stim_A = vol_noise*10.^(snr/20) * rms_noise/rms_stim;
%vol_stim_E = vol_noise*10.^((snr-2.5)/20) * rms_noise/rms_stim;
vol_stim_A = vol_noise*10.^(snr_A/20) * rms_noise/rms_stim;
vol_stim_E = vol_noise*10.^(snr_E/20) * rms_noise/rms_stim;

soa_planned = [];
qdelay_planned = [];
for i = 1:trials_nb
    soa_planned = [soa_planned;timing_soa(1)+rand*range(timing_soa)]; 
    qdelay_planned = [qdelay_planned;timing_qdelay(1)+rand*range(timing_qdelay)];
end

%Randomize answer orders
possible_orders = perms(1:stimuli_nb); %2*2 matrix (because there are 2 stimuli) with possible orders, i.e. 1 2 or 2 1
per_block_answer_order = repmat(possible_orders, floor(blocks_nb-length(possible_orders)), 1); %floor returns closest integer < or = to floating number (i'm not sure what the point is, since its argument is an operation of integers)
per_block_answer_order = [per_block_answer_order;possible_orders(1:blocks_nb-length(per_block_answer_order), :)];
per_block_answer_order = per_block_answer_order(randperm(blocks_nb),:); %randperm(N) returns a vector containing a random permutation of the integers 1:N.  For example, randperm(6) might be [2 4 5 6 1 3].
training_block_answer_order = [1:stimuli_nb];
per_block_answer_order = [training_block_answer_order;per_block_answer_order];
answer_order = kron(per_block_answer_order, ones(trials_per_block, 1)); %returns a 200*2 matrix of 1s and 2s (either 1,2 or 2,1), for stim nb = 2 and 50 trials / block

trials_order = [];
for b = 0:blocks_nb
    trials_order = [trials_order randperm(trials_per_block)]; %returns a list of integers randomized in range (1:trials_per_block(here, 50)) for each block
end
stimulus_num = stimulus_num(trials_order);
stimulus = stimulus(trials_order);
snr_num = snr_num(trials_order);
%snr = snr(trials_order);
snr_A = snr_A(trials_order);
snr_E = snr_E(trials_order);
vol_stim_A = vol_stim_A(trials_order);
vol_stim_E = vol_stim_E(trials_order);

%Define result data
%trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr, vol_stim_A, vol_stim_E, soa_planned, qdelay_planned, answer_order);
trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr_A, snr_E, vol_stim_A, vol_stim_E, soa_planned, qdelay_planned, answer_order);

trials.scan_start = nan(trials_nb, 1);
trials.time_start = nan(trials_nb, 1);
trials.onset_stim = nan(trials_nb, 1);
trials.onset_start = nan(trials_nb, 1);
trials.soa_real = nan(trials_nb, 1);
trials.time_stim = nan(trials_nb, 1);
trials.qdelay_real = nan(trials_nb, 1);
trials.time_quest1 = nan(trials_nb, 1);
trials.duration = nan(trials_nb, 1);
trials.answer_rect = nan(trials_nb, 1);
trials.audib_rect = nan(trials_nb, 1);
trials.answer_num = nan(trials_nb, 1);
trials.answer = repmat(char(0), trials_nb, 1); %produces a matrix of ''
trials.correct = nan(trials_nb, 1);
trials.rt1 = nan(trials_nb, 1);
trials.rt2 = nan(trials_nb, 1);
trials.time_quest2 = nan(trials_nb, 1);
trials.audib = nan(trials_nb, 1);
trials.staircase_vol = nan(trials_nb, 1);
trials.ending = nan(trials_nb, 1);

add_file = table(block, trial_in_block, trial);
add_file.startblock = nan(trials_nb, 1); %beginning of each block
add_file.endblock = nan(trials_nb, 1); %end of each block
add_file.startexp = nan(trials_nb, 1); %beginning of the experiment
add_file.endexp = nan(trials_nb, 1); %end of the experiment

%%

%Start
message = 'Pret a demarrer.';
DrawFormattedText(el.window, message, 'center', 'center', black);
Screen('Flip', el.window);
fprintf('\n Please press SPACE when ready to start. \n \n');

%Loop to be able to quit at any time during the experiment
while true
    [iskeydown, keytime, keys] = KbCheck(-1);
    if iskeydown
        if keys(validation_key)
            break
        elseif keys(exit_key)
            EXIT = 1;
            break
        end
    end
end

if EXIT
    fprintf('\n ESCAPE key pressed \n');
    clear all;
end

starttime = datetime;
add_file.startexp(1) = GetSecs;
Eyelink('message', 'experiment_start');
PsychPortAudio('Start', pamaster, 0); %infinite repetitions
fprintf('Starting audio.\n');
last_block = 0; % Keeping track of block change
feedback = true; % Provide feedback to participant during first block

%%

%Loop for all trials

%Adding a line at each trial so it can be recorded even if the experiment
%stops
filename_base = fullfile(...
    Current_directory,...
    sprintf('Subject_%d_%s_%s', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM')));
filename_csv = [filename_base '.csv'];
filename_mat = [filename_base '.mat'];

Fixation = {};

for i=1:trials_nb
    fixx = [];
    %At beginning of all blocks
    if (i==1 || trials.block(i)~=last_block)
        %All blocks beginnings except the first one
        if (i>1)
            %Announce end of block
            endblocktime = datetime; 
            add_file.endblock(i-1) = GetSecs;
            Eyelink('message', 'end of block %i / %i', trials.block(i-1), blocks_nb);
            fprintf('\n\n%s ***** Block %d done ***** ', datestr(endblocktime, 'HH:MM:SS'), last_block);
            disp(endblocktime-startblocktime);
            
            %Display results of last block
            varfun(@mean, trials(trials.block==last_block,:),...
                'GroupingVariables', 'snr_num',...
                'InputVariables',{'correct','audib'})
            varfun(@mean, trials(trials.block==last_block,:),...
                'GroupingVariables', 'stimulus',...
                'InputVariables',{'correct','audib'})

            for z = 1:trials_per_block
                fix_moy(z) = mean(Fixation{trials.block(i-1)+1,z},'omitnan');
            end
            fix_moy_block = mean(fix_moy, 'omitnan'); 
            fprintf('\n\n\n Mean correct fixation during last block: %.2f percent \n\n\n', fix_moy_block * 100)
            
            %Display fixation
            fprintf('%d secondes de fixation... ', timing_blockend);
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('Flip', window);
            WaitSecs(timing_blockend);
            %Decrease noise volume
            for s=1:noise_ramp_steps
                PsychPortAudio('Volume', panoise, vol_noise * (1 - s/noise_ramp_steps));
                WaitSecs(noise_ramp_time/noise_ramp_steps);
            end
            %Turn noise off
            PsychPortAudio('Stop', panoise);
            PsychPortAudio('DeleteBuffer', noise_buffer);
            message = ['Bloc ' num2str(last_block) '/' num2str(blocks_nb)...
                ' fini.\n\n Preparation du prochain bloc...'];
            DrawFormattedText(window, message, 'center', 'center', black);
            Screen('Flip', window);
            %feedback = false; % Training finished, remove feedback
            last_block = trials.block(i);
        end
        %--- Prepare noise for next block ---
        %load noise file
        [audiodata, infreq] = audioread(audiofile_noise{trials.block(i)+1});
        if infreq ~= noisefreq
            fprintf('Resampling from %i Hz to %i Hz... ', infreq, noisefreq);
            audiodata = resample(audiodata, noisefreq, infreq);
        end
        [samplecount, ninchannels] = size(audiodata);
        audiodata_noise = repmat(transpose(audiodata), nrchannels / ninchannels, 1);
        %create buffer
        noise_buffer = PsychPortAudio('CreateBuffer', [], audiodata_noise);
        fprintf('Filled audiobuffer handle %i with soundfile %s ...\n', ...
            noise_buffer, audiofile_noise{trials.block(i)+1});
        WaitSecs(1);
        %%
        %--- Announce next block and response keys ---
        message = ['Prochain bloc = ' num2str(trials.block(i)) '/' num2str(blocks_nb)];
        message = [message '\n\n\n Appuyer sur 1 pour commencer le bloc. \n\n\n']; %adapt keypress to fMRI
        message = [message '\n\nTouches reponse \n\n\n - Q1: \n'];
        for j = 1:stimuli_nb
            message = [message num2str(j) ' = ' char(stimuli(trials.answer_order(i,j))) '  '];
        end
        message = [message '\n\n - Q2: de gauche a droite = 1 / 2 / 3 / 4'];
        fprintf(message);
        DrawFormattedText(window, message, 'center', yCenter/2, black);
        Screen('Flip', window);

        while true
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if keys(answer_keys(1))
                    break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            end
        end
        
        %wait for experimenter to press SPACE and for scan to start (ie, keypress 't')
        message = 'Le bloc va bientot commencer...';
        DrawFormattedText(window, message, 'center', yCenter, black);
        Screen('Flip', window);
        fprintf('\n Please press SPACE when ready to start. \n \n');
        while true
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if keys(validation_key)
                    break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            end
        end
        fprintf('\n \n Waiting for the scanner to start ... \n ');
        while true
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if keys(scan_key)
                    trials.scan_start(i) = GetSecs;
                    break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            end
        end
        %--- Block beginning ---
        startblocktime = datetime;
        add_file.startblock(i) = GetSecs;
        Eyelink('message', 'start of block %i / %i', trials.block(i), blocks_nb);
        fprintf('\n\n %s ---Bloc %d \n', datestr(startblocktime, 'HH:MM:SS'), trials.block(i));
        %         Screen('DrawDots', window, [xCenter;yCenter], 10, black, [], 2);
        %         Screen('Flip', window);
        WaitSecs(timing_blockstart);
        %turn noise back on
        PsychPortAudio('FillBuffer', panoise, noise_buffer);
        PsychPortAudio('Start', panoise, 0,0,1);
        for s=1:noise_ramp_steps
            PsychPortAudio('Volume', panoise, vol_noise*(s/noise_ramp_steps)); %increase noise volume progressively
            WaitSecs(noise_ramp_time/noise_ramp_steps);
        end
        WaitSecs(timing_blockstart);
    end
    if isnan(trials.scan_start(i)) %give a value to all 'scan start' timings even if it is not the beginning of a block
        trials.scan_start(i) = trials.scan_start(i-1);
    end
    
    %Check Eyelink
    if Eyelink('isconnected') ~= 1
        Eyelink('initialize');
    else
        fprintf('\nEyelink is connected\n');
    end
    
    %Compute each trial number
    fprintf('\n Block %d/%d Trial %2d/%d: %+3.1f | %s', trials.block(i), blocks_nb, trials.trial_in_block(i), trials_per_block, trials.snr_num(i), char(trials.stimulus(i)));
    trials.time_start(i) = GetSecs; %recording trial start time
    Eyelink('message', 'trial_start, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
    
    %Display fixation and start Eyelink fixation check
    Screen('Drawdots', window, [xCenter; yCenter], 10, black, [], 2);
    Screen('Flip', window);

    %Display auditory stimulus
    PsychPortAudio('FillBuffer', pastim, stim_buffer(trials.stimulus_num(i)));
    if trials.stimulus_num(i) == 1
        PsychPortAudio('Volume', pastim, trials.vol_stim_A(i));
    elseif trials.stimulus_num(i) == 2
        PsychPortAudio('Volume', pastim, trials.vol_stim_E(i));
    end
    trials.time_stim(i) = PsychPortAudio('Start', pastim, 1, ...
        trials.time_start(i)+trials.soa_planned(i), 1);
    trials.onset_stim(i) = trials.time_stim(i) - trials.scan_start(i);
    trials.onset_start(i) = trials.time_start(i) - trials.scan_start(i);
    trials.soa_real(i) = trials.time_stim(i) - trials.time_start(i);

    Limm = trials.time_stim(i) + trials.qdelay_planned(i);
    WaitSecs(0.2);
    Eyelink('message', 'auditory stim, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);

    % check fixation during qdelay (before response screen)
    tstart=GetSecs;
    t=tstart;
    timeout = 0.5;
    repetition_nb = 0;
    
     while ((t-tstart) < timeout && repetition_nb < 10) %check fixation but limit nb of iterations
        NewSample = Eyelink( 'NewFloatSampleAvailable');
        if NewSample
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            if eye_used ~= -1 % do we know which eye to use yet?
                % if we do, get current gaze position from sample
                x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                y = evt.gy(eye_used+1);
                % do we have valid data and is the pupil visible?
                if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    if sqrt((x-xCenter).^2 + (y-yCenter).^2) < rad
                        a = 1;
                    else
                        a = 0;
                    end
                    fixx = [fixx a];
                else
                    % if data is invalid (e.g. during a blink), clear display
                    fprintf('eyelink data invalid');
                end
            else % if we don't, first find eye that's being tracked
                eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
                if eye_used == el.BINOCULAR % if both eyes are tracked
                    eye_used = el.LEFT_EYE; % use left eye
                end
            end
        end % if sample available
        repetition_nb = repetition_nb + 1;
        t = GetSecs;
    end % main checkfix loop
    
    PsychPortAudio('Stop', pastim);

    %max 1sec normalement
    delay(i) = GetSecs - tstart; %just for tests
    while GetSecs < Limm
        WaitSecs(.004);
    end

    %Display response screen for Q1
    Screen('FrameRect', window, black, answer_rect);
    for j = 1:stimuli_nb
        DrawFormattedText(window, char(stimuli(trials.answer_order(i,j))), 'center', 'center', black, [],[],[],[],[], answer_rect(:,j)');
    end
    Screen('Flip', window, 0, 1) %don't clear = 1, to keep rectangles at next flip
    trials.time_quest1(i) = GetSecs;
    trials.qdelay_real(i) = trials.time_quest1(i)-trials.time_stim(i);
    Eyelink('message', 'question_1, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
    fprintf(' --> ');
    
    while GetSecs-trials.time_quest1(i) < timing_rtmax
        [iskeydown, keytime, keys] = KbCheck(-1);
        if iskeydown
            if any(keys(answer_keys)) %a response is given, record it
                %answer correspondance depends on the randomized answer
                %order that is set at the beginning of each block
                Eyelink('message', 'keypress_1, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
                for j = 1:stimuli_nb
                    if keys(answer_keys(j))
                        trials.answer_num(i) = trials.answer_order(i,j);%returns 1 or 2 (because 2 answer keys have been specified)
                        trials.answer_rect(i) = j;
                    end
                end
                trials.correct(i) = trials.answer_num(i)==trials.stimulus_num(i); %returns 1 for logical true, 0 for logical false; compares stim_num and answer_num
                trials.answer(i) = char(stimuli(trials.answer_num(i)));
                trials.rt1(i) = keytime - trials.time_quest1(i);
                break
            elseif keys(exit_key)
                EXIT = 1;
                break
            end
        else
            WaitSecs(0.004);
        end
    end
    if isnan(trials.answer_num(i))
        fprintf('\n Too late! \n');
    else
        fprintf('_%s_Recorded.', char(trials.answer(i)));
        feedback_thickness = 6*1.5;
        Screen('FrameRect', window, black, ...
            answer_rect(:,trials.answer_rect(i))', feedback_thickness);
    end
    
    writetable(trials, filename_csv);
    save(filename_mat, 'trials');
    Screen('Flip', window);
    WaitSecs(timing_resphl);
    KbReleaseWait(-1); %don't count a Q1 answer in Q2
    
    %Display audib question (Q2)
    Screen('FrameRect', window, black, audib_rect);
    for j = 1:4
        DrawFormattedText(window, sprintf('%i', j), ...
            'center', 'center', black, [],[],[],[],[], audib_rect(:,j)');
    end
    Screen('TextSize', window, text_size);
    Screen('Flip', window, 0, 1);
    trials.time_quest2(i) = GetSecs;
    Eyelink('message', 'question_2, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);

    %Response recording
    while GetSecs - trials.time_quest2(i)<timing_rtmax
        [iskeydown, keytime, keys] = KbCheck(-1);
        if iskeydown
            if any(keys(audib_keys)) %a response is given, record it
                trials.rt2(i) = keytime-trials.time_quest2(i);
                Eyelink('message', 'keypress_2, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
                for j = 1:length(audib_keys)
                    if keys(audib_keys(j))
                        trials.audib(i)=j;
                        trials.audib_rect(i) = j;
                    end
                end
                break
            elseif keys(exit_key)
                EXIT = 1;
                break
            end
        else
            WaitSecs(0.004);
        end
    end
    if isnan(trials.audib(i))
        fprintf('\n Too late! \n');
    else
        fprintf('_%i_Recorded.', trials.audib(i));
        feedback_thickness = 6*1.5;
        Screen('FrameRect', window, black, ...
            audib_rect(:,trials.audib_rect(i))', feedback_thickness);
    end
    writetable(trials, filename_csv);
    save(filename_mat, 'trials');
    Screen('Flip', window);
    WaitSecs(timing_resphl);
    trials.ending(i) = GetSecs;
    
    %Send Infos about current trial to Eyelink File
    Eyelink('message', 'snr_num = %i, trials.snr_num(i), trial %i / %i _ block %i / %i',trials.snr_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    Eyelink('message', 'vowel = %i, trial %i / %i _ block %i / %i', trials.stimulus_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    if ~ isnan(trials.correct(i))
        Eyelink('message', 'correct = %i, trial %i / %i _ block %i / %i',trials.correct(i), i, trials_per_block, trials.block(i), blocks_nb);
    else
        Eyelink('message', 'correct = NaN, trial %i / %i _ block %i / %i',i, trials_per_block, trials.block(i), blocks_nb);
    end
    if ~ isnan(trials.audib(i))
        Eyelink('message', 'audibility = %i, trial %i / %i _ block %i / %i',trials.audib(i), i, trials_per_block, trials.block(i), blocks_nb);
    else
        Eyelink('message', 'audibility = NaN, trial %i / %i _ block %i / %i',i, trials_per_block, trials.block(i), blocks_nb);
    end
    Eyelink('Message', 'end of trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);

    trials.staircase_vol(i) = vol_noise;

    % if ESCAPE is pressed
    if EXIT
        fprintf('\n ESCAPE key pressed \n');
        break
    end
    
    %Compute fixation performance for all blocks' trials
    for iblock = 1:(blocks_nb + 1) 
        if trials.block(i) == (iblock-1)
            for itrial_in_block = 1:trials_per_block
                if trials.trial_in_block(i) == itrial_in_block
                    Fixation{iblock,itrial_in_block} = fixx; 
                end
            end
        end
    end
    trials.duration(i) = GetSecs - trials.time_start(i);
    
end %end of main trial loop

%Decrease noise
for s=1:noise_ramp_steps
    PsychPortAudio('Volume', panoise, vol_noise * (1 - s/noise_ramp_steps));
    WaitSecs(noise_ramp_time/noise_ramp_steps);
end

%End experiment
endtime = datetime;
add_file.endexp(i) = GetSecs;
Eyelink('message', 'experiment_end');
fprintf('\nExperience terminee, duree = %s\n\n', datestr(endtime-starttime, 'HH:MM:SS')); %Overall stats:\n', datestr(endtime-starttime, 'HH:MM:SS'));

DrawFormattedText(window, 'Experience terminee, merci !', 'center', 'center', black);
Screen('Flip', window);

PsychPortAudio('Stop', pamaster);

PsychPortAudio('DeleteBuffer');

PsychPortAudio('Close', pamaster);

% finish up: stop recording eye-movements,
% close graphics window, close data file and shut down tracker
Eyelink('StopRecording');
Eyelink('CloseFile');
% download data file
try
    fprintf('Receiving data file ''%s''\n', edfFile );
    status=Eyelink('ReceiveFile');
    if status > 0
        fprintf('ReceiveFile status %d\n', status);
    end
    if 2==exist(edfFile, 'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
    end
catch rdf
    fprintf('Problem receiving data file ''%s''\n', edfFile );
    rdf;
end
Eyelink('Shutdown');

%record main behaviour data
filename_base = fullfile(...
    Current_directory,...
    sprintf('Subject_%d_%s_%s', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM'), datestr(endtime, '_HH-MM')));
filename_csv = [filename_base '.csv'];
writetable(trials, filename_csv);
filename_mat = [filename_base '.mat'];
save(filename_mat, 'trials');

%record also the add_file
filename_base = fullfile(...
    Current_directory,...
    sprintf('Subject_%.1f_%s_%s_addfile', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM'), datestr(endtime, '_HH-MM')));
filename_csv = [filename_base '.csv'];
writetable(add_file, filename_csv);
filename_mat = [filename_base '.mat'];
save(filename_mat, 'add_file');

%... and record fixation performances!
filename_base = fullfile(...
    Current_directory,...
    sprintf('Subject_%.1f_%s_%s_fixation', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM'), datestr(endtime, '_HH-MM')));
filename_mat = [filename_base '.mat'];
save(filename_mat, 'Fixation');

%%
%%%%%%%%
%%% Close
%%%%%%%%

WaitSecs(2);
Screen('CloseAll');
