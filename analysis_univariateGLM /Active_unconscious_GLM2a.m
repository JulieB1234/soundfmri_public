function matlabbatch=FirstLevelParameters_audibPerSNR_unconscious2(options,sub_nb)

%% job for SPM -- 1st level analysis of soundfmri indiv sessions; new version (May 2024)

%% CREATE BATCH -- specification

global options;

% Define each subject's number of runs
run_nb = length(options.Sessions_names.(['subj' sub_nb]));
run_nb_active = 0;

for irun = 1:run_nb
    if contains(options.Sessions_names.(['subj' sub_nb]){irun},'A')
        run_nb_active = run_nb_active + 1;
    end
end

RONI_ok = zeros(run_nb,1); % true if a given run has 66 nuisance regressors, false if not
RONI_corr = zeros(run_nb,1); % corrected number of nuisance regressors if false

steps = 0;

if ismember('specify',options.steps_to_run) % Specify 1st level, ie create GLM using multiple regressors and timing file
    disp('Defining specification...')
    steps = steps+1;

    % create a 'results' folder for each subject
    % specify the root path for the results
    resultsRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/results_1stLevelnew';
    % create the path for the results folder for the current subject
    resultsFolderPath = fullfile(resultsRootPath, ['results_subj' sub_nb]);
    % check if the folder already exists; if not, create it
    if ~exist(resultsFolderPath, 'dir')
        mkdir(resultsFolderPath);
        disp(['Folder created: ' resultsFolderPath]);
    else
        disp(['Folder already exists: ' resultsFolderPath]);
    end
    addpath(resultsFolderPath);

    matlabbatch{steps}.spm.stats.fmri_spec.dir = {resultsFolderPath}; %{'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE'};
    matlabbatch{steps}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{steps}.spm.stats.fmri_spec.timing.RT = 1.66;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    %%
    % loop across sessions
    for jrun = 1:run_nb %length(options.Sessions_names) %(1 to 20)
        if jrun < (run_nb_active + 1) %10 % active condition (run 1 to 9 in spm --> run 0 to 8 as named in our files)
            % get the scans and NReg (nuisance regressors)
            rootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_ACTIVE/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt',jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
            rootSubj = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's8wts_OC_run%d.nii';
            functional_root = [rootSubj  sub_nb '_ACTIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);
            vol_nb = numScans;
            for i = 1:vol_nb % total number of scans in the run's nifti file
                matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            end
            % get timing files
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            timingRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/timing_files';
            % generate the filename based on GLM type and PMod version
            filename_baseTF = fullfile(timingRootPath, sprintf('audibPerSNR_timing_file_active_subject%i_run%i', str2double(sub_nb), jrun-1));
            if ismember(options.GLMtype, 'Classic')
                timingFilePath = [filename_baseTF '_classic_' '.mat'];
            elseif ismember(options.GLMtype, 'Pmod')
                if ismember(options.PModVer, 'V1')
                    timingFilePath = [filename_baseTF '_pmod_V1_' '.mat'];
                elseif ismember(options.PModVer, 'V2')
                    timingFilePath = [filename_baseTF '_pmod_V2_' '.mat'];
                end
            end
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath};
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath}; % comment this line to test the cdesign matrix wuthout nuisance regressors
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        end
        % for each run, check the number of nuisance regressors
        if numNreg == 66
            RONI_ok(jrun) = true;
        elseif numNreg ~= 66
            RONI_ok(jrun) = false;
            RONI_corr(jrun) = numNreg;
        end
    end
end
%%
% Masking specification (we don't have one)

matlabbatch{steps}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {}); % fill if ANOVA design
matlabbatch{steps}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{steps}.spm.stats.fmri_spec.volt = 1;
matlabbatch{steps}.spm.stats.fmri_spec.global = 'None';
matlabbatch{steps}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{steps}.spm.stats.fmri_spec.mask = {''};
matlabbatch{steps}.spm.stats.fmri_spec.cvi = 'AR(1)';


%% CREATE BATCH -- estimation

%% MODEL ESTIMATION
if ismember('estimate',options.steps_to_run)
    disp('Defining estimation...')

    steps = steps+1;

    % go fetch the SPM.mat file created just before
    matlabbatch{steps}.spm.stats.fmri_est.spmmat            = {[resultsFolderPath '/SPM.mat']};
    matlabbatch{steps}.spm.stats.fmri_est.write_residuals  = 0;
    matlabbatch{steps}.spm.stats.fmri_est.method.Classical = 1;
