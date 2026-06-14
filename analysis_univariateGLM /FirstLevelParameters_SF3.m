function matlabbatch=FirstLevelParameters_SF3(options,sub_nb)

%% job for SPM for 1st level analysis of soundfmri individual conjunction analysis

% Define each subject's number of runs
run_nb = length(options.Sessions_names.(['subj' sub_nb]));
run_nb_active = 0;
run_nb_passive = 0;

for irun = 1:run_nb
    if contains(options.Sessions_names.(['subj' sub_nb]){irun},'A')
        run_nb_active = run_nb_active + 1;
    elseif contains(options.Sessions_names.(['subj' sub_nb]){irun},'P')
        run_nb_passive = run_nb_passive + 1;
    end
end

RONI_ok = zeros(run_nb,1); % true if a given run has 66 nuisance regressors, false if not
RONI_corr = zeros(run_nb,1); % corrected number of nuisance regressors if false


%% CREATE BATCH -- specification

steps = 0;
% create a 'results' folder for each subject
% specify the root path for the results
resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/5mmSmoothing/CONJUNCTION/Results_1stLevel_pmod'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/CONJUNCTION';
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
%%

if ismember('specify',options.steps_to_run) % Specify 1st level, ie create GLM using multiple regressors and timing file
    disp('Defining specification...')
    steps = steps+1;



    matlabbatch{steps}.spm.stats.fmri_spec.dir = {resultsFolderPath}; %{'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE'};
    matlabbatch{steps}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{steps}.spm.stats.fmri_spec.timing.RT = 1.66;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

    % loop across sessions (= runs, or blocks ; for conjunction we admit
    % that 9 1st runs are active blocks (called run0 to run9, ie jrun-1) and 11 last runs are
    % passive blocks (called run0 to run10, ie jrun-10)
    for jrun = 1:run_nb %jrun = 1:length(options.Sessions_names) %(1 to 20)
        if jrun < (run_nb_active + 1) %jrun < 10 % active condition (run 1 to 9 in spm --> run 0 to 8 as named in our files)
            % get the scans and NReg (nuisance regressors)
            rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_ACTIVE/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt',jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
            rootSubj = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's5wts_OC_run%d.nii'; % change here for smoothing 5 or 8
            functional_root = [rootSubj  sub_nb '_ACTIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);
            vol_nb = numScans;
            for i = 1:vol_nb % total number of scans in the run's nifti file
                matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            end
            % get timing files
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE/TimingFiles'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Timing_files/';
            % generate the filename based on GLM type and PMod version
            filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_active_subject%i_run%i', str2double(sub_nb), jrun-1));
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
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath};
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        elseif jrun > run_nb_active %> 9 % passive condition (run 10 to 20 in spm --> run 0 to 10 as named in our files)
            % get the scans and NReg (nuisance regressors)
            rootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_PASSIVE/multiple_regressors_run'];
            %MultReg_root2 = sprintf('%d.txt',jrun-10);
            MultReg_root2 = sprintf('%d.txt',jrun-(run_nb_active+1));
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-(run_nb_active+1))]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-(run_nb_active+1))]);
            rootSubj = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's5wts_OC_run%d.nii'; % change here for smoothing 5 or 8
            functional_root = [rootSubj  sub_nb '_PASSIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-(run_nb_active+1));
            vol_nb = numScans;
            for i = 1:vol_nb % total number of scans in the run's nifti file
                matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
                %disp([functional_file ',' num2str(i)]); % just for test
            end
            % get timing files
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVE/TimingFiles'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Timing_files/';
            % generate the filename based on GLM type and PMod version
            filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_passive_subject%i_run%i', str2double(sub_nb), jrun-(run_nb_active+1)));
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
        end
        % for each run, check the number of nuisance regressors
        if numNreg == 66
            RONI_ok(jrun) = true;
        elseif numNreg ~= 66
            RONI_ok(jrun) = false;
            RONI_corr(jrun) = numNreg;
        end
    end

    % Masking specification (we don't have one)

    matlabbatch{steps}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {}); % fill if ANOVA design
    matlabbatch{steps}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; % 0 if using canonical HRF)
    matlabbatch{steps}.spm.stats.fmri_spec.volt = 1; % order of the Volterra expansion
    matlabbatch{steps}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{steps}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{steps}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{steps}.spm.stats.fmri_spec.cvi = 'AR(1)';
