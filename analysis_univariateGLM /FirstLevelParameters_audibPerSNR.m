function matlabbatch=FirstLevelParameters_audibPerSNR(options,sub_nb)

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
    resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Results';
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
            rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_ACTIVE/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt',jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
            rootSubj = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's8wts_OC_run%d.nii';
            functional_root = [rootSubj  sub_nb '_ACTIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);
            vol_nb = numScans;
            for i = 1:vol_nb % total number of scans in the run's nifti file
                matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            end
            % get timing files
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/TimingFiles';
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

    steps = steps+1;

    % Directory containing the contrast .mat files
    Con_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts';
    addpath(Con_dir);

    % List all available contrasts and get their names
    list_available_contrasts = dir(fullfile(Con_dir, '*.mat'));
    contrast_names = {};
    for c = 1:length(list_available_contrasts)
        [~, contrast_name, ~] = fileparts(list_available_contrasts(c).name);
        contrast_names{end + 1} = contrast_name;
    end

    % Where to get the SPM.mat
    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};

    % Get the contrast adapted to potential missing regressors
    % !! wanted contrast (eg, snr3, just vowel A) is defined directly in
    % the Contrast function !! -> use the indices of the right regressors
    % of interest computed during the Contrast function
    load('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts/RegIndices.mat');
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
        %missingReg = []; %num_regressors_of_interest = 8;
        num_regressors_of_interest = length(regressors_of_interest_indices);
        missingReg = false(1, num_regressors_of_interest); % Preallocate missingReg array

        for ireg = 1:num_regressors_of_interest
            %regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
            %missingReg(ireg) = false;
            %if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(ireg) ~= 0
            %    missingReg(ireg) = true;
            %end
            % Check if the regressor is missing
            regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
            if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(regressor_index) ~= 0
                missingReg(ireg) = true;
            end
        end

        % Generate an error if the 'not heard' was never selected during a
        % given run
        % These are indices 1 and 5 relative to the regressors of interest
        % -- that only works if the 2 vowels are analyzed...
        % if missingReg(1) == true || missingReg(5) == true
        %     error('Missing onset for audibility 1, subject %i run %i',str2double(sub_nb),jrun);
        % end

        % Generate the contrast name based on missing regressors
        contrast_name = 'HnotH_';
        for ireg = 1:num_regressors_of_interest
            if missingReg(ireg)
                %contrast_name = [contrast_name 'Miss' num2str(ireg)];
                contrast_name = [contrast_name 'Miss' num2str(regressors_of_interest_indices(ireg))];
            end
        end
        if all(~missingReg)
            contrast_name = [contrast_name 'noMiss'];
        end


        % Load the appropriate contrast
        filename = fullfile(Con_dir, [contrast_name '.mat']);
        if exist(filename, 'file')
            % Load the selected contrast
            contrast_struct = load(filename); %(contrast_file);
            contrast_basis = contrast_struct.contrast_data;
        else
            error('Contrast file not found: %s', filename);
        end

        % compute the contrast chuncks for each run
        con = [con contrast_basis zeros(1,RONI)];

    end
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name = 'audib';
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = con;
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{steps}.spm.stats.con.delete = 1;


end