end


%% CONTRASTS -- can be adapted to the contrasts we want

if ismember('contrasts',options.steps_to_run)
    disp('Defining contrasts...')
    %% List of contrasts we want

    base_contrast_list = {};

    %% for indiv threshold let's do it manually it's not complicated
    % S2 : snr3
    % S3 : snr3
    % S4 : snr4
    % S5 : snr3
    % S6 : snr4A & snr3E
    % S7 : snr4
    % S8 : snr3
    % S9 : snr3
    % S10 : snr3
    % S12 : snr3
    % S13 : snr4
    % S14 : snr3
    % S15 : snr3
    % S18 : snr4
    % S19 : snr3
    % S20 : snr3
    % S21 : snr3
    % S22 : snr3
    % S23 : snr4
    % S24 : snr4
    % S25 : snr3 (corrected)
    % S26 : snr4
    % S27 : snr4
    % S28 : snr4
    % S29 : snr3
    % S30 : snr4
    % S32 : snr3

    snr3 = [2 3 5 6 8 9 10 12 14 15 19 20 21 22 25 29 32];
    snr4 = [4 7 13 18 23 24 26 27 28 30];
    % and S6 = special case

    % 1/ stim heard AT THRESHOLD + 2/ stim heard minus not heard AT
    % THRESHOLD + 6/ stim heard AT THRESHOLD minus no stim
    if ismember(str2double(sub_nb),snr3)
        base_contrast_list{1} = [0 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 1 0 0 ... % audib2 for vowel A
            0 0 1 0 0 ... % audib3
            0 0 1 0 0 ... % audib4
            0 0 0 0 0 ... % audib1 for vowel E
            0 0 1 0 0 ... % audib2 for vowel E
            0 0 1 0 0 ... % audib3
            0 0 1 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{2} = [0 0 -1  0 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 1  0 0 ... % audib2 for vowel A
            0 0 1  0 0 ... % audib3
            0 0 1  0 0 ... % audib4
            0 0 -1 0 0 ... % audib1 for vowel E
            0 0 1  0 0 ... % audib2 for vowel E
            0 0 1  0 0 ... % audib3
            0 0 1  0 0 ... % audib4
            0 0 0  0 0]; % non interest regressors
        base_contrast_list{6} = [-1 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 1 0 0 ... % audib2 for vowel A
            -1 0 1 0 0 ... % audib3
            -1 0 1 0 0 ... % audib4
            -1 0 0 0 0 ... % audib1 for vowel E
            -1 0 1 0 0 ... % audib2 for vowel E
            -1 0 1 0 0 ... % audib3
            -1 0 1 0 0 ... % audib4
             0 0 0 0 0]; % non interest regressors
        %% NEW: 7 = not heard at thr. / 8 = not heard at thr. MINUS snr1 not heard / 9 = heard thr. MINUS snr1 heard
        base_contrast_list{7} = [0 0 1 0 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 0 0 ... % audib2 for vowel A
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 1 0 0 ... % audib1 for vowel E
            0 0 0 0 0 ... % audib2 for vowel E
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{8} = [-1 0 1 0 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 0 0 ... % audib2 for vowel A
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
           -1 0 1 0 0 ... % audib1 for vowel E
            0 0 0 0 0 ... % audib2 for vowel E
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{9} = [0 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 1 0 0 ... % audib2 for vowel A
            -1 0 1 0 0 ... % audib3
            -1 0 1 0 0 ... % audib4
             0 0 0 0 0 ... % audib1 for vowel E
            -1 0 1 0 0 ... % audib2 for vowel E
            -1 0 1 0 0 ... % audib3
            -1 0 1 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors

        %% last one 11/2/26
        base_contrast_list{10} = [-1 0 1 0 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 0 0 0 ... % audib2 for vowel A
            -1 0 0 0 0 ... % audib3
            -1 0 0 0 0 ... % audib4
            -1 0 1 0 0 ... % audib1 for vowel E
            -1 0 0 0 0 ... % audib2 for vowel E
            -1 0 0 0 0 ... % audib3
            -1 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
    elseif ismember(str2double(sub_nb),snr4)
        base_contrast_list{1} = [0 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 1 0 ... % audib2 for vowel A
            0 0 0 1 0 ... % audib3
            0 0 0 1 0 ... % audib4
            0 0 0 0 0 ... % audib1 for vowel E
            0 0 0 1 0 ... % audib2 for vowel E
            0 0 0 1 0 ... % audib3
            0 0 0 1 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{2} = [0 0 0 -1  0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 1  0 ... % audib2 for vowel A
            0 0 0 1  0 ... % audib3
            0 0 0 1  0 ... % audib4
            0 0 0 -1 0 ... % audib1 for vowel E
            0 0 0 1  0 ... % audib2 for vowel E
            0 0 0 1  0 ... % audib3
            0 0 0 1  0 ... % audib4
            0 0 0 0  0]; % non interest regressors
        base_contrast_list{6} = [-1 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 0 1 0 ... % audib2 for vowel A
            -1 0 0 1 0 ... % audib3
            -1 0 0 1 0 ... % audib4
            -1 0 0 0 0 ... % audib1 for vowel E
            -1 0 0 1 0 ... % audib2 for vowel E
            -1 0 0 1 0 ... % audib3
            -1 0 0 1 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        %% NEW: 7 = not heard at thr. / 8 = not heard at thr. MINUS snr1 not heard / 9 = heard thr. MINUS snr1 heard
        base_contrast_list{7} = [0 0 0 1 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 0 0 ... % audib2 for vowel A
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 0 1 0 ... % audib1 for vowel E
            0 0 0 0 0 ... % audib2 for vowel E
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{8} = [-1 0 0 1 0 ... % audib1 (and 5 snrs) for vowel A
            0 0 0 0 0 ... % audib2 for vowel A
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
           -1 0 0 1 0 ... % audib1 for vowel E
            0 0 0 0 0 ... % audib2 for vowel E
            0 0 0 0 0 ... % audib3
            0 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        base_contrast_list{9} = [0 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 0 1 0 ... % audib2 for vowel A
            -1 0 0 1 0 ... % audib3
            -1 0 0 1 0 ... % audib4
             0 0 0 0 0 ... % audib1 for vowel E
            -1 0 0 1 0 ... % audib2 for vowel E
            -1 0 0 1 0 ... % audib3
            -1 0 0 1 0 ... % audib4
            0 0 0 0 0]; % non interest regressors

        %% last one 11/2/26
        base_contrast_list{10} = [-1 0 0 1 0 ... % audib1 (and 5 snrs) for vowel A
            -1 0 0 0 0 ... % audib2 for vowel A
            -1 0 0 0 0 ... % audib3
            -1 0 0 0 0 ... % audib4
            -1 0 0 1 0 ... % audib1 for vowel E
            -1 0 0 0 0 ... % audib2 for vowel E
            -1 0 0 0 0 ... % audib3
            -1 0 0 0 0 ... % audib4
            0 0 0 0 0]; % non interest regressors
        %%
        % elseif strcmp(sub_nb,'06') % Asnr4 and Esnr3 --> con2 is invalid so
        % treat s6 like a 'snr3' for both vowels
        %     base_contrast_list{1} = [0 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
        %         0 0 0 1 0 ... % audib2 for vowel A
        %         0 0 0 1 0 ... % audib3
    %         0 0 0 1 0 ... % audib4
    %         0 0 0 0 0 ... % audib1 for vowel E
    %         0 0 1 0 0 ... % audib2 for vowel E
    %         0 0 1 0 0 ... % audib3
    %         0 0 1 0 0 ... % audib4
    %         0 0 0 0 0]; % non interest regressors
    %     base_contrast_list{2} = [0 0 0 0 -1 0 ... % audib1 (and 5 snrs) for vowel A
    %         0 0 0  1 0 ... % audib2 for vowel A
    %         0 0 0  1 0 ... % audib3
    %         0 0 0  1 0 ... % audib4
    %         0 0 -1 0 0 ... % audib1 for vowel E
    %         0 0 1  0 0 ... % audib2 for vowel E
    %         0 0 1  0 0 ... % audib3
    %         0 0 1  0 0 ... % audib4
    %         0 0 0 0 0]; % non interest regressors
    %     base_contrast_list{6} = [-1 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
    %         -1 0 0 1 0 ... % audib2 for vowel A
    %         -1 0 0 1 0 ... % audib3
    %         -1 0 0 1 0 ... % audib4
    %         -1 0 0 0 0 ... % audib1 for vowel E
    %         -1 0 1 0 0 ... % audib2 for vowel E
    %         -1 0 1 0 0 ... % audib3
    %         -1 0 1 0 0 ... % audib4
    %         0 0 0 0 0]; % non interest regressors
    end


    % 3/ stim not heard
    base_contrast_list{3} = [0 1 1 1 1 ... % audib1 (and 5 snrs) for vowel A
        0 0 0 0 0 ... % audib2 for vowel A
        0 0 0 0 0 ... % audib3
        0 0 0 0 0 ... % audib4
        0 1 1 1 1 ... % audib1 for vowel E
        0 0 0 0 0 ... % audib2 for vowel E
        0 0 0 0 0 ... % audib3
        0 0 0 0 0 ... % audib4
        0 0 0 0 0]; % non interest regressors

    % 4/ no stim
    base_contrast_list{4} = [1 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
        1 0 0 0 0 ... % audib2 for vowel A
        1 0 0 0 0 ... % audib3
        1 0 0 0 0 ... % audib4
        1 0 0 0 0 ... % audib1 for vowel E
        1 0 0 0 0 ... % audib2 for vowel E
        1 0 0 0 0 ... % audib3
        1 0 0 0 0 ... % audib4
        0 0 0 0 0]; % non interest regressors

    % 5/ stim not heard minus no stim
    base_contrast_list{5} = [-1 1 1 1 1 ... % audib1 (and 5 snrs) for vowel A
        -1 0 0 0 0 ... % audib2 for vowel A
        -1 0 0 0 0 ... % audib3
        -1 0 0 0 0 ... % audib4
        -1 1 1 1 1 ... % audib1 for vowel E
        -1 0 0 0 0 ... % audib2 for vowel E
        -1 0 0 0 0 ... % audib3
        -1 0 0 0 0 ... % audib4
         0 0 0 0 0]; % non interest regressors

        %% LAST last one 11/3/26
        base_contrast_list{11} = [
            -1 0 0 0 1 ... % audib1 (and 5 snrs) for vowel A
            -1 0 0 0 1 ... % audib2 for vowel A
            -1 0 0 0 1 ... % audib3
            -1 0 0 0 1 ... % audib4
            -1 0 0 0 1 ... % audib1 for vowel E
            -1 0 0 0 1 ... % audib2 for vowel E
            -1 0 0 0 1 ... % audib3
            -1 0 0 0 1 ... % audib4
            0 0 0 0 0]; % non interest regressors

%% modif
    %contrast_names = {'SHthr','SH_SnotHthr','SnotH','noS','SnotH_noS','SH_noS'};

    %contrast_names = {' ',' ',' ',' ',' ',' ','SnotHthr','SnotHthr_noSthr','SHthr_noSthr'};

    %contrast_names = {' ',' ',' ',' ',' ',' ',' ',' ',' ','SnotHthr_noSall'};
    contrast_names = {' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','snr5_1'};
    steps = steps+1;


    for icon = 11:numel(contrast_names)

        matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
        base_contrast = base_contrast_list{icon};

        regressors_of_interest_indices = find(base_contrast);
        num_regressors_of_interest = length(regressors_of_interest_indices);

        con = [];
        clear jrun;


        for jrun = 1:run_nb
            % Define number of nuisance regressors (RONI <3)
            if RONI_ok(jrun) == true
                fprintf('\n number of nreg ok for run %d \n', jrun);
                RONI = 66;
            elseif RONI_ok(jrun) == false
                fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                RONI = RONI_corr(jrun);
            end
            % Check if some onsets are missing in each run and if so, adapt the contrast basis
            num_regressors_of_interest = length(regressors_of_interest_indices);
            missingReg = false(1, num_regressors_of_interest); % Preallocate missingReg array

            for ireg = 1:num_regressors_of_interest
                % Check if the regressor is missing
                regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
                if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(regressor_index) ~= 0
                    missingReg(ireg) = true;
                end
            end
            for ireg = 1:num_regressors_of_interest
                % Check if the regressor is missing
                regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
                if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(regressor_index) ~= 0
                    missingReg(ireg) = true;
                end
            end

            % Generate the contrast based on missing regressors
            new_base_contrast = base_contrast;
            for ireg = 1:num_regressors_of_interest
                if missingReg(ireg)
                    new_base_contrast(regressors_of_interest_indices(ireg)) = 0;
                end
            end
            con = [con new_base_contrast zeros(1,RONI)];

        end
        matlabbatch{steps}.spm.stats.con.consess{icon}.tcon.name    = contrast_names{icon};
        matlabbatch{steps}.spm.stats.con.consess{icon}.tcon.weights = con;
        matlabbatch{steps}.spm.stats.con.consess{icon}.tcon.sessrep = 'none';


    end



end
