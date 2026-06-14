%Staircase -- fMRI (juliechezboyer@wanadoo.fr) -- march 2022
%new version with an identification task to be as close as possible to the
%main task of active condition; so new script must include:
% - keeping response screen with both letters and randomized answer order
% - but changing answer treatment so that subjects always give an answer
% even if they haven't heard anything; 2 options then
%   - wrong answers are considered a 'miss' and lead to volume increase /
%   good answers to volume decrease; faster than option 2 but whenever
%   participants randomly chose correctly despite not having heard the
%   stimulus, volume will inappropriately decrease... BUT the objective
%   will be 75% identification (instead of 50% detection) ; see how to change break criterion as a
%   function of last trials comparison in the end
%   - we add an audibility response just like in the main task; could be a
%   training for participants but it would also be longer

%here we will keep three possible options:
%   1/ classical detection task with objective of 50% detection for A & B
%   indistinctly; only respond if letter heard
%   2/ identification task alone with obj. 75% perf
%   3/ identification task with audibility task and audibility 1 or 2 are
%   considered misses

%add a highlight where it is missing

%Clear workspace
close all;
clear all;
clc;
sca;

EXIT = 0; %for loop quit

%Set up for mri or computer
MRI = 0;
Comp = 0;
prompt = 'MRI (1) or computer test (2)? \n \n';
Condition = input(prompt);
if Condition == 1
    MRI = true;
elseif Condition == 2
    Comp = true;
end

%Set up for wanted response option
Task_1 = 0; %detection task
Task_2 = 0; %identification task
Task_3 = 0; %identification + audib task
prompt = '\n \n Which answer option? \n 1 = detection task; \n 2 = identification task; \n 3 = identification task + audibility; \n \n';
Resp = input(prompt);
if Resp == 1
    Task_1 = true;
elseif Resp == 2
    Task_2 = true;
elseif Resp == 3
    Task_3 = true;
end


%Setup
Current_directory = pwd;
%choice of stimuli (A+E, just A, or just E)
stimuli = {'A'; 'E'};
%stimuli = {'A'};
%stimuli = {'E'}
stimuli_nb = length(stimuli);
snr_levels_A = -9.5; 
snr_levels_E = -12;
snr_nb = length(snr_levels_A);
blocks_nb = 0;
trials_per_cond = 100; %equivalent to total trial number or x2
trials_per_block = trials_per_cond * snr_nb * stimuli_nb;
trials_nb = (blocks_nb+1) * trials_per_block; %+1

if Comp
    soundcardNumber = 1; %depends on the device; Julie's laptop = 1
end
if MRI
    soundcardNumber = []; % for MRI
end

ppd = 32; %pixels per degree = per centimeter at 57cm distance
if Comp
    screenNumber = max(Screen('Screens')); %total number of screens attached
end
if MRI
    screenNumber = 1; %for MRI CENIR
end

%Staircase & sound parameters
stepsize = .1; %initial stepsize
noise_ramp_time = 1; %seconds needed to bring noise up or down
noise_ramp_steps = 10; %steps of volume variation

white = [255 255 255];
black = [0 0 0];
grey = [128 128 128];
blue = [0 0 255];
green = [0 255 0];
red = [255 0 0];
yellow = [255 255 0];
background = black;
text_size = round(1.5*ppd);

rect_size = 4 * ppd;
rect_margin = round(rect_size / 8);
%for stimuli_nb == 2; 1 rectangle per column, x1 y1 x2 y2
answer_rect = [
    -rect_margin-rect_size,  rect_margin          ;
    -rect_size/2          , -rect_size/2          ;
    -rect_margin          ,  rect_margin+rect_size;
    rect_size/2          ,  rect_size/2          ;
    ];