end

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

%% GLM standard version
%base = [-1 0 0 0 1 -1 0 0 0 1 0 0 0]; % contrast to test for snr 5 - snr 1 ACTIVE
%base = [-1 0 0 0 1 -1 0 0 0 1 0 0]; % contrast to test for snr 5 - snr 1 PASSIVE
%% Parametric modulation version (Stim intensity alone)
%base = %first parametric modulation test (active condition, subject 10)
%base = [0 1 0 1 0 0]; %first parametric modulation test (passive condition, subject 10)
%% formula
%contrast = repmat([base zeros(1,66)],1,11); %9 for active, 11 for
%passive / if 66 nuisance regressors

if ismember('contrasts',options.steps_to_run) && ~ismember('specify',options.steps_to_run)
    for jrun = 1:run_nb %jrun = 1:length(options.Sessions_names) %(1 to 20)
        if jrun < (run_nb_active + 1) %jrun < 10 % active condition (run 1 to 9 in spm --> run 0 to 8 as named in our files)
            % get the scans and NReg (nuisance regressors)
            rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_ACTIVE/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt',jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
            rootSubj = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/ACTIVE/Scans/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's5wts_OC_run%d.nii'; % change here for smoothing 5 or 8
            functional_root = [rootSubj  sub_nb '_ACTIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);
            vol_nb = numScans;
            % for i = 1:vol_nb % total number of scans in the run's nifti file
            %     matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            % end
            % get timing files
            %matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            %timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/ACTIVE/TimingFiles'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE/Timing_files/';
            % generate the filename based on GLM type and PMod version
            % filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_active_subject%i_run%i', str2double(sub_nb), jrun-1));
            % if ismember(options.GLMtype, 'Classic')
            %     timingFilePath = [filename_baseTF '_classic_' '.mat'];
            % elseif ismember(options.GLMtype, 'Pmod')
            %     if ismember(options.PModVer, 'V1')
            %         timingFilePath = [filename_baseTF '_pmod_V1_' '.mat'];
            %     elseif ismember(options.PModVer, 'V2')
            %         timingFilePath = [filename_baseTF '_pmod_V2_' '.mat'];
            %     end
            % end
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath};
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath};
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        elseif jrun > run_nb_active %> 9 % passive condition (run 10 to 20 in spm --> run 0 to 10 as named in our files)
            % get the scans and NReg (nuisance regressors)
            rootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_PASSIVE/multiple_regressors_run'];
            %MultReg_root2 = sprintf('%d.txt',jrun-10);
            MultReg_root2 = sprintf('%d.txt',jrun-(run_nb_active+1));
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-(run_nb_active+1))]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-(run_nb_active+1))]);
            rootSubj = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's5wts_OC_run%d.nii'; % change here for smoothing 5 or 8
            functional_root = [rootSubj  sub_nb '_PASSIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-(run_nb_active+1));
            vol_nb = numScans;
            % for i = 1:vol_nb % total number of scans in the run's nifti file
            %     matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            %     %disp([functional_file ',' num2str(i)]); % just for test
            % end
            % % get timing files
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            % timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/PASSIVE/TimingFiles'; %'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/PASSIVE/Timing_files/';
            % % generate the filename based on GLM type and PMod version
            % filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_passive_subject%i_run%i', str2double(sub_nb), jrun-(run_nb_active+1)));
            % if ismember(options.GLMtype, 'Classic')
            %     timingFilePath = [filename_baseTF '_classic_' '.mat'];
            % elseif ismember(options.GLMtype, 'Pmod')
            %     if ismember(options.PModVer, 'V1')
            %         timingFilePath = [filename_baseTF '_pmod_V1_' '.mat'];
            %     elseif ismember(options.PModVer, 'V2')
            %         timingFilePath = [filename_baseTF '_pmod_V2_' '.mat'];
            %     end
            % end
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath}; % must be adapted to go get the files
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath}; % must be adapted to go get the files
            % matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
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

