%Passive Condition -- fMRI (juliechezboyer@wanadoo.fr) -- april 2022

%% POUR LES ISI
% - pour homogénéiser les durées entre les différents types d'essais,
% rajouter un délai aux questions type 'RT' et 'None'
% - piloter durées pour questions type 'None' et 'RT', pour objectif:
% moyenne globale autour de 9 sec (sachant que la moyenne quiz / mw est à
% 11.3)

%% POUR LE NB D'ESSAIS
% - contrainte: ce doit être un multiple du nb de questions (4)
% - actuellement: on garde 4 essais / condition / bloc mais on essaie
% d'augmenter le nb de blocs (11?) mais en faisant des pilotes
% comportementaux préalables avec les nouveax timestamps pour pouvoir bien
% mesurer les délais!

%% POUR LES SNR
% - autres études préalables (EEG / sEEG) : il semble qu'il y ait un shift
% de 2dB entre actif / passif
% - on peut estimer le seuil de perception autour de -7.5 dB en passif donc
% [-Inf;-10.5;-7.5;-4.5;0] en premier lieu

%% Changement de script avril 2024 --> décorrélation des stim auditifs et des questions
% car on voit dans la condition passive initiale des activations qui
% peuvent être de la préparation motrice ; hypothèse que le fait d'entendre
% le son, même en condition passive, fait préparer une réponse motrice à
% l'une des quatre tâches distractives qui suivent toujours le son (même si
% le délai est variable)

%% V1 : juste introduction d'une variabilité du nb de questions qui suivent un stim
% - pour l'instant soit 0, soit 1, soit 2 questions après un stim donné
% - en contrebalançant les types de question qui passent en position 2
% - mais on garde la séquence stim / question donc pas sûre d'être très
% efficace sur le contrôle de la préparation motrice lors du stim

%% V2 : enlever les questions ; on remplace par un changement de couleur de la croix de fixation
% - le sujet devra dire oralement en fin de bloc combien de fois la croix
% aura été d'une couleur donnée
% - enjeu ici = décorréler au maximum les changements de couleur des stims
% auditifs

%% V3 : le point rouge devient rare et un évènement spécifique distinct du reste

%% V4 : version corrigée avec Claire et Nathan  -- 25/04/224
% - changer boucle : point noir permanent puis randi --> changement couleur
% sur 0.2 sec ; puis randi --> avant ou après stim
% - randomisation d'une des 3 couleurs pour le dot
% - séparer black des autres couleurs sinon ça biaise les fréquences
% - la tâche sera : parmi 3 couleurs différentes du noir (bleu / vert / rouge), combien de fois
% est apparue brièvement (0.2 sec) l'une d'elles pour chaque bloc ?
% - rajouter à chaque bloc : nouvelle couleur à compter au prochain
% - feedback expérimentateur en fin de bloc
% - fréquence à adapter : obj entre 13 et 14 points par bloc (1/3)
% - les délais sont à adapter (rajouter des timestamps pour calculer les
% ISI notamment) + comparaison avec les autres conditions
% - enlever les datas inutiles relatives aux changements de couleur des
% autres versions
% - puis ré incorporer dans la version fMRI+eyelink

%% V5 : modif boucle en 2 boucles principales
% - 1 boucle avec proba 1/3 où on met le stim entre deux points de couleur
% potentiels
% - 1 boucle 'else' avec juste le stim


% -------------------------------------------------------------------------
%% Clear workspace
close all;
clear all;
clc;
sca;

%% Setups
PsychDefaultSetup(1);
dummymode=0;
%ppd = 32; %pixels per degree = per centimeter at 57cm distance
text_size = 65; %round(5*ppd); %(1.5*ppd);
black = [0 0 0];
white = [255 255 255];
grey = [128 128 128];
%blue = [0 0 255];
blue = [0 255 255]; %cyan
green = [0 255 0];
red = [255 0 0];
yellow = [255 255 0];
EXIT = 0; %for loop quit

%% Eyelink & Screen Setup