% %Answer options - audibility << for old cursor
% %change it to have 4 rectangles corresponding to 4 distinct keypresses; +
% %highlight the response
% % %audib_levels = 0:10;
% % audib_levels = 1:4;
% % %audib_cursor = .5 * ppd;
% % audib_cursor = 2 * ppd;
% % audib_width = audib_cursor * length(audib_levels);
% % %audib_height = audib_cursor * 2;
% % audib_height = audib_cursor * 1;
% % audib_rect = [
% %     -audib_width/2-1, -audib_height/2, audib_width/2+1, audib_height/2];
%

%Answer options - audibility << for PAS-like response options
if Task_3
    rect_marg_2 = rect_margin/2;
    audib_rect = [...
        -3*rect_marg_2-2*rect_size, -rect_marg_2-rect_size, rect_marg_2          , 3*rect_marg_2+rect_size  ;
        -rect_size/2              , -rect_size/2          , -rect_size/2         , -rect_size/2             ;
        -3*rect_marg_2-rect_size  , -rect_marg_2          , rect_marg_2+rect_size, 3*rect_marg_2+2*rect_size;
        rect_size/2              ,  rect_size/2          , rect_size/2          , rect_size/2              ;
        ];
end

%Answer keys
KbName('UnifyKeyNames');
answer_keys = [KbName('b'),KbName('y')]; %for mri buttons
if Task_3
    audib_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')]; %for mri buttons
end
%less_keys = KbName('R');
%more_keys = KbName('U');
validation_key = KbName('space'); %only for the experimenter
scan_key = KbName('t'); %make sure it's the right letter for the scan
exit_key = KbName('escape');

%Timing, in secs
timing_blockstart = 1; %wait for it at block begining (to be confirmed)
timing_soa = [0 2]; %for MRI, fixation [1 3] - stim - qdelay 5 sec; total ISI must be around 10 (to be confirmed)
timing_qdelay = [0 2]; %to be confirmed
timing_rtmax = 4; %to be confirmed
timing_resphl = .2; %time to highlight selected answer; to be confirmed
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

%%

%Compute subject number
prompt = ('\n Subject number? \n');
subject_nb = input(prompt);

%Precise which block to start with, in case the experiment had to be
%interrupted
%prompt = ('\n Which block should we start with? \n');
%starting_block = input(prompt);
%doesn't work so far; we need to modify the 'block' variables so that we
%can add an if loop with index key for each block


%%
%if starting_block == 0