if ismember('contrasts',options.steps_to_run)
    disp('Defining contrasts...')
    steps = steps+1;
    % Where to get the SPM.mat
    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
    % Depends on the type of conjunction analysis we want, and GLM type
    contrast = [];
    if ismember(options.ConjType, 'CAplusCP')
        if ismember(options.GLMtype,'Classic')
            contrast_basis_active =  [-1 0 0 0 1 -1 0 0 0 1 0 0 0]; % active
            contrast_basis_passive = [-1 0 0 0 1 -1 0 0 0 1 0 0]; % passive
            for jrun = 1:length(options.Sessions_names) %(1 to 20)
                % First, check number of nuisance regressors (RONI <3)
                if RONI_ok(jrun) == true
                    fprintf('\n number of nreg ok for run %d \n', jrun);
                    RONI = 66;
                elseif RONI_ok(jrun) == false
                    fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                    RONI = RONI_corr(jrun);
                end
                if jrun < (run_nb_active + 1) %10 % active blocks
                    contrast = [contrast contrast_basis_active zeros(1,RONI)];
                elseif jrun > run_nb_active %> 9 % passive blocks
                    contrast = [contrast contrast_basis_passive zeros(1,RONI)];
                end
            end
            matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Classic';
        elseif ismember(options.GLMtype,'Pmod')
            contrast_basis_active =  [0 1 0 1 0 0 0]; % active
            contrast_basis_passive = [0 1 0 1 0 0]; % passive
            for jrun = 1:length(options.Sessions_names) %(1 to 20)
                % First, check number of nuisance regressors (RONI <3)
                if RONI_ok(jrun) == true
                    fprintf('\n number of nreg ok for run %d \n', jrun);
                    RONI = 66;
                elseif RONI_ok(jrun) == false
                    fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                    RONI = RONI_corr(jrun);
                end
                if jrun < (run_nb_active + 1) % < 10 % active blocks
                    contrast = [contrast contrast_basis_active zeros(1,RONI)];
                elseif jrun > run_nb_active %jrun > 9 % passive blocks
                    contrast = [contrast contrast_basis_passive zeros(1,RONI)];
                end
            end
            matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Pmod';
        end
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = contrast;
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{steps}.spm.stats.con.delete = 1;
    elseif ismember(options.ConjType, 'CAminusCP')
        if ismember(options.GLMtype,'Classic') % not sure what to put here for passive ... ?
            % contrast_basis_active =  [-1 0 0 0 1 -1 0 0 0 1 0 0 0]; % active
            % contrast_basis_passive = [-1 0 0 0 1 -1 0 0 0 1 0 0]; % passive
            matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Classic';
        elseif ismember(options.GLMtype,'Pmod')
            contrast_basis_active =  [0 1 0 1 0 0 0]; % active
            contrast_basis_passive = [0 -1 0 -1 0 0]; % passive
            for jrun = 1:length(options.Sessions_names) %(1 to 20)
                % First, check number of nuisance regressors (RONI <3)
                if RONI_ok(jrun) == true
                    fprintf('\n number of nreg ok for run %d \n', jrun);
                    RONI = 66;
                elseif RONI_ok(jrun) == false
                    fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                    RONI = RONI_corr(jrun);
                end
                if jrun < (run_nb_active + 1) %< 10 % active blocks
                    contrast = [contrast contrast_basis_active zeros(1,RONI)];
                elseif jrun > run_nb_active %> 9 % passive blocks
                    contrast = [contrast contrast_basis_passive zeros(1,RONI)];
                end
            end
            matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Pmod';
        end
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = contrast;
        matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{steps}.spm.stats.con.delete = 1;
    elseif ismember(options.ConjType, 'CAconjCP') % here we want to create 2 ...
        % different contrasts so later we can get a conjunction SPM of them, ...
        % ie a map of the t stats of the voxels that pass a certain threshold for both theses contrasts
        if ismember(options.GLMtype,'Classic') % not sure what to put here for passive ... ?
            %contrast_basis_active =  [-1 0 0 0 1 -1 0 0 0 1 0 0 0]; % active
            %contrast_basis_passive = [-1 0 0 0 1 -1 0 0 0 1 0 0]; % passive
            % just for snr1 tests
            contrast_basis_active =  [1 0 0 0 0 1 0 0 0 0 0 0 0]; % active
            contrast_basis_passive = [1 0 0 0 0 1 0 0 0 0 0 0]; % passive
            contrast_minus_active = zeros(length(contrast_basis_active),1)';
            contrast_minus_passive = zeros(length(contrast_basis_passive),1)';
            conCA = []; conCP = [];
            matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'Classic';
            for jrun = 1:length(options.Sessions_names.(['subj' sub_nb])) %length(options.Sessions_names) %(1 to 20)
                if RONI_ok(jrun) == true
                    fprintf('\n number of nreg ok for run %d \n', jrun);
                    RONI = 66;
                elseif RONI_ok(jrun) == false
                    fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                    RONI = RONI_corr(jrun);
                end
                if jrun < (run_nb_active + 1) %< 10 % active blocks
                    conCA = [conCA contrast_basis_active zeros(1,RONI)];
                    conCP = [conCP contrast_minus_active zeros(1,RONI)];
                elseif jrun > run_nb_active %jrun > 9 % passive blocks
                    conCA = [conCA contrast_minus_passive zeros(1,RONI)];
                    conCP = [conCP contrast_basis_passive zeros(1,RONI)];
                end
            end
            con_list = {conCA, conCP};
            nameCon = {'CAclassicSNR1', 'CPclassicSNR1'}; % one contrast for pmod of stim intensity for active condition, ...
            % the other for pmod of stim intensity for passive condition
            for c = 1:length(nameCon) %length(list_of_contrasts) % define list_of_contrasts
                if strcmp(options.contrast_type,'T')
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.name    = nameCon{c};
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.weights = con_list{c};
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.sessrep = 'none';
                elseif strcmp(options.contrast_type,'F')
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.name = nameCon{c};
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.weights = conCP;
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.sessrep = 'none';
                end
            end
        elseif ismember(options.GLMtype,'Pmod')
            contrast_basis_active =  [0 1 0 1 0 0 0]; % active
            contrast_minus_active = zeros(length(contrast_basis_active),1)'; % as many zeros as the basis
            contrast_basis_passive = [0 1 0 1 0 0]; % passive
            contrast_minus_passive = zeros(length(contrast_basis_passive),1)'; % as many zeros as the basis
            conCA = []; conCP = [];
            for jrun = 1:length(options.Sessions_names.(['subj' sub_nb])) %length(options.Sessions_names) %(1 to 20)
                % sept 2024: very surprised i had to change line 235
                % because it was working berfore.... but now it returns 1
                % though i didn't touch the format of Sessions_names
                % First, check number of nuisance regressors (RONI <3)
                if RONI_ok(jrun) == true
                    fprintf('\n number of nreg ok for run %d \n', jrun);
                    RONI = 66;
                elseif RONI_ok(jrun) == false
                    fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
                    RONI = RONI_corr(jrun);
                end
                if jrun < (run_nb_active + 1) %< 10 % active blocks
                    conCA = [conCA contrast_basis_active zeros(1,RONI)];
                    conCP = [conCP contrast_minus_active zeros(1,RONI)];
                elseif jrun > run_nb_active %jrun > 9 % passive blocks
                    conCA = [conCA contrast_minus_passive zeros(1,RONI)];
                    conCP = [conCP contrast_basis_passive zeros(1,RONI)];
                end
            end
            con_list = {conCA, conCP};
            nameCon = {'CApmodSNR', 'CPpmodSNR'}; % one contrast for pmod of stim intensity for active condition, ...
            % the other for pmod of stim intensity for passive condition
            for c = 1:length(nameCon) %length(list_of_contrasts) % define list_of_contrasts
                if strcmp(options.contrast_type,'T')
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.name    = nameCon{c};
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.weights = con_list{c};
                    matlabbatch{steps}.spm.stats.con.consess{c}.tcon.sessrep = 'none';
                elseif strcmp(options.contrast_type,'F')
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.name = nameCon{c};
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.weights = conCP;
                    % matlabbatch{steps}.spm.stats.con.consess{c}.fcon.sessrep = 'none';
                end
            end
        end
    end
end