% Open a graphics window on the main screen
screenNumber=max(Screen('Screens')); %for computers + CENIR 2024
%screenNumber = 1; %for MRI CENIR
dimXwindow=800;
dimYwindow=500;
timeout = 1.00; % maximum fixation check time
tCorMin = 0.20; % minimum correct fixation time
%[window,screenRect] = Screen('OpenWindow', screenNumber, [128 128 128],[0 0 1600 1000]); %grey -- Julie's laptop
[window,screenRect] = Screen('OpenWindow', screenNumber, [128 128 128]); %grey -- full screen
%[window,screenRect] = Screen('OpenWindow', screenNumber, grey, [0 0 dimXwindow dimYwindow]); % for tests and debug ; [0 0 0] represents black color
Screen('TextSize',window, text_size);
[xCenter, yCenter] = RectCenter(screenRect);
[width, height] = Screen('WindowSize', screenNumber);
%Screen('Preference', 'SkipSyncTests', 1);
[screenWidth, screenHeight] = RectSize(screenRect); % doublon ??

%% NEW ----
% Define fixation dot colors
dotColors = {red, blue, green}; %{[255 255 255], [255 255 0], [0 0 255], [255 0 0]}; % yellow, white, blue, red
indexColors = [1, 2, 3];
nameColors  = {'rouge' , 'bleue', 'verte'};
% Define fixation dot size
dotSize = 10; %10;
% Define fixation dot position
dotX = xCenter;
dotY = yCenter;
% Define target Dot Appearance
%targetDotFrequency = 0.4; % Adjust as needed, e.g., every 20% of the trials
targetDotDuration = 0.2; % Duration of red dot appearance in seconds
% Define jittered delays for fixdot and auditory stimulus
min_delay_fixdot = 1; % Minimum delay for fixdot color flip (tampon avant / après chaque stim : 1 sec minimum)
max_delay_fixdot = 4.5; % Maximum delay for fixdot color flip

% Provide Eyelink with details about the graphics environment
el=EyelinkInitDefaults(window);

% Disable key output to Matlab window
ListenChar(2);

% Initialization of the connection with the Eyelink Gazetracker
if ~EyelinkInit(dummymode, 1)
    fprintf('Eyelink Init aborted.\n');
end
WaitSecs(0.001);

