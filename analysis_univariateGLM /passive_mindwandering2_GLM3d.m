%% New new pipeline for fMRI processing - SOUNDFMRI -- Mindwandering probes in Passive condition
% feb 2026 omg J Boyer
% AI - improved, V3  because other models sucked
% main idea now: take into account all trials' stim intensity using pmod
% and test for heard / not heard; AI says its also better to do pmod on
% heard not heard lets try it -- with a binary regressor though, -1 or +1

%% new version (1)
% parametric modulation for audibility = either -1 or 1
% parametric modulation for snr = [-2.2, -1.2, -0.2, 0.8, 2.8]
% try putting vowels A and E together to improve power
% + non interest regressors = fixpoint + response screen (4 types) + keypress

% run this one 1st level for all and then 2nd level
% if shitty try:
% - differentiating A and E
% - pmod for snr level but not 'heard / not heard' (though gemini says its
% not good because pmod won't account for stim effect properly since
% applied to heard (strong snrs) vs not heard (weak snrs)
% - pmod heard / not heard = 1 / 0
% - try a simpler model like the first one but improved? A/E together?
% doesnt take into account stim intensity effect but..
% - try orthogonalization off? cf. explanation later

%% for now: add sanity check = contrast for stim intensity pmod ++
% works okay at indiv level so global idea = fine BUT pmod on HnotH that
% way gives nothing or very weird uncorrected results + a lot of indivs
% have invalid contrasts

%% V2: 
% - pmod heard not heard but 0 for not heard and 1 for heard
% - +/- cancel orthogonalization

%% 16 02 26 - V2
% pmod HnotH 0/1
% dont touch orthog°
% try w/o global options
%% still some invalid contrast (eg S6 and it's not a code pb --> pmod on intensity w/ same length works)
%% also for subjects where it works it still gives nonesense results

%% 17 02 26 - V3
% try no orthog° - modified code in timing-files
% + back to HnotH pmod -1/1
% S2 + S6 (usually S2 works but is shitty and S6 has invalid contrast)
% ccl: won't work because some subjects sometimes never have 'heard or 'not
% heard' in a full run ?? + anyway results are shitty when it works

%% +/- V4: 17-18 02 2026
% - no pmod for HnotH -> 
% > stim not probed + pmod intensity
% > stim probed heard + pmod intensity
% > stim probed not heard + pmod intensity
% - +/- cancel orthogonalization

%% i think i get why some subjects don't work despite missing regressors dealing
% it's because i didnt fix the part of timing files where it gives missing
% regressors -> it gives vectors of a length of 9 instead of 12 regressors
% because it doesn't include pmod regs +++
% fix it
% then maybe re try pmod for Hnoth ......

%% 18 02 2026
% still invalid contrasts for S6
% (1) main reason = no pmod regressors in runs where an onset is missing (and
% dealt with with an outside onset = 1000sec); eg for S6 run8 there is no
% "heard" so regressors are stim heard / stim not heard / pmod / stim not
% probed / pmod / ... so 1 regressor less than expected and then contrast
% is all shifted
% so deal w/ it
% (2) checking manually the design matrix i see for run0 of S6 the pmod
% column for not heard pmod intensity is empty which makes no sense because
% there are several onsets for not heard

%% what about unconscious
% same but with just a 1 in not heard? ...
% or re do a model with no stim as a specific regressor for no stim?

%% SO NEW REGRESSORS
% 1 stim heard
% 2 stim heard x pmod intensiy
% 3 stim not heard
% 4 stim not heard x pmod intensiy
% 5 stim not probed
% 6 stim not probed x pmod intensiy
% 7 fix point
% 8 9 10 11 the 4 possible resp. screens
% 12 keypress



%% !! We set the polynomial expansion to 1st order, and switch the Orthogonalise modulations option from Yes to No.
% i think we need it if several pmod regs for one given onset?
% try something like matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 0;

% Gemini says
% With Orthogonalization ON (SPM Default):
% The contrast [0 0 1] shows: "Is there any brain activity that correlates with hearing the sound that cannot be explained by SNR?"
% Interpretation: "Pure awareness."

% With Orthogonalization OFF:
% The contrast [0 0 1] shows: "Is there brain activity that correlates with hearing the sound?" (even if that activity is also correlated with SNR).
% Interpretation: This will look more like a general auditory/awareness map combined.

% My Recommendation: Keep it ON. It is a much more "honest" test of perception because it proves the brain activity isn't just a byproduct of the stimulus being louder.

%% for unconscious processing try with a "no stim" alone and then the same regressors except pmod goes from snr 2 to 5? and invert the values for heard / not heard? (-1 / 1)
% or just put -1 in the contrast instead of 1
%% basic setup
clear;
%clear global options;
close all;
clc;

addpath('/Applications/spm12/');


%subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32]; 
subjects = [3 4 5 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32]; 
%subjects = [6 7 8 9 10]; 
%% errors
% S6 S7 S10 S13 S14 S18 invalid contrast
% àp S14 changement boucle 
%for ii = full_subjects

    %clear global options;
    %global options;
    passive_scan_folder = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans';

    %subjects = [ii];
    % Define Options and start filling it with subject's sessions numbers
    for isubj = subjects % loop across subjects of the list
        if isubj<10
            sub_nb = ['0' num2str(isubj)];
        else
            sub_nb = [num2str(isubj)];
        end
        passive_folder = dir([passive_scan_folder '/SOUNDFMRI_SUJET' sub_nb '_PASSIVE']);
        n = 0;
        for j = 1:numel(passive_folder)
            if ~passive_folder(j).isdir && contains(passive_folder(j).name, 's8wts_OC_run') && ~contains(passive_folder(j).name,'._')
                n = n+1; %m = m+1;
                options.Sessions_names.(['subj' sub_nb]){n} = ['RunP' num2str(n-1)];
            end
        end
    end
    clear sub_nb;

    % Complete Options
    options.steps_to_run  = {'specify','estimate','contrasts'}; % {'contrasts'}; %{'specify','estimate','contrasts'}; % ,'contrasts' / Here, select the actions that you want to run : model specification, model estimation, contrasts, and second level. You can select one or several actions
    options.contrast_type = 'T'; % 'F' or 'T' % The type of contrast (usually T)
    options.bases         = 'HRF'; % 'HRF' or 'FIR' (usually HRF)
    %options.GLMtype       = {'Classic'}; % Classic or Pmod
    options.stim_duration = {'0.2'};  % change this to test for other durations
    options.missing_regressors = {};

    %% 1st level job

    if ismember('specify',options.steps_to_run) || ismember('estimate',options.steps_to_run) || ismember('contrasts',options.steps_to_run)

        % Loop across subjects for the first level
        for isubj = subjects
            % define subject nb
            if isubj<10
                sub_nb = ['0' num2str(isubj)];
            else
                sub_nb = [num2str(isubj)];
            end
            options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))) = {}; % list of runs missing regressor

            % Get the timing files and fill info about missing regressors
            %options = timing_files_mw3(sub_nb, options);
            options = timing_files_mw3_ai(sub_nb, options);

            % Set up spm : for fMRI, and in job manager and non-interactive, commandline mode
            spm('defaults', 'fmri');
            spm_jobman('initcfg');
            spm_get_defaults('cmdline',true);

            % call function 'FirstLevelParameters' whose arguments are (options, sub_nb)
            [matlabbatch1, options] = FirstLevelParameters_mw3(options,sub_nb);
            spm_jobman('run', matlabbatch1);

        end
    end
%end
