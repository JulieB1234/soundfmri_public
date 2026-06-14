%Passive Condition -- fMRI (juliechezboyer@wanadoo.fr) -- april 2022

%% POUR LES ISI
% - pour homog�n�iser les dur�es entre les diff�rents types d'essais,
% rajouter un d�lai aux questions type 'RT' et 'None'
% - piloter dur�es pour questions type 'None' et 'RT', pour objectif:
% moyenne globale autour de 9 sec (sachant que la moyenne quiz / mw est �
% 11.3)

%% POUR LE NB D'ESSAIS
% - contrainte: ce doit �tre un multiple du nb de questions (4)
% - actuellement: on garde 4 essais / condition / bloc mais on essaie
% d'augmenter le nb de blocs (11?) mais en faisant des pilotes
% comportementaux pr�alables avec les nouveax timestamps pour pouvoir bien
% mesurer les d�lais!

%% POUR LES SNR
% - autres �tudes pr�alables (EEG / sEEG) : il semble qu'il y ait un shift
% de 2dB entre actif / passif
% - on peut estimer le seuil de perception autour de -7.5 dB en passif donc
% [-Inf;-10.5;-7.5;-4.5;0] en premier lieu

% -------------------------------------------------------------------------
%%
%Clear workspace
close all;
clear all;
clc;
sca;

% calib;

PsychDefaultSetup(1);
dummymode=0;
black = [0 0 0];
white = [255 255 255];
grey = [128 128 128];
blue = [0 0 255];
green = [0 255 0];
red = [255 0 0];
yellow = [255 255 0];


%% ---- Eyelink Setup ----
% Open a graphics window on the main screen
%screenNumber=max(Screen('Screens')); %for computers
screenNumber = 1; %for MRI CENIR
dimXwindow=800;
dimYwindow=500;
%[window,screenRect] = Screen('OpenWindow', screenNumber, [], [0 0 dimXwindow dimYwindow]); %for tests and debug
[window, screenRect] = Screen('OpenWindow', screenNumber); %full screen
[xCenter, yCenter] = RectCenter(screenRect);
timeout = 1.00; % maximum fixation check time
tCorMin = 0.20; % minimum correct fixation time
% Setting the proper recording resolution, proper calibration type,
% as well as the data file content;
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
blue = [0 0 255];
green = [0 255 0];
red = [255 0 0];
yellow = [255 255 0];
rad = 64; %MUST BE ADAPTED !!
% 40 if gazeRect=[xCenter-20 yCenter-20 xCenter+20 yCenter+20];
% 20 if gazeRect=[xCenter-10 yCenter-10 xCenter+10 yCenter+10];

if Eyelink('isconnected') ~= 1
    Eyelink('initialize');
else
    fprintf('\nEyelink is connected\n');
end

% Open Eyelink file to record data to
edfFile='cp1.edf';
Eyelink('Openfile', edfFile);

% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('Message', 'SYNCTIME');
%stopkey=KbName('space');
eye_used = -1;

%% --- Other setups ---
% Complementary screen setup
ppd = 32;
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
%snr_levels = [-Inf;-11;-9;-7;-3]; %in dB
%snr_levels = -3; %test
%snr_levels = [-Inf;-10.5;-3]; %for MRI 1st pilot
%snr_levels = [-Inf;-11.5;-9.5;-7.5;-3]; %full manip for active condition
%snr_levels = [-Inf;-10.5;-7.5;-4.5;0]; %full manip CP for 1st complete CP pilot
% snr_levels = [-10.5;0];
% snr_nb = length(snr_levels);
snr_levels_A = [-Inf;-10;-7.5;-5;-1];
snr_levels_E = [-Inf;-12.5;-10;-7;0];
snr_nb = length(snr_levels_A);
trials_per_cond = 4; %(CP: must = sum of questions per trial); 5 for full CA manip - nb of repetition within each block, for a given SNR and stimulus (trials / cond / block)
trials_per_block = trials_per_cond * snr_nb * stimuli_nb;
blocks_nb = 10; %type 8 for full manip ==> 9 (total = +1); +2 for CP (because less trials than CA): 10
trials_nb = (blocks_nb+1) * trials_per_block; %+1