[v, vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

%Use CENIR's setup for Eyelink
LoadParameters;

% Restore keyboard output to Matlab:
ListenChar(0);

rad = 64; %MUST BE ADAPTED !!
% 40 if gazeRect=[xCenter-20 yCenter-20 xCenter+20 yCenter+20];
% 20 if gazeRect=[xCenter-10 yCenter-10 xCenter+10 yCenter+10];

if Eyelink('isconnected') ~= 1
    Eyelink('initialize');
else
    fprintf('\nEyelink is connected\n');
end

% Open Eyelink file to record data to
edfFile='cp_new33.edf';
Eyelink('Openfile', edfFile);

% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('Message', 'SYNCTIME');
%stopkey=KbName('space');
eye_used = -1;

%% Other setups
Current_directory = pwd;

% Stimuli and data setup
stimuli = {'A'; 'E'};
stimuli_nb = length(stimuli);
prompt = ('What is the staircase volume for this participant? \n\n');
vol_noise = input(prompt); %must be adapted to staircase >> enter subject's staircase value
noise_ramp_time = 1; %seconds needed to bring noise up or down
noise_ramp_steps = 10; %steps of volume variation
snr_levels_A = [-Inf;-10;-7.5;-5;-1];
snr_levels_E = [-Inf;-12.5;-10;-7;0];
snr_nb = length(snr_levels_A);
trials_per_cond = 4; %(CP: must = sum of questions per trial); 5 for full CA manip - nb of repetition within each block, for a given SNR and stimulus (trials / cond / block)
trials_per_block = trials_per_cond * snr_nb * stimuli_nb;
blocks_nb = 10; %type 8 for full manip ==> 9 (total = +1); +2 for CP (because less trials than CA): 10
trials_nb = (blocks_nb+1) * trials_per_block; %+1


%Answer keys // fMRI = B / Y / G / R
KbName('UnifyKeyNames');
%answer_keys = [KbName('b'),KbName('y')]; %for mri buttons
%scale_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')]; %for mri buttons
answer_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')];
validation_key = KbName('space'); %only for the experimenter
scan_key = KbName('t');
exit_key = KbName('escape');

%Timing, in secs
%Timing, in secs
timing_blockstart = 1; %wait for it at block begining (to be confirmed)
% ISI = soa + delay (soa : trial start - stim / delay : stim - next trial
% start) ; ISI must be 8-10
timing_soa = [3.5 5.5]; %[0.5 1]; %[3.5 5.5]; %MODIFIED [1 3] [2 4]
timing_delay = [3.5 5.5]; %[0.5 1]; %[3.5 5.5]; %NEW -- [7 9] [5 6]
timing_blockend = 2; %fixation at the end of block

%% Sound setups
%Noise files and loading
audiodir = 'Sounds/';
for i = 0:blocks_nb %to use different TEN file for each block
    audiofile_noise{i+1} = [audiodir 'LF_TEN_SPL_' num2str(i) '.wav'];
end
for i = 1:stimuli_nb
    audiofile_stim{i} = [audiodir char(stimuli(i)) '.wav'];
end
nrchannels = 2;
soundcardNumber = []; %for MRI or eyelink PC; depends on the device; Julie's laptop = 1; ThÃ©a's laptotp = 2

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

%% Experiment setup

%Compute subject number
prompt = ('\n Subject number? \n');
subject_nb = input(prompt);

%Preparing data
trial = (1:trials_nb)';
trial_in_block = repmat((1:trials_per_block)', blocks_nb+1,1);
block = kron((0:blocks_nb)', ones(trials_per_block,1));
stimulus_num = repmat((1:stimuli_nb)',trials_per_block/stimuli_nb,1); %produce a vertical array of 1 and 2 (if n = 2)  , corresponding to stim type
stimulus = repmat(stimuli,trials_per_block/stimuli_nb,1); %produce a vertical array of (A,E) * (nb trials)
snr_num = repmat(kron((1:snr_nb)', ones(stimuli_nb, 1)), trials_per_cond, 1); %produce a vertical array of repeating variables from 1 to 5 (= nb SNR), each one * 2 (= nb stim), 5 times (nb trials per cond)
snr_A = repmat(kron(snr_levels_A, ones(stimuli_nb,1)), trials_per_cond, 1);
snr_E = repmat(kron(snr_levels_E, ones(stimuli_nb,1)), trials_per_cond, 1);
vol_stim_A = vol_noise*10.^(snr_A/20) * rms_noise/rms_stim;
vol_stim_E = vol_noise*10.^(snr_E/20) * rms_noise/rms_stim;

% Randomize trial order and delays
trials_order = [];
for b = 0:blocks_nb
    trials_order = [trials_order randperm(trials_per_block)]; %returns a list of integers randomized in range (1:trials_per_block(here, 50)) for each block
end
stimulus_num = stimulus_num(trials_order);
stimulus = stimulus(trials_order);
snr_num = snr_num(trials_order);
snr_A = snr_A(trials_order);
snr_E = snr_E(trials_order);
vol_stim_A = vol_stim_A(trials_order);
vol_stim_E = vol_stim_E(trials_order);
soa_planned = [];
delay_planned = [];
for i = 1:trials_nb
    soa_planned = [soa_planned;timing_soa(1)+rand*range(timing_soa)]; %returns a list with random timings in prespecified range (here, timing_soa = [8 12])
    %NB: rand returns by default a random floating number between 0 and 1.
    delay_planned = [delay_planned;timing_delay(1)+rand*range(timing_delay)];
end

% Prepare results' table to store the data -- add actual timings of the fixation cross color changings
trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, ...
    snr_A, snr_E, vol_stim_A, vol_stim_E, soa_planned, delay_planned);
% Randomize TargetColor for each block (3 options)
for b = 0:blocks_nb
    targetColor = randi(3);
    for c = 1:trials_per_block
        trials.target_color(trials.trial_in_block == c & trials.block == b) = targetColor;
    end
end
trials.time_start = nan(trials_nb, 1);
trials.soa_real = nan(trials_nb, 1);
trials.time_stim = nan(trials_nb, 1);
trials.scan_start = nan(trials_nb, 1);
trials.onset_start = nan(trials_nb, 1);
trials.onset_stim = nan(trials_nb, 1);
trials.duration = nan(trials_nb, 1);
trials.staircase_vol = nan(trials_nb, 1);
trials.ending = nan(trials_nb, 1);
% NEW
trials.delay_real = nan(trials_nb, 1);
trials.isi = nan(trials_nb,1);
trials.time_targetDot = nan(trials_nb, 1);
trials.onset_targetDot = nan(trials_nb, 1);
trials.offset_targetDot = nan(trials_nb, 1);
trials.duration_targetDot = nan(trials_nb, 1);
trials.delay_targetDot = nan(trials_nb,1);
trials.targetDot = zeros(trials_nb,1);
trials.color_targetDot = cell(trials_nb,1);
%
add_file = table(block, trial_in_block, trial);
add_file.startblock = nan(trials_nb, 1); %beginning of each block
add_file.endblock = nan(trials_nb, 1); %end of each block
add_file.startexp = nan(trials_nb, 1); %beginning of the experiment
add_file.endexp = nan(trials_nb, 1); %end of the experiment

%% Set up screen

%Starting
message = 'Prêt à démarrer.';
DrawFormattedText(window, message, 'center', 'center', black);
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

if EXIT
    fprintf('\n ESCAPE key pressed \n');
    clear all
end

%% Starting...

starttime = datetime;
add_file.startexp(1) = GetSecs;
Eyelink('message', 'experiment_start');
PsychPortAudio('Start', pamaster, 0); %infinite repetitions
fprintf('Starting audio.\n');
last_block = 0; % Keeping track of block change
% Prepare to count the dot colors
color_count_red = cell(blocks_nb+1,1);
color_count_blue = cell(blocks_nb+1,1);
color_count_green = cell(blocks_nb+1,1);
%% Loop for all trials

%Adding a line at each trial so it can be recorded even if the experiment
%stops
filename_base = fullfile(...
    Current_directory,...
    sprintf('Subject_%d_%s_%s', subject_nb, datestr(starttime, 'yyyy-mm-dd_HH-MM')));
filename_csv = [filename_base '.csv'];
filename_mat = [filename_base '.mat'];

Fixation = {};

Start_time = GetSecs;

for i=1:trials_nb %_per_block
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
            % Display fixation performance of last block
            for z = 1:trials_per_block
                fix_moy(z) = mean(Fixation{trials.block(i-1)+1,z},'omitnan');
            end
            fix_moy_block = mean(fix_moy, 'omitnan');
            fprintf('\n\n\n Mean correct fixation during last block: %.2f percent \n\n\n', fix_moy_block * 100)
            % Add feedback for the experimenter
            if trials.target_color(i-1) == 1
                frequency_this_block = sum(color_count_red{trials.block(i-1)+1});
            elseif trials.target_color(i-1) == 2
                frequency_this_block = sum(color_count_blue{trials.block(i-1)+1});
            elseif trials.target_color(i-1) == 3
                frequency_this_block = sum(color_count_green{trials.block(i-1)+1});
            end
            total_dots_this_block = sum(color_count_red{trials.block(i-1)+1}) + sum(color_count_blue{trials.block(i-1)+1}) + sum(color_count_green{trials.block(i-1)+1});
            fprintf('\n\n\n Pendant ce bloc il y a eu %i point(s) de couleur %s \n\n Et un total de %i points de couleur \n\n', frequency_this_block, nameColors{trials.target_color(i-1)}, total_dots_this_block);
            %Display fixation
            fprintf('%d secondes de fixation... ', timing_blockend);
            Screen('DrawDots', window, [xCenter; yCenter], dotSize, black, [], 2);
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
                ' fini.\n\n Préparation du prochain bloc...'];
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
        %--- Announce next block ---
        if trials.block(i) == 0
            message = ['Prochain bloc = ' num2str(trials.block(i)) '/' num2str(blocks_nb)];
        else
            message = ['Combien avez-vous compté de points de couleur ' nameColors{trials.target_color(i-1)} ' ? \n\n\n Prochain bloc = ' num2str(trials.block(i)) '/' num2str(blocks_nb)];
        end
        message = [message '\n\n\n Compter les points de couleur ' nameColors{trials.target_color(i)} '\n\n\n Appuyer sur 1 pour commencer le bloc \n\n\n'];
        fprintf(message);
        DrawFormattedText(window, message, 'center', yCenter/2, black);
        Screen('Flip', window);
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

        %Wait for experimenter to press SPACE and for scan to start (ie, keypress 't')
        message = 'Le bloc va bientôt commencer...';
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

        %% BLOCK START
        startblocktime = datetime;
        add_file.startblock(i) = GetSecs;
        Eyelink('message', 'start of block %i / %i', trials.block(i), blocks_nb);
        Eyelink('message', 'target color this block : number ', trials.target_color(i));
        fprintf('\n\n %s ---Bloc %d \n', datestr(startblocktime, 'HH:MM:SS'), trials.block(i));
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
    if trials.trial_in_block(i) ~= 1
        trials.delay_real(i-1) = trials.time_start(i) - trials.time_stim(i-1);
        trials.isi(i-1) = trials.delay_real(i-1) + trials.soa_real(i-1);
    end

    %% CHANGES ++
    target_dot = 0; before = 0; after = 0;
    % Is it time to display a colored target dot ?
    if trials.trial_in_block(i) ~= 1 && randi(3) == 1
        if randi(2) == 1
            %change either before or after stim
            before = 1;
        else
            after = 1;
        end
        if before == 1 % before stim (50%)
            newColorIndex = randi(numel(dotColors)); % rajouter une boucle pour éviter de compter le noir
            newColor = dotColors{newColorIndex};
            target_dot = 1;
            % Draw the fixation dot with the new color
            Screen('DrawDots', window, [dotX; dotY], dotSize, newColor, [], 2);
            Screen('Flip', window);
            targetDotOnset = GetSecs; % Record the onset time of the red dot
            Eyelink('message', 'target dot -- trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb')
            WaitSecs(targetDotDuration); % Wait for the specified duration
            % Clear the target dot
            Screen('DrawDots', window, [dotX; dotY], dotSize, black, [], 2); % back to black
            Screen('Flip', window);
            redDotOffset = GetSecs; % Record the offset time of the red dot
            trials.targetDot(i) = -1;
            % Jittered delay after flipping fixdot color
            WaitSecs(min_delay_fixdot + rand() * (max_delay_fixdot - min_delay_fixdot));
        else
            % Draw the fixation dot with the current color
            Screen('DrawDots', window, [dotX; dotY], dotSize, black, [], 2);
            Screen('Flip', window);
        end
        % Display auditory stim + check fixation
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
        Eyelink('message', 'auditory stim, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);

        % check fixation during stim
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
                        fprintf('\n\n eyelink data invalid \n\n');
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

        if after == 1 % after stim
            % Randomly select a new color for the fixation dot
            newColorIndex = randi(numel(dotColors));
            newColor = dotColors{newColorIndex};
            target_dot = 1;
            % Jittered delay before flipping fixdot color
            WaitSecs(min_delay_fixdot + rand() * (max_delay_fixdot - min_delay_fixdot));
            % Draw the fixation dot with the new color
            Screen('DrawDots', window, [dotX; dotY], dotSize, newColor, [], 2);
            Screen('Flip', window);
            targetDotOnset = GetSecs; % Record the onset time of the red dot
            Eyelink('message', 'target dot -- trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb');
            WaitSecs(targetDotDuration); % Wait for the specified duration
            % Clear the red dot
            Screen('DrawDots', window, [dotX; dotY], dotSize, black, [], 2);
            Screen('Flip', window);
            redDotOffset = GetSecs; % Record the offset time of the red dot
            trials.targetDot(i) = 1;
        end
    else % no target dot this time
        % Draw the fixation dot with the current color
        Screen('DrawDots', window, [dotX; dotY], dotSize, black, [], 2);
        Screen('Flip', window);
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
        Eyelink('message', 'auditory stim, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
    end
            % check fixation during stim
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
                        fprintf('\n\n eyelink data invalid \n\n');
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
        WaitSecs(0.2);
        PsychPortAudio('Stop', pastim);

        % if a target dot was displayed, record data about it
        if target_dot == 1
        disp('--> A colored dot has appeared !')
        trials.time_targetDot(i) = targetDotOnset;
        trials.onset_targetDot(i) = trials.time_targetDot(i) - trials.scan_start(i);
        trials.offset_targetDot(i) = redDotOffset;
        trials.duration_targetDot(i) = redDotOffset - targetDotOnset;
        trials.delay_targetDot(i) = abs(targetDotOnset - trials.time_stim(i)); % Calculate the delay
        trials.color_targetDot{i} = nameColors{newColorIndex};
        if newColorIndex == 1
            color_count_red{trials.block(i)+1} = [color_count_red{trials.block(i)+1} 1];
        elseif newColorIndex == 2
            color_count_blue{trials.block(i)+1} = [color_count_blue{trials.block(i)+1} 1];
        elseif newColorIndex == 3
            color_count_green{trials.block(i)+1} = [color_count_green{trials.block(i)+1} 1];
        end
    end
    Limit = trials.time_stim(i) + trials.delay_planned(i);
    while GetSecs < Limit
        WaitSecs(.004);
    end
    %% End of trial
    trials.ending(i) = GetSecs;
    trials.staircase_vol(i) = vol_noise;
    writetable(trials, filename_csv);
    save(filename_mat,'trials');

    % Send Infos about current trial to Eyelink File
    Eyelink('message', 'snr_num = %i, trials.snr_num(i), trial %i / %i _ block %i / %i',trials.snr_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    Eyelink('message', 'vowel = %i, trial %i / %i _ block %i / %i', trials.stimulus_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    if target_dot == 1
        Eyelink('message', 'target dot : color nb ',newColorIndex);
    end
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
    trials.duration(i) = GetSecs - trials.time_start(i); %is it relevant?
end

%% WRAP UP AND LEAVE
endtime = datetime;
add_file.endexp(i) = GetSecs;
Eyelink('message', 'experiment_end');

% Feedback for last block
if trials.target_color(i-1) == 1
    frequency_this_block = sum(color_count_red{trials.block(i-1)+1});
elseif trials.target_color(i-1) == 2
    frequency_this_block = sum(color_count_blue{trials.block(i-1)+1});
elseif trials.target_color(i-1) == 3
    frequency_this_block = sum(color_count_green{trials.block(i-1)+1});
end
total_dots_this_block = sum(color_count_red{trials.block(i-1)+1}) + sum(color_count_blue{trials.block(i-1)+1}) + sum(color_count_green{trials.block(i-1)+1});
fprintf('\n\n\n Pendant ce bloc il y a eu %i point(s) de couleur %s \n\n Et un total de %i points de couleur \n\n', frequency_this_block, nameColors{trials.target_color(i-1)}, total_dots_this_block);

% Announce end of experiment & close audio devices
fprintf('\nExpérience terminée, durée = %s\n\n', datestr(endtime-starttime, 'HH:MM:SS')); %Overall stats:\n', datestr(endtime-starttime, 'HH:MM:SS'));
DrawFormattedText(window, 'Expérience terminée, merci !', 'center', 'center', black);
Screen('Flip', window);
PsychPortAudio('Stop', pamaster);
PsychPortAudio('DeleteBuffer');
PsychPortAudio('Close', pamaster);

%% Record data // add timestamp
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

% finish up: stop recording eye-movements, close graphics window, close data file and shut down tracker
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

%%
%%%%%%%%
%%% Close
%%%%%%%%

WaitSecs(2);
Screen('CloseAll');
