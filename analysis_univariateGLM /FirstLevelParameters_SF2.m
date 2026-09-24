function matlabbatch=FirstLevelParameters_SF2(options,sub_nb)

%% job for SPM for 1st level analysis of soundfmri individual active sessions

% Define each subject's number of runs
run_nb = length(options.Sessions_names.(['subj' sub_nb]));
%run_nb_active = 0;
%run_nb_passive = 0;

% for irun = 1:run_nb
%     if contains(options.Sessions_names.(['subj' sub_nb]){irun},'A')
%         run_nb_active = run_nb_active + 1;
%     elseif contains(options.Sessions_names.(['subj' sub_nb]){irun},'P')
%         run_nb_passive = run_nb_passive + 1;
%     end
% end

RONI_ok = zeros(run_nb,1); % true if a given run has 66 nuisance regressors, false if not
RONI_corr = zeros(run_nb,1); % corrected number of nuisance regressors if false

%% CREATE BATCH -- specification

steps = 0;

if ismember('specify',options.steps_to_run) % Specify 1st level, ie create GLM using multiple regressors and timing file
    disp('Defining specification...')
    steps = steps+1;

    % create a 'results' folder for each subject
    % specify the root path for the results
    %resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE';
    resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVE/Results/Results_indiv_PMOD'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/CONJUNCTION';
    % create the path for the results folder for the current subject
    resultsFolderPath = fullfile(resultsRootPath, ['results_subj' sub_nb '_NewTimingFiles']);
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

    % loop across sessions (= runs, or blocks ; in active condition : from
    % run 0 to run 8, n = 9)
    for jrun = 1:run_nb %length(options.Sessions_names)
        %rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET';
        rootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET';
        MultReg_root = [rootPath sub_nb '_PASSIVE/multiple_regressors_run'];
        MultReg_root2 = sprintf('%d.txt',jrun-1);
        NregfilePath = [MultReg_root MultReg_root2];
        data = load(NregfilePath);
        [numScans, numNreg] = size(data);
        disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
        disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
        %rootSubj = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans/SOUNDFMRI_SUJET';
        rootSubj = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Scans/SOUNDFMRI_SUJET';
        functionalName = 's8wts_OC_run%d.nii';
        functional_root = [rootSubj  sub_nb '_PASSIVE/']; %we'll have to change it for the passive condition
        functional_file = sprintf([functional_root functionalName], jrun-1);
        %functional_file =  '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/Scans/SOUNDFMRI_SUJET10_ACTIVE/s8wts_OC_run0.nii'; %but ...
        % it must be adapted to each subject! ask chatgpt using the
        % variable sub_nub AND must be adapted to each run
        vol_nb = numScans;
        for i = 1:vol_nb % total number of scans in the run's nifti file
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            %disp([functional_file ',' num2str(i)]); % nust for test
        end

        % Get events definition (from timing files and multiple regressors = Nreg, nuisance regressors)
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        %timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Timing_files/';
        timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVE/TimingFiles'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Timing_files/';
        % timingFilePath = fullfile(timingRootPath, ['pm_timing_file_active_subject' sub_nb '_run' num2str(jrun-1) '.mat']);
        
        % Generate the filename based on GLM type and PMod version
        filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_passive_subject%i_run%i', str2double(sub_nb), jrun-1));

        if ismember(options.GLMtype, 'Classic')
            timingFilePath = [filename_baseTF '_classic_' '.mat'];
        elseif ismember(options.GLMtype, 'Pmod')
            if ismember(options.PModVer, 'V1')
                timingFilePath = [filename_baseTF '_pmod_V1_' '.mat'];
            elseif ismember(options.PModVer, 'V2')
                timingFilePath = [filename_baseTF '_pmod_V2_' '.mat'];
            end
        end
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath}; % must be adapted to go get the files
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath}; % must be adapted to go get the files
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        if numNreg == 66
            RONI_ok(jrun) = true;
        elseif numNreg ~= 66
            RONI_ok(jrun) = false;
            RONI_corr(jrun) = numNreg;
        end
    end

    % Masking specification (we don't have one)

    matlabbatch{steps}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {}); % fill if ANOVA design
    matlabbatch{steps}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; % in Alizée's code = [options.TimeDeriv options.DispersDeriv] (= 0 if using canonical HRF)
    matlabbatch{steps}.spm.stats.fmri_spec.volt = 1; % order of the Volterra expansion, typically set to 1 (mathematical approach used to capture ...
    % higher-order interactions and nonlinearities in the modeling of the relationship between neural activity and the observed fMRI signal)
    matlabbatch{steps}.spm.stats.fmri_spec.global = 'None'; % specifies the global calculation for global scaling. 'None' means no global scaling ...
    % (preprocessing step where the intensity values across all voxels in an fMRI volume are normalized or scaled to a common reference value. ...
    % This process is aimed at reducing variability in overall signal intensity across the entire brain or a region of interest).
    matlabbatch{steps}.spm.stats.fmri_spec.mthresh = 0.8; % Alizée's code : 0.1 (sets the motion threshold, defining the proportion ...
    % of volumes that are allowed to exceed the threshold without causing the session to be rejected)
    matlabbatch{steps}.spm.stats.fmri_spec.mask = {''}; %Alizée's code : [rootSubj dir_sess_func.name filesep ExplicitMasking] --> path for .nii file; only if masking wanted
    matlabbatch{steps}.spm.stats.fmri_spec.cvi = 'AR(1)'; %specifies the approach for modeling serial correlations. 'AR(1)' stands for AutoRegressive(1), ...
    % which is commonly used for modeling serial correlations in fMRI time series.