% --- Setup questions ---
%Types of questions that can end each trial
question_types = {'Quiz', 'RT', 'MindWander', 'None'};
question_types_nb = length(question_types);
%Number of questions of each type (sum must = trials_per_cond)
question_per_cond = [1; 1; 1; 1];
%Follow question with 'Cliquer pour poursuivre' ?
question_pause = [0; 1; 0; 1];
% -- Quiz questions --
quizfile = 'Quiz.csv';
fileID = fopen(quizfile, 'r', 'n', 'UTF-8');
%fileID = fopen(filename,permission,machinefmt,encodingIn) additionally
%specifies the order for reading or writing bytes or bits in the file using
%the machinefmt argument. 'r' input specifies read access, 'n' input
%specifies native byte ordering.
%The optional encodingIn argument specifies the
%character encoding scheme associated with the file. UTF-8 is a variable-width
%character encoding used for electronic communication;name is derived
%from Unicode (or Universal Coded Character Set) Transformation Format ? 8-bit
quizlist = textscan(fileID, '%s%s%s%s%s%s%[^\n\r]', 'Delimiter', ';', ...
    'ReturnOnError', false);
%returns a cell array with 6 cells containing column vectors of the strings
%of each column of the Quiz.csv file; e.g., quizlist{1,1} is the list of
%all the 283 questions of the quiz
fclose(fileID);
quizlist = [quizlist{1:end-1}];
%returns a 283 x 6 cell array with all columns of the Quiz.csv file by
%concatenating all previously created cells
quizlist = quizlist(randperm(size(quizlist,1)),:);
%size(quizlist,1) returns the size of the 1st dimension, i.e. 283;
%randperm(283) returns a pseudo randomized array of integers between 1 and
%283 quizlist(1:n,:) returns all columns of rows from 1 to n.
% -- Mind wandering question --
mindwander_text = 'Qu aviez-vous en tete � l instant ?';
mindwander_levels = {'Le son', 'L environnement', 'Mes pens�es', 'Rien / Je m endors'};
mindwander_nb = length(mindwander_levels);
%mindwander_percent = .2; %how often to present it
%mindwander_per_block = round(trials_per_block*mindwander_percent);

% --- Answer options ---
% -- grid --
%rect_height = 3*ppd;
%rect_width = 7*ppd;
%rect_margin = round(.5*ppd);
rect_height = 9*ppd;
rect_width = 21*ppd;
rect_margin = round(1.5*ppd);
answer_rect = [
    -rect_margin-rect_width, rect_margin, -rect_margin-rect_width, rect_margin;
    -rect_margin-rect_height, -rect_margin-rect_height, rect_margin, rect_margin;
    -rect_margin, rect_margin+rect_width, -rect_margin, rect_margin+rect_width;
    -rect_margin, -rect_margin, rect_margin+rect_height, rect_margin+rect_height];
% -- linear scale --
scale_cursor = 1*ppd;
scale_width = scale_cursor*mindwander_nb;
scale_height = scale_cursor*2;
%scale_rect = [-scale_width/2-1, -scale_height/2, scale_width/2+1, scale_height/2];

%Answer keys // fMRI = B / Y / G / R
KbName('UnifyKeyNames');
%answer_keys = [KbName('b'),KbName('y')]; %for mri buttons
%scale_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')]; %for mri buttons
answer_keys = [KbName('b'), KbName('y'), KbName('g'), KbName('r')];
validation_key = KbName('space'); %only for the experimenter
scan_key = KbName('t');
exit_key = KbName('escape');

%Timing, in secs
timing_blockstart = 1; %wait for it at block begining (to be confirmed)
timing_soa = [1 3]; %for MRI, fixation [1 3] - stim - qdelay 5 sec; total ISI must be around 10 (to be confirmed)
timing_qdelay = [4 6]; %to be confirmed
timing_rtmax = 4; %to be confirmed (3 in CA) >> 4 or 4.25??
timing_rtmaxquiz = 5;
timing_resphl = .2; %time to highlight selected answer
timing_blockend = 2; %fixation at the end of block
%timing_extraITI = .5; %additional time before next trial after quiz ?