%Preparing data
trial = (1:trials_nb)';
trial_in_block = repmat((1:trials_per_block)', blocks_nb+1,1);
block = kron((0:blocks_nb)', ones(trials_per_block,1));
stimulus_num = repmat((1:stimuli_nb)',trials_per_block/stimuli_nb,1); %produce a vertical array of 1 and 2 (if n = 2)  , corresponding to stim type
stimulus = repmat(stimuli,trials_per_block/stimuli_nb,1); %produce a vertical array of (A,E) * (nb trials)
snr_num = repmat(kron((1:snr_nb)', ones(stimuli_nb, 1)), trials_per_cond, 1); %produce a vertical array of repeating variables from 1 to 5 (= nb SNR), each one * 2 (= nb stim), 5 times (nb trials per cond)
snr_A = repmat(kron(snr_levels_A, ones(stimuli_nb,1)), trials_per_cond, 1); %produce a vertical array of repeating pairs of SNR levels, 5 times (nb trials per cond)
snr_E = repmat(kron(snr_levels_E, ones(stimuli_nb,1)), trials_per_cond, 1);

soa_planned = [];
qdelay_planned = [];
for i = 1:trials_nb
    soa_planned = [soa_planned;timing_soa(1)+rand*range(timing_soa)]; %returns a list with random timings in prespecified range (here, timing_soa = [8 12])
    %NB: rand returns by default a random floating number between 0 and 1.
    qdelay_planned = [qdelay_planned;timing_qdelay(1)+rand*range(timing_qdelay)];
end

%Randomizing answer orders
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
snr_A = snr_A(trials_order);
snr_E = snr_E(trials_order);

%Defining result data
%trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr, vol_stim, soa_planned, qdelay_planned, answer_order);
%trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr, vol_stim_A, vol_stim_E, soa_planned, qdelay_planned, answer_order);
trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr_A, snr_E, soa_planned, qdelay_planned, answer_order);

%must be adapted to staircase
%we'll add a correction factor for letter 'E' to compensate for the
%psychometric shift between both functions (2.5 ?)
%stimulus volum computed separately for A et E so we can compensate for
%psychometric shift
% vol_noise = [];
% vol_noise(1) = .3;
% vol_stim_A = vol_noise*10.^(snr/20) * rms_noise/rms_stim;
% vol_stim_E = vol_noise*10.^((snr-2.5)/20) * rms_noise/rms_stim;
%vol_stim = vol_noise*10.^(snr/20) * rms_noise/rms_stim; %converting SNR from dB to volume, i.e. signal amplitude

%vol_stim = vol_stim(trials_order);
% vol_stim_A = vol_stim_A(trials_order);
% vol_stim_E = vol_stim_E(trials_order);

trials.vol_noise = nan(trials_nb, 1);
trials.vol_stim_A = nan(trials_nb, 1);
trials.vol_stim_E = nan(trials_nb, 1);
trials.time_start = nan(trials_nb, 1);
trials.soa_real = nan(trials_nb, 1);
trials.time_stim = nan(trials_nb, 1);
trials.qdelay_real = nan(trials_nb, 1);
trials.time_quest1 = nan(trials_nb, 1);
trials.answer_rect = nan(trials_nb, 1);
%trials.audib_rect = nan(trials_nb, 1);
trials.answer_num = nan(trials_nb, 1);
trials.answer = repmat(char(0), trials_nb, 1); %produces a matrix of ''
trials.correct = nan(trials_nb, 1);
trials.rt1 = nan(trials_nb, 1);
trials.average = nan(trials_nb, 1);
%trials.audioVol = nan(trials_nb, 1);
if Task_3
    trials.rt2 = nan(trials_nb, 1);
    trials.time_quest2 = nan(trials_nb, 1);
    trials.audib = nan(trials_nb, 1);
end
%trials.answer_trigger, trials.audibility_trigger suppressed

trials.vol_noise(1) = .5; %to be adapted: 1 ?

%what we want to record during staircase:
%volume = trials.audioVol(trial);
%average = mean(trials.audioVol(trial-5:trial));
%%
%Set up screen
Screen('Preference', 'SkipSyncTests', 1);
dimXwindow=800;
dimYwindow=500;
if Comp
    [window, screenRect] = Screen('OpenWindow', screenNumber, background, [0 0 dimXwindow dimYwindow], 32); %for tests and debug
end
if MRI
    [window, screenRect] = Screen('OpenWindow', screenNumber, background, [],32); %full screen
end
[screenWidth, screenHeight] = RectSize(screenRect);
[xCenter, yCenter] = RectCenter(screenRect);
answer_rect = answer_rect + repmat([xCenter ; yCenter], 2, stimuli_nb);
%audib_rect = audib_rect + repmat([xCenter ; yCenter], 1, 2); for old cursor
if Task_3
    audib_rect = audib_rect + repmat([xCenter ; yCenter], 2, 4); %for PAS like answer (4 rectangles), must be checked
end
Screen('TextSize', window, text_size);
%%

%Starting
message = 'Prêt à démarrer.';
%fprintf(message);
DrawFormattedText(window, message, 'center', 'center', grey);
Screen('Flip', window);
%fprintf([message '\n']);
fprintf('\n Please press SPACE when ready to start. \n \n');
%KbStrokeWait(-1);
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

% -- not compulsory on this machine --
%in fMRI, start must be synchronized with scan start (here we assume each
%scan is equivalent to a 't' keypress) and its equilibrium (about 5 scans)
% fprintf('\n waiting for the scanner to start \n \n');
% scan = 0;
% while scan < 6
%     [iskeydown, keytime, keys] = KbCheck(-1);
%     CurrentResp = KbName(keys);
%     if iskeydown
%         if keys(scan_key) && ~ismember('t',PreviousResp)
%             scan = scan + 1;
%         end
%     end
%     if isempty(CurrentResp)
%         PreviousResp={};
%     else
%         PreviousResp=CurrentResp;
%     end
% end

if EXIT
    fprintf('\n ESCAPE key pressed \n');
    clear all
end

starttime = datetime;
PsychPortAudio('Start', pamaster, 0); %infinite repetitions
fprintf('Starting audio.\n');
last_block = 0; % Keeping track of block change
%feedback = true; % Provide feedback to participant during first block

%%

%Loop for all blocks
%for k=starting_block:(blocks_nb)

%Loop for all trials

%Adding a line at each trial so it can be recorded even if the experiment
%stops

filename_base = fullfile(...
    Current_directory,...
    sprintf('Staircase_Subject_%d_%s_%s', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM')));
filename_csv = [filename_base '.csv'];
filename_mat = [filename_base '.mat'];

%Start_time = GetSecs;

for i=1:trials_nb %_per_block
    %At beginning of all blocks
    if (i==1 || trials.block(i)~=last_block)
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
        %--- Announce experiment and response keys ---
        message = '\n\n\n Appuyez sur 1 pour commencer. \n\n\n'; %adapt keypress to fMRI
        message = [message '\n\nTouches réponse \n\n\n - Q1: \n'];
        %         for j = 1:stimuli_nb %for keyboard answers
        %             message = [message char(KbName(answer_keys(j))) '=' char(stimuli(trials.answer_order(i,j))) ' '];
        %         end
        for j = 1:stimuli_nb
            message = [message num2str(j) ' = ' char(stimuli(trials.answer_order(i,j))) '  '];
        end
        %message = [message '\n\n Puis appuyez sur 1 lorsque vous entendez une voyelle. \n\n'];
        %message = [message '\n\n - Q2: \n' char(KbName(less_keys)) ' vers
        %la gauche (-) ; ' char(KbName(more_keys)) ' vers la droite (+) '];
        %pour curseur ordi
        %message = [message '\n\n - Q2: de gauche à droite = 1 / 2 / 3 / 4'];
        fprintf(message);
        DrawFormattedText(window, message, 'center', yCenter/2, grey);
        Screen('Flip', window);
        %KbStrokeWait(-1);
        while true
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                %if keys(validation_key)
                if keys(answer_keys(1))
                    break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            end
        end
        
        %wait for the scan to start (ie, keypress 't')
        fprintf('\n \n Waiting for the scanner to start ... \n ');
        message = 'L experience va bientôt commencer...';
        DrawFormattedText(window, message, 'center', yCenter, grey);
        Screen('Flip', window);
        while true
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if keys(scan_key)
                    break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            end
        end
        
        %--- Block beginning ---
        startblocktime = datetime;
        fprintf('\n\n %s ---Bloc %d \n', datestr(startblocktime, 'HH:MM:SS'), trials.block(i));
        Screen('DrawDots', window, [xCenter;yCenter], 10, grey, [], 2);
        Screen('Flip', window);
        WaitSecs(timing_blockstart);
        %turn noise on
        PsychPortAudio('FillBuffer', panoise, noise_buffer);
        PsychPortAudio('Start', panoise, 0,0,1);
        for s=1:noise_ramp_steps
            PsychPortAudio('Volume', panoise, trials.vol_noise(1)*(s/noise_ramp_steps)); %increase noise volume progressively
            WaitSecs(noise_ramp_time/noise_ramp_steps);
        end
        WaitSecs(timing_blockstart);
    end
    %next_onset = Start_time + 10; %10 must be replaced by next_evt_onset, ie the time left before next trial; to be computed by making a diagram of the whole MRI experiment
    %(= approximately SOA + (RT + question timings + HL timings) x 2)
    %while true %GetSecs < 30 %next_onset %while loop to be able to press escape
    %[keyIsDown, secs, keyCode] = KbCheck(-1);
    %if keyIsDown
    %EXIT = keyCode(KEY_ESCAPE);
    %if EXIT, break, end
    %end
    %Compute each trial number
    %fprintf('\n Block %d/%d Trial %2d/%d: %+3.0f | %s', trials.block(i), blocks_nb, trials.trial_in_block(i), trials_per_block, trials.snr(i), char(trials.stimulus(i)));
    fprintf('\n Block %d/%d Trial %2d/%d: snr num = %i | %s', trials.block(i), blocks_nb, trials.trial_in_block(i), trials_per_block, trials.snr_num(i), char(trials.stimulus(i)));
    trials.time_start(i) = GetSecs; %recording trial start time
    %Display fixation
    Screen('Drawdots', window, [xCenter; yCenter], 10, grey, [], 2);
    Screen('Flip', window);
    
    %Display stimulus
    %Compute vol_stim as a funcion of previously determined vol_noise
    trials.vol_stim_A(i) = trials.vol_noise(i)*10.^(trials.snr_A(i)/20) * rms_noise/rms_stim;
    trials.vol_stim_E(i) = trials.vol_noise(i)*10.^(trials.snr_E(i)/20) * rms_noise/rms_stim;
    
    %PsychPortAudio('Volume', pastim, trials.vol_stim(i));
    PsychPortAudio('FillBuffer', pastim, stim_buffer(trials.stimulus_num(i)));
    %Select stim volume depending on whether it's A (stimulus_num = 1) or E
    %(stimulus_num = 2)
    if trials.stimulus_num(i) == 1
        PsychPortAudio('Volume', pastim, trials.vol_stim_A(i));
    elseif trials.stimulus_num(i) == 2
        PsychPortAudio('Volume', pastim, trials.vol_stim_E(i));
    end
    %     PsychPortAudio('Volume', pastim, trials.vol_stim(i));
    %     PsychPortAudio('FillBuffer', pastim, stim_buffer(trials.stimulus_num(i)));
    trials.time_stim(i) = PsychPortAudio('Start', pastim, 1, ...
        trials.time_start(i)+trials.soa_planned(i), 1);
    trials.soa_real(i) = trials.time_stim(i) - trials.time_start(i);
    %Wait 'qdelay' time and stop stimulus
    WaitSecs(trials.qdelay_planned(i));
    PsychPortAudio('Stop', pastim);
    
    if Task_1
        %Display response screen
        Screen('FrameRect', window, grey, answer_rect);
        for j = 1:stimuli_nb
            DrawFormattedText(window, char(stimuli(trials.answer_order(i,j))), 'center', 'center', grey, [],[],[],[],[], answer_rect(:,j)');
        end
        Screen('Flip', window, 0, 1) %don't clear = 1, to keep rectangles at next flip
        trials.time_quest1(i) = GetSecs;
        trials.qdelay_real(i) = trials.time_quest1(i)-trials.time_stim(i);
        fprintf(' --> ');
        
        while GetSecs-trials.time_quest1(i) < timing_rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(answer_keys)) %a response is given, record it
                    %answer correspondance depends on the randomized answer
                    %order that is set at the beginning of each block
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
            fprintf('Missed!');
            %if not detected, we increase the volume for next trial // only
            %varying noise volume because stim volume is then determined as a
            %function of noise volume and SNR
            trials.vol_noise(i+1) = trials.vol_noise(i) + stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
        else
            fprintf('_%s_Detected. \n \n', char(trials.answer(i)));
            feedback_thickness = 6*1.5;
            Screen('FrameRect', window, grey, ...
                answer_rect(:,trials.answer_rect(i))', feedback_thickness);
            %if detected, we decrease the volume for next trial
            trials.vol_noise(i+1) = trials.vol_noise(i)-stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
        end
        %trials.audioVol(i) = vol_noise;
        writetable(trials, filename_csv);
        save(filename_mat, 'trials');
        Screen('Flip', window);
        WaitSecs(timing_resphl);
    elseif Task_2 %modified identification task
        %Display response screen
        Screen('FrameRect', window, grey, answer_rect);
        for j = 1:stimuli_nb
            DrawFormattedText(window, char(stimuli(trials.answer_order(i,j))), 'center', 'center', grey, [],[],[],[],[], answer_rect(:,j)');
        end
        Screen('Flip', window, 0, 1) %don't clear = 1, to keep rectangles at next flip
        trials.time_quest1(i) = GetSecs;
        trials.qdelay_real(i) = trials.time_quest1(i)-trials.time_stim(i);
        fprintf(' --> ');
        
        while GetSecs-trials.time_quest1(i) < timing_rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(answer_keys)) %a response is given, record it
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
        if trials.correct(i) == 0
            fprintf('wrong letter!');
            %considered a miss, so we increase the volume for next trial
            trials.vol_noise(i+1) = trials.vol_noise(i) + stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
        elseif isnan(trials.answer_num(i))
            fprintf('too late!');
            %considered a delayed response (subject is asked to answer
            %everytime) so we don't modify the volume
            trials.vol_noise(i+1) = trials.vol_noise(i);
        else
            fprintf('_%s_correctly detected. \n \n', char(trials.answer(i)));
            feedback_thickness = 6*1.5;
            Screen('FrameRect', window, grey, ...
                answer_rect(:,trials.answer_rect(i))', feedback_thickness);
            %if correctly detected, we decrease the volume for next trial
            trials.vol_noise(i+1) = trials.vol_noise(i)-stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
        end
        %trials.audioVol(i) = vol_noise;
        writetable(trials, filename_csv);
        save(filename_mat, 'trials');
        Screen('Flip', window);
        WaitSecs(timing_resphl);
        
    elseif Task_3 %add audibility response screen
        
        %Display response screen for identification
        Screen('FrameRect', window, grey, answer_rect);
        for j = 1:stimuli_nb
            DrawFormattedText(window, char(stimuli(trials.answer_order(i,j))), 'center', 'center', grey, [],[],[],[],[], answer_rect(:,j)');
        end
        Screen('Flip', window, 0, 1) %don't clear = 1, to keep rectangles at next flip
        trials.time_quest1(i) = GetSecs;
        trials.qdelay_real(i) = trials.time_quest1(i)-trials.time_stim(i);
        fprintf(' --> ');
        
        while GetSecs-trials.time_quest1(i) < timing_rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(answer_keys)) %a response is given, record it
                    %answer correspondance depends on the randomized answer
                    %order that is set at the beginning of each block
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
            fprintf('too late!');
            %             trials.vol_noise(i+1) = trials.vol_noise(i) + stepsize;
            %             PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            %             fprintf('\n New volume: %d', trials.vol_noise(i+1));
        else
            fprintf('_%s_Detected. \n \n', char(trials.answer(i)));
            feedback_thickness = 6*1.5;
            Screen('FrameRect', window, grey, ...
                answer_rect(:,trials.answer_rect(i))', feedback_thickness);
            %             trials.vol_noise(i+1) = trials.vol_noise(i)-stepsize;
            %             PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            %             fprintf('\n New volume: %d', trials.vol_noise(i+1));
        end
        %trials.audioVol(i) = vol_noise;
        writetable(trials, filename_csv);
        save(filename_mat, 'trials');
        Screen('Flip', window);
        WaitSecs(timing_resphl);
        
        Screen('FrameRect', window, grey, audib_rect);
        for j = 1:4
            DrawFormattedText(window, sprintf('%i', j), ...
                'center', 'center', grey, [],[],[],[],[], audib_rect(:,j)');
        end
        Screen('TextSize', window, text_size);
        Screen('Flip', window, 0, 1);
        trials.time_quest2(i) = GetSecs;
        
        %Response recording and volume adapting
        while GetSecs - trials.time_quest2(i)<timing_rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(audib_keys)) %a response is given, record it
                    trials.rt2(i) = keytime-trials.time_quest2(i);
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
            fprintf('\n Too late ! \n')
            trials.vol_noise(i+1) = trials.vol_noise(i);
        elseif (trials.audib(i) == 1 || trials.audib(i) == 2 || trials.correct(i) == 0 || isnan(trials.correct(i))) %low audibility and errors are considered misses
            fprintf('\n audibility %i = too low or incorrect response',trials.audib(i));
            %increase volume for next trial
            trials.vol_noise(i+1) = trials.vol_noise(i)+stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
            %highlight selected answer
            feedback_thickness = 6*1.5;
            Screen('FrameRect', window, grey, ...
                audib_rect(:,trials.audib_rect(i))', feedback_thickness);
        elseif (trials.audib(i) == 3 || trials.audib(i) == 4) && trials.correct(i) == 1
            fprintf('\n audibility %i = loud enough and correct response',trials.audib(i));
            %decrease volume for next trial
            trials.vol_noise(i+1) = trials.vol_noise(i)-stepsize;
            PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
            fprintf('\n New volume: %d', trials.vol_noise(i+1)*100);
            %highlight selected answer
            feedback_thickness = 6*1.5;
            Screen('FrameRect', window, grey, ...
                audib_rect(:,trials.audib_rect(i))', feedback_thickness);
        elseif isnan(trials.audib(i))
            fprintf('\n too late!');
            trials.vol_noise(i+1) = trials.vol_noise(i);
        end
        writetable(trials, filename_csv);
        save(filename_mat, 'trials');
        Screen('Flip', window);
        WaitSecs(timing_resphl);
        %break
        
    end
    
    %Display detection response screen
    %     DrawFormattedText(window, 'Appuyez sur 1 si vous avez entendu une lettre !', 'center', 'center', grey);
    %     Screen('Flip', window);
    %     trials.time_quest1(i) = GetSecs;
    %     trials.qdelay_real(i) = trials.time_quest1(i)-trials.time_stim(i);
    % 	fprintf(' --> ');
    
    %     while GetSecs-trials.time_quest1(i) < timing_rtmax
    %         [iskeydown, keytime, keys] = KbCheck(-1);
    %         if iskeydown
    %             if any(keys(answer_keys)) %a response is given, record it
    %                 %answer correspondance depends on the randomized answer
    %                 %order that is set at the beginning of each block -- only
    %                 %for identification task!
    % %                 for j = 1:stimuli_nb
    % %                     if keys(answer_keys(j))
    % %                         trials.answer_num(i) = trials.answer_order(i,j);%returns 1 or 2 (because 2 answer keys have been specified)
    % %                         trials.answer_rect(i) = j;
    % %                     end
    % %                 end
    %                 %trials.correct(i) = trials.answer_num(i)==trials.stimulus_num(i); %returns 1 for logical true, 0 for logical false; compares stim_num and answer_num
    %                 %trials.answer(i) = char(stimuli(trials.answer_num(i)));
    %                 for j = 1:stimuli_nb
    %                     if keys(answer_keys(j))
    %                         trials.answer_num(i) = trials.answer_order(i,j);
    %                     end
    %                 end
    %                 trials.answer(i) = char(stimuli(trials.answer_num(i)));
    %                 trials.correct(i) = trials.answer_num(i)==trials.stimulus_num(i);
    %                 trials.rt1(i) = keytime - trials.time_quest1(i);
    %                 break
    %             elseif keys(exit_key)
    %                 EXIT = 1;
    %                 break
    %             end
    %         else
    %             WaitSecs(0.004);
    %         end
    %     end
    %     if isnan(trials.answer_num(i))
    %         fprintf('Missed!');
    %         %if not detected, we increase the volume for next trial // only
    %         %varying noise volume because stim volume is then determined as a
    %         %function of noise volume and SNR
    %         trials.vol_noise(i+1) = trials.vol_noise(i) + stepsize;
    %         PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
    %         fprintf('\n New volume: %d', trials.vol_noise(i+1));
    %     else
    %         fprintf('_%s_Detected.', char(trials.answer(i)));
    %         %if detected, we decrease the volume for next trial
    %         trials.vol_noise(i+1) = trials.vol_noise(i)-stepsize;
    %         PsychPortAudio('Volume', panoise, trials.vol_noise(i+1));
    %         fprintf('\n New volume: %d', trials.vol_noise(i+1));
    %     end
    %     %WaitSecs(timing_resphl);
    %     %trials.audioVol(i) = vol_noise;
    %     writetable(trials, filename_csv);
    %     save(filename_mat, 'trials');
    %     Screen('Flip', window);
    %     WaitSecs(0.04)
    %KbReleaseWait(-1); %don't count a Q1 answer in Q2
    
    %progressively decreasing stepsize
    if i == 3
        stepsize =.05;
    elseif i == 10
        stepsize =.02;
    elseif i == 22
        stepsize =.01;
    end
    
    %ending experiment if there are enough trials & an average volume can
    %be computed


%     if Task_1 %is it equivalent to a computed perf mean > .50 ? if not, which
        %one is best ? maybe modify it if the mean formula works for other
        %2 tasks...
        %if i > 40 && mean(
    if i > 40 && trials.vol_noise(i) == trials.vol_noise(i-2) && trials.vol_noise(i-1)==trials.vol_noise(i-3)
        break
    end
%     if i > 5
%         break
%     end
        %mean_perf_A(idir,snrnum) = nnz(trials.correct == 1
        %& trials.snr_num == snrnum & trials.stimulus_num ==
        %1)/nnz(trials.snr_num == snrnum & trials.stimulus_num == 1)*100;
%     elseif Task_2 
%         if i > 40 && round(mean(trials.correct(1:i))) == .75
%             break
%         end
%     elseif Task_3
%         if i > 40 && round(mean(trials.audib(1:i))) == .75
%             break
%         end
%     end
%     
    
    
    % if ESCAPE is pressed
    if EXIT
        fprintf('\n ESCAPE key pressed \n');
        break
    end
    
end

for s=1:noise_ramp_steps
    PsychPortAudio('Volume', panoise, trials.vol_noise(i) * (1 - s/noise_ramp_steps));
    WaitSecs(noise_ramp_time/noise_ramp_steps);
end
%end
endtime = datetime;
fprintf('\nExpérience terminée, durée = %s\n\n', datestr(endtime-starttime, 'HH:MM:SS')); %Overall stats:\n', datestr(endtime-starttime, 'HH:MM:SS'));

DrawFormattedText(window, 'Expérience terminée, merci !', 'center', 'center', grey);
Screen('Flip', window);

PsychPortAudio('Stop', pamaster);

PsychPortAudio('DeleteBuffer');

PsychPortAudio('Close', pamaster);
%%
%Adapt saving consigns to the beginning of the script +++

%Record data // add timestamp
%filename_base = sprintf('/Users/julieboyer/Desktop/M2/projet M2/Nouveaux codes/Results_MRI_Pilots/Subject_%d', subject_nb);
%filename_base = sprintf('E:\Protocoles\psychtoolbox\SOUNDfMRI\LogFiles\Subject_%d_', subject_nb);
% filename_base = fullfile(...
%     Current_directory,...
%     sprintf('Subject_%d_%s_%s', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM'), datestr(endtime, '_HH-MM')));
trials.average(i) = mean(trials.vol_noise(i-6:i));

filename_csv = [filename_base '.csv'];
writetable(trials, filename_csv);
filename_mat = [filename_base '.mat'];
save(filename_mat, 'trials');
%
% volume = trials.audioVol(trial);

fprintf('final threshold = %02f\n', trials.vol_noise(i));
fprintf('average threshold = %02f\n', trials.average(i));
% path = '/Users/julieboyer/Desktop/M2/projet M2/Nouveaux codes/Results_Behav_Pilots/Staircase'; %change when used for scans
% save(sprintf('%s/staircase_subject_%02d', path, subject_number), 'volume', 'average');

%%
%%%%%%%%
%%% Close
%%%%%%%%

WaitSecs(2);
Screen('CloseAll');