end

%% CREATE BATCH -- estimation

%% MODEL ESTIMATION
if ismember('estimate',options.steps_to_run)
    disp('Defining estimation...')

    steps = steps+1;
    % go fetch the SPM.mat file created just before
    %matlabbatch{steps}.spm.stats.fmri_est.spmmat           = {'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/SPM.mat'};   %{[options.rootModels 'model' options.modelName  filesep options.study_code sub_nb '/SPM.mat']};
    matlabbatch{steps}.spm.stats.fmri_est.spmmat            = {[resultsFolderPath '/SPM.mat']};
    matlabbatch{steps}.spm.stats.fmri_est.write_residuals  = 0;
    matlabbatch{steps}.spm.stats.fmri_est.method.Classical = 1;
end

% see later if useful (for FIR)

% if strcmp(options.bases,'FIR')
%     nb_regressors_of_interest=nb_regressors_of_interest*options.FIRorder;
% end


%% CONTRASTS -- can be adapted to the contrasts we want

if ismember('contrasts',options.steps_to_run)
    disp('Defining contrasts...')
    steps = steps+1;
    % find the SPM.mat
    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
    contrast = [];
    if ismember(options.GLMtype,'Classic')
        contrast_basis = [-1 0 0 0 1 -1 0 0 0 1 0 0];
        for jrun = 1:run_nb
            % First, check number of nuisance regressors (RONI <3)
            if RONI_ok(jrun) == true
                fprintf('\n number of nreg ok for run %d \n', jrun);
                RONI = 66;
            elseif RONI_ok(jrun) == false
                fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                RONI = RONI_corr(jrun);
            end
            contrast = [contrast contrast_basis zeros(1,RONI)];
        end
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Classic';
    elseif ismember(options.GLMtype,'Pmod')
        contrast_basis = [0 1 0 1 0 0];
        for jrun = 1:run_nb
            if RONI_ok(jrun) == true
                fprintf('\n number of nreg ok for run %d \n', jrun);
                RONI = 66;
            elseif RONI_ok(jrun) == false
                fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                RONI = RONI_corr(jrun);
            end
            contrast = [contrast contrast_basis zeros(1,RONI)];
        end
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Pmod';
    end

    %contrast = repmat([contrast_basis zeros(1,numNreg)],1,length(options.Sessions_names)); % 'options.Sessions_names' = string list of all the runs
    
    % ATTENTION : erreur potentielle si pas le même nb de régresseurs de
    % nuisance à chaque bloc --> prend valeur 'numNreg' du dernier bloc
    % pour faire le contraste appliqué à tous les blocs --> soit modif code
    % pour le prendre en compte, soit au moins mettre un message d'erreur
    % si pas le même nb

    % for now only T contrasts -- and only one contrast (so c = 1)
    % name the contrast
    % if ismember(options.GLMtype,'Classic')
    %     matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Classic';
    % elseif ismember(options.GLMtype,'Pmod')
    %     matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Pmod';
    % end

    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = contrast;
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none'; %session replication option ; ...
    % specifies how to replicate the contrast weights across sessions (we could have used this ...
    % instead of manually repeating our basis earlier)
    %matlabbatch{steps}.spm.stats.con.consess = {};
    matlabbatch{steps}.spm.stats.con.delete = 1; % after the contrast computations ...
    % are done, the intermediate contrast files (usually images) will be deleted if set to 1.

end