%Noise files and loading
audiodir = 'Sounds/';
for i = 0:blocks_nb %to use different TEN file for each block
    audiofile_noise{i+1} = [audiodir 'LF_TEN_SPL_' num2str(i) '.wav'];
end
for i = 1:stimuli_nb
    audiofile_stim{i} = [audiodir char(stimuli(i)) '.wav'];
end

nrchannels = 2;

soundcardNumber = []; %for MRI or eyelink PC; depends on the device; Julie's laptop = 1; Théa's laptotp = 2

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

%Preparing data
trial = (1:trials_nb)';
trial_in_block = repmat((1:trials_per_block)', blocks_nb+1,1);
block = kron((0:blocks_nb)', ones(trials_per_block,1));
stimulus_num = repmat((1:stimuli_nb)',trials_per_block/stimuli_nb,1); %produce a vertical array of 1 and 2 (if n = 2)  , corresponding to stim type
stimulus = repmat(stimuli,trials_per_block/stimuli_nb,1); %produce a vertical array of (A,E) * (nb trials)
snr_num = repmat(kron((1:snr_nb)', ones(stimuli_nb, 1)), trials_per_cond, 1); %produce a vertical array of repeating variables from 1 to 5 (= nb SNR), each one * 2 (= nb stim), 5 times (nb trials per cond)
%snr = repmat(kron(snr_levels, ones(stimuli_nb,1)), trials_per_cond, 1); %produce a vertical array of repeating pairs of SNR levels, 5 times (nb trials per cond)
%must be adapted to staircase
snr_A = repmat(kron(snr_levels_A, ones(stimuli_nb,1)), trials_per_cond, 1);
snr_E = repmat(kron(snr_levels_E, ones(stimuli_nb,1)), trials_per_cond, 1);
%we'll add a correction factor for letter 'E' to compensate for the
%psychometric shift between both functions (2.5 ?)
%stimulus volum computed separately for A et E so we can compensate for
%psychometric shift
% vol_stim_A = vol_noise*10.^(snr/20) * rms_noise/rms_stim;
% vol_stim_E = vol_noise*10.^((snr-2.5)/20) * rms_noise/rms_stim;
%vol_stim = vol_noise*10.^(snr/20) * rms_noise/rms_stim; %converting SNR from dB to volume, i.e. signal amplitude
vol_stim_A = vol_noise*10.^(snr_A/20) * rms_noise/rms_stim;
vol_stim_E = vol_noise*10.^(snr_E/20) * rms_noise/rms_stim;

%Add appropriate number of question types to each combination of SNR /
%stimulus
question_num = [];
for q = 1:question_types_nb
    question_num = [question_num; kron(q, ones(snr_nb*stimuli_nb*question_per_cond(q), 1))];
end
%returns a column vector of 10 (2x5x1) times each value of q

soa_planned = [];
qdelay_planned = [];
for i = 1:trials_nb
    soa_planned = [soa_planned;timing_soa(1)+rand*range(timing_soa)]; %returns a list with random timings in prespecified range (here, timing_soa = [8 12])
    %NB: rand returns by default a random floating number between 0 and 1.
    qdelay_planned = [qdelay_planned;timing_qdelay(1)+rand*range(timing_qdelay)];
end

%Randomizing answer orders
% possible_orders = perms(1:stimuli_nb); %2*2 matrix (because there are 2 stimuli) with possible orders, i.e. 1 2 or 2 1
% per_block_answer_order = repmat(possible_orders, floor(blocks_nb-length(possible_orders)), 1); %floor returns closest integer < or = to floating number (i'm not sure what the point is, since its argument is an operation of integers)
% per_block_answer_order = [per_block_answer_order;possible_orders(1:blocks_nb-length(per_block_answer_order), :)];
% per_block_answer_order = per_block_answer_order(randperm(blocks_nb),:); %randperm(N) returns a vector containing a random permutation of the integers 1:N.  For example, randperm(6) might be [2 4 5 6 1 3].
% training_block_answer_order = [1:stimuli_nb];
% per_block_answer_order = [training_block_answer_order;per_block_answer_order];
% answer_order = kron(per_block_answer_order, ones(trials_per_block, 1)); %returns a 200*2 matrix of 1s and 2s (either 1,2 or 2,1), for stim nb = 2 and 50 trials / block

%Randomizing trials order within each block
trials_order = [];
for b = 0:blocks_nb
    mindwander_inarow = 3;
    while mindwander_inarow > 2 %reject randomization with 3 MindWander questions together
        trials_order_this_block = randperm(trials_per_block);
        %compute number of MindWandering questions in a row
        question_tmp = question_types(question_num(trials_order_this_block));
        mindwander_inarow = 0;
        inarow = 0;
        for i = 1:length(question_tmp)
            if strcmp(question_tmp{i}, 'MindWander')
                inarow = inarow + 1;
            else
                mindwander_inarow = max(mindwander_inarow, inarow);
                inarow = 0;
            end
        end
    end
    trials_order = [trials_order trials_order_this_block];
    %returns a list of integers randomized in range
    %(1:trials_per_block(here, 40)) for each block, provided there aren't
    %>2 MindWander questions in a row
end

stimulus_num = stimulus_num(trials_order);
stimulus = stimulus(trials_order);
snr_num = snr_num(trials_order);
%snr = snr(trials_order);
snr_A = snr_A(trials_order);
snr_E = snr_E(trials_order);
%vol_stim = vol_stim(trials_order);
vol_stim_A = vol_stim_A(trials_order);
vol_stim_E = vol_stim_E(trials_order);
question_num = question_num(trials_order);

%Add question text and answer options
question = (question_types(question_num))'; %returns a 360x1 cell array with randomised question types
pause = question_pause(question_num); %returns a 360x1 column vector of randomised (in the same random order) 1s and 0s
question_text = cell(trials_nb, 1);
question_options = cell(trials_nb, 1);
question_correct = zeros(trials_nb, 1);
iquiz = 1;
for i = 1:trials_nb
    switch question{i}
        case 'Quiz'
            if iquiz > length(quizlist) %we reached the end of available quizs
                disp('!! warning: end of quizs reached !!');
                quizlist = quizlist(randperm(size(quizlist,1)),:); %so we randomize and start again
                iquiz = 1;
            end
            question_text{i} = quizlist(iquiz,1);
            question_options{i} = quizlist(iquiz,2:end-1);
            question_correct(i) = str2num(cell2mat(quizlist(iquiz,end)));
            iquiz = iquiz + 1;
        case 'MindWander'
            question_text{i} = mindwander_text;
            question_options{i} = mindwander_levels;
    end
end

% switch / case evaluates an expression and chooses to execute one of
%several groups of statements. Each choice is a case. The switch block
%tests each case until one of the case expressions is true. A case is true
%when:
% For numbers, case_expression == switch_expression.
% For character vectors, strcmp(case_expression,switch_expression) == 1.
% For objects that support the eq function, case_expression == switch_expression.
%For a cell array case_expression, at least one of the elements of the cell array
%matches switch_expression, as defined above for numbers, character vectors, and objects.
%When a case expression is true, MATLAB� executes the corresponding statements
%and exits the switch block. An evaluated switch_expression must be a
%scalar or character vector. An evaluated case_expression must be a scalar,
%a character vector, or a cell array of scalars or character vectors.
% The otherwise block is optional. MATLAB executes the statements only when no case is true.

%I'm having trouble recording the answers because matlab won't assign a
%string with > 1 character in trials.answer(i); so in the maintime here is
%a 1-letter code to compute the MindWandering probe answer with only the
%first letter:
% - S = 'le son', answer 1
% - E = 'l'environnement', answer 2
% - P = 'mes pens�es', answer 3
% - R = 'rien / je m'endors', answer 4

%Defining result data
%trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, snr, vol_stim, soa_planned, qdelay_planned, answer_order);
% trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, ...
%     snr, vol_stim_A, vol_stim_E, question_num, question, pause, soa_planned, ...
%     qdelay_planned, question_text, question_options, question_correct);
trials = table(block, trial_in_block, trial, stimulus_num, stimulus, snr_num, ...
    snr_A, snr_E, vol_stim_A, vol_stim_E, question_num, question, pause, soa_planned, ...
    qdelay_planned, question_text, question_options, question_correct);

trials.time_start = nan(trials_nb, 1);
trials.soa_real = nan(trials_nb, 1);
trials.time_stim = nan(trials_nb, 1);
trials.scan_start = nan(trials_nb, 1);
trials.onset_start = nan(trials_nb, 1);
trials.onset_stim = nan(trials_nb, 1);
trials.duration = nan(trials_nb, 1);
trials.qdelay_real = nan(trials_nb, 1);
trials.time_quest = nan(trials_nb, 1);
trials.time_pause = nan(trials_nb, 1);
trials.answer_num = nan(trials_nb, 1);
trials.answer = repmat(char(0), trials_nb, 1);
trials.correct = nan(trials_nb, 1);
trials.rt1 = nan(trials_nb, 1);
trials.rt2 = nan(trials_nb, 1);
trials.staircase_vol = nan(trials_nb, 1);
trials.ending = nan(trials_nb, 1);

add_file = table(block, trial_in_block, trial);
add_file.startblock = nan(trials_nb, 1); %beginning of each block
add_file.endblock = nan(trials_nb, 1); %end of each block
add_file.startexp = nan(trials_nb, 1); %beginning of the experiment
add_file.endexp = nan(trials_nb, 1); %end of the experiment

mw_list = {'S' 'E' 'R' 'P'};

%%
%Set up screen
% Screen('Preference', 'SkipSyncTests', 1);
% dimXwindow=800;
% dimYwindow=500;
% if Comp
%     %[window, screenRect] = Screen('OpenWindow', screenNumber, background, [0 0 dimXwindow dimYwindow], 32); %for tests and debug
%     [window, screenRect] = Screen('OpenWindow', screenNumber, background, [],32);
% end
% if MRI
%     [window, screenRect] = Screen('OpenWindow', screenNumber, background, [],32); %full screen
% end
% [screenWidth, screenHeight] = RectSize(screenRect);
% [xCenter, yCenter] = RectCenter(screenRect);

%center answer rectangles
answer_rect = answer_rect+repmat([xCenter;yCenter], 2, mindwander_nb);
%scale_rect = scale_rect+repmat([xCenter;yCenter], 1, 2); %useless??
Screen('TextSize', window, text_size);
%%

%Starting
message = 'Pr�t � d�marrer.';
%fprintf(message);
DrawFormattedText(window, message, 'center', 'center', black);
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

if EXIT
    fprintf('\n ESCAPE key pressed \n');
    clear all
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
            %Display results of first block
            varfun(@mean, trials(trials.block==last_block & strcmp(trials.question, 'RT'),:),...
                'InputVariables', {'rt1'})
            varfun(@sum, trials(trials.block==last_block & strcmp(trials.question, 'Quiz'),:), ...
                'InputVariables', {'correct'})
            disp('Mind wandering answers: ');
            varfun(@length, trials(trials.block == last_block & ...
                strcmp(trials.question, 'MindWander'),:), 'GroupingVariables', ...
                'answer_num', 'InputVariables', {'answer_num'});

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
                ' fini.\n\n Pr�paration du prochain bloc...'];
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
        message = ['Prochain bloc = ' num2str(trials.block(i)) '/' num2str(blocks_nb)];
        message = [message '\n\n\n Appuyer sur 1 pour commencer le bloc. \n\n\n']; %adapt keypress to fMRI
        %message = [message '\n\nTouches r�ponse \n\n\n - Q1: \n'];
        %         for j = 1:stimuli_nb %for keyboard answers
        %             message = [message char(KbName(answer_keys(j))) '=' char(stimuli(trials.answer_order(i,j))) ' '];
        %         end
        %for j = 1:stimuli_nb
        %    message = [message num2str(j) ' = ' char(stimuli(trials.answer_order(i,j))) '  '];
        %end
        %message = [message '\n\n - Q2: de gauche � droite = 1 / 2 / 3 / 4'];
        fprintf(message);
        DrawFormattedText(window, message, 'center', yCenter/2, black);
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

        %Wait for experimenter to press SPACE and for scan to start (ie, keypress 't')
        message = 'Le bloc va bient�t commencer...';
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
        %ITI = 0;
        startblocktime = datetime;
        add_file.startblock(i) = GetSecs;
        Eyelink('message', 'start of block %i / %i', trials.block(i), blocks_nb);
        %WaitSecs(ITI); %will be set to non-zero after quiz questions ?
        %ITI = 0;
        fprintf('\n\n %s ---Bloc %d \n', datestr(startblocktime, 'HH:MM:SS'), trials.block(i));
        %         Screen('DrawDots', window, [xCenter;yCenter], 10, black, [], 2);
        %         Screen('Flip', window);
        %I suppressed the fixation point because we don't want it to happen earlier
        %fort blocks beginnings than for other trials
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
    %fprintf('\n Block %d/%d Trial %2d/%d: %+3.0f | %s', trials.block(i), blocks_nb, trials.trial_in_block(i), trials_per_block, trials.snr(i), char(trials.stimulus(i)));
    fprintf('\n Block %d/%d Trial %2d/%d: %+3.1f | %s', trials.block(i), blocks_nb, trials.trial_in_block(i), trials_per_block, trials.snr_num(i), char(trials.stimulus(i)));
    trials.time_start(i) = GetSecs; %recording trial start time
    Eyelink('message', 'trial_start, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
    %setup eyelink timings
    %     timeout = trials.soa_planned(i) + trials.qdelay_planned(i) + 0.2;
    %     tCorMin = 0.2;
    %     tstart=GetSecs;
    %     cor=0;
    %     corStart=0;
    %     tCor=0;
    %     t=tstart;

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

    %%

    % ----- Question -----
    fprintf([' - ' trials.question{i} ' -> ']);
    Eyelink('message', 'question, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
    if ismember(trials.question{i}, {'Quiz','MindWander'})
        %display answer options
        if strcmp (trials.question{i},'Quiz')
            answer_nb = length(trials.question_options{i});
        else
            answer_nb = mindwander_nb;
        end
        DrawFormattedText(window, char(question_text{i}), 'center',...
            yCenter-(rect_height+3*rect_margin+text_size), black);
        Screen('FrameRect', window, black, answer_rect);
        for j = 1:answer_nb
            DrawFormattedText(window, char(question_options{i}{j}),...
                'center', 'center', black, [],[],[],[],[], answer_rect(:,j)');
        end
        Screen('Flip', window, 0,1); %don t clear = 1 (keep rectangles at next flip)
    elseif strcmp(trials.question{i}, 'RT') %if question type is 'RT', display green circle
        Screen('DrawDots', window, [xCenter;yCenter], 50, green, [], 2);
        Screen('Flip', window);
    end
    
    trials.time_quest(i) = GetSecs;
    trials.qdelay_real(i) = trials.time_quest(i) - trials.time_stim(i);

    % ----- Response -----
    if ~strcmp(trials.question{i}, 'None') %for questions of quiz, mindwandering, and RT: wait for answer
        if strcmp(trials.question{i}, 'Quiz')
            rtmax = timing_rtmaxquiz;
        else
            rtmax = timing_rtmax;
        end
        while GetSecs-trials.time_quest(i) < rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(answer_keys))
                    Eyelink('message', 'keypress, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
                    if ismember(trials.question{i}, {'Quiz', 'MindWander'})
                        trials.answer_num(i) = find(keys(answer_keys), 1);
                        trials.correct(i) = (...
                            (trials.answer_num(i) == trials.question_correct(i))...
                            | trials.question_correct(i)== 0); %0 when there is no right answer, e.g., 'pick your favorite color' or MindWandering
                        if ismember(trials.question{i}, {'MindWander'})
                            for k = 1:answer_nb
                                if keys(answer_keys(k))
                                    trials.answer(i) = char(mw_list(k));
                                end
                            end
                        end
                        break
                    elseif ismember(trials.question{i},{'RT'})
                        trials.answer_num(i) = 0;
                        trials.correct(i) = 1;
                        break
                    end
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
                KbReleaseWait(-1);
            else
                WaitSecs(.004);
            end
        end

        trials.rt1(i) = keytime-trials.time_quest(i);
        writetable(trials, filename_csv);
        save(filename_mat,'trials');

        %report and HL selected answer
        if ismember(trials.question{i}, {'Quiz', 'MindWander'})
            if ~isnan(trials.answer_num(i))
                fprintf('%d (%s) %d', trials.answer_num(i),...
                    char(trials.question_options{i}{trials.answer_num(i)}),...
                    trials.correct(i));
                feedback_thickness = 6;
                Screen('FrameRect', window, black, ...
                    answer_rect(:,trials.answer_num(i))', feedback_thickness);
            else
                fprintf('Too late!');
                %add a Screen('FrameRect') ? in case it is needed for next
                %line; but we don't want no negative feedback so don't change
                %anything to the screen
            end
            Screen('Flip', window, 0,1); %1 = don't clear rectangles
            WaitSecs(timing_resphl);
        end
        %give correct answer to the quiz
        if (strcmp(trials.question{i}, 'Quiz') && trials.question_correct(i) ~= 0)
            feedback_thickness = 6;
            Screen('FrameRect', window, green, ...
                answer_rect(:,trials.question_correct(i))', feedback_thickness);
            Screen('Flip', window);
            WaitSecs(timing_resphl*2);
        else
            %clear screen
            Screen('Flip', window);
        end
        Screen('Flip', window);
    end
    %------- Pause -------
    if trials.pause(i) %display pause if 'RT' or 'None' question type
        fprintf(' - ');
        DrawFormattedText(window, 'Cliquer pour poursuivre', 'center', 'center', black);
        Screen('Flip', window);
        trials.time_pause(i) = GetSecs;
        %KbStrokeWait(-1);
        while GetSecs-trials.time_pause(i) < timing_rtmax
            [iskeydown, keytime, keys] = KbCheck(-1);
            if iskeydown
                if any(keys(answer_keys))
                Eyelink('message', 'keypress, trial %i / %i _ block %i / %i', i, trials_per_block, trials.block(i), blocks_nb);
                break
                elseif keys(exit_key)
                    EXIT = 1;
                    break
                end
            else
                WaitSecs(.004);
            end
        end
        trials.rt2(i) = keytime-trials.time_pause(i);
    end
    trials.ending(i) = GetSecs;

    %Send Infos about current trial to Eyelink File
    Eyelink('message', 'snr_num = %i, trials.snr_num(i), trial %i / %i _ block %i / %i',trials.snr_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    Eyelink('message', 'vowel = %i, trial %i / %i _ block %i / %i', trials.stimulus_num(i), i, trials_per_block, trials.block(i), blocks_nb);
    if ~ isnan(trials.correct(i))
        Eyelink('message', 'correct = %i, trial %i / %i _ block %i / %i',trials.correct(i), i, trials_per_block, trials.block(i), blocks_nb);
    else
        Eyelink('message', 'correct = NaN, trial %i / %i _ block %i / %i',i, trials_per_block, trials.block(i), blocks_nb);
    end
    if trials.question_num == 3
        if ~ isnan(trials.answer_num(i))
            Eyelink('message', 'mindwander resp = %i, trial %i / %i _ block %i / %i',trials.answer_num(i), i, trials_per_block, trials.block(i), blocks_nb);
        else
            Eyelink('message', 'mindwander resp = NaN, trial %i / %i _ block %i / %i',i, trials_per_block, trials.block(i), blocks_nb);
        end
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
trials.duration(i) = GetSecs - trials.time_start(i); %is it relevant?
end

%%

endtime = datetime;
add_file.endexp(i) = GetSecs;
Eyelink('message', 'experiment_end');
fprintf('\nExp�rience termin�e, dur�e = %s\n\n', datestr(endtime-starttime, 'HH:MM:SS')); %Overall stats:\n', datestr(endtime-starttime, 'HH:MM:SS'));

DrawFormattedText(window, 'Exp�rience termin�e, merci !', 'center', 'center', black);
Screen('Flip', window);

PsychPortAudio('Stop', pamaster);

PsychPortAudio('DeleteBuffer');

PsychPortAudio('Close', pamaster);
%%
%%% Record data // add timestamp
%filename_base = sprintf('/Users/julieboyer/Desktop/M2/projet M2/Nouveaux codes/Results_MRI_Pilots/Subject_%d', subject_nb);
%filename_base = sprintf('E:\Protocoles\psychtoolbox\SOUNDfMRI\LogFiles\Subject_%d_', subject_nb);
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

%%
%%%%%%%%
%%% Close
%%%%%%%%

WaitSecs(2);
Screen('CloseAll');
