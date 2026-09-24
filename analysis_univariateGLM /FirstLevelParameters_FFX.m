function matlabbatch = FirstLevelParameters_FFX(options, subj_nb_list)

%% job for SPM 1st level analysis — True Fixed-Effects (FFX) Concatenation

steps = 0;

% Define FFX Group Results Output Folder
resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVEDC/Results/pmod/ffx_try1/results';
resultsFolderPath = fullfile(resultsRootPath, 'results_FFX_Group_Pmod');

if ~exist(resultsFolderPath, 'dir')
    mkdir(resultsFolderPath);
    disp(['FFX Output Folder created: ' resultsFolderPath]);
else
    disp(['FFX Output Folder exists: ' resultsFolderPath]);
end

%% CREATE BATCH -- Specification

if ismember('specify', options.steps_to_run)
    disp('Defining FFX model specification across all subjects...')
    steps = steps + 1;

    matlabbatch{steps}.spm.stats.fmri_spec.dir = {resultsFolderPath};
    matlabbatch{steps}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{steps}.spm.stats.fmri_spec.timing.RT = 1.66;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

    global_sess_cnt = 0; % Global session counter across ALL subjects

    for sub_idx = 1:length(subj_nb_list)
        subs = subj_nb_list(sub_idx);
        if subs < 10
            sub_nb = ['0' num2str(subs)];
        else
            sub_nb = num2str(subs);
        end

        run_nb = length(options.Sessions_names.(['subj' sub_nb]));

        for jrun = 1:run_nb
            global_sess_cnt = global_sess_cnt + 1;

            % Paths for multiple regressors & scans
            rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE_DC/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_PASSIVE_DC/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt', jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);

            rootSubj = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE_DC/Scans/SOUNDFMRI_SUJET';
            functionalName = 's8wts_OC_run%d.nii';
            functional_root = [rootSubj sub_nb '_PASSIVE_DC/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);

            for i = 1:numScans
                matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).scans{i,1} = [functional_file ',' num2str(i)];
            end

            % Load timing file
            timingRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVEDC/Results/pmod/ffx_try1/TimingFiles';
            filename_baseTF = fullfile(timingRootPath, sprintf('timing_file_passiveDC_subject%i_run%i', str2double(sub_nb), jrun-1));
            timingFilePath = [filename_baseTF '_pmod_V2_.mat'];

            matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).multi = {timingFilePath};
            matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).regress = struct('name', {}, 'val', {});
            matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).multi_reg = {NregfilePath};
            matlabbatch{steps}.spm.stats.fmri_spec.sess(global_sess_cnt).hpf = 128;
        end
    end

    matlabbatch{steps}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{steps}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{steps}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{steps}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{steps}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{steps}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{steps}.spm.stats.fmri_spec.cvi = 'AR(1)';
end

%% CREATE BATCH -- Estimation

if ismember('estimate', options.steps_to_run)
    disp('Defining FFX estimation...')
    steps = steps + 1;
    matlabbatch{steps}.spm.stats.fmri_est.spmmat = {[resultsFolderPath '/SPM.mat']};
    matlabbatch{steps}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{steps}.spm.stats.fmri_est.method.Classical = 1;
end

%% CREATE BATCH -- Contrasts

if ismember('contrasts', options.steps_to_run)
    disp('Defining FFX group contrasts...')
    steps = steps + 1;

    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
    contrast = [];
    
    % Basis weights for Pmod (Col 1: Stim1, Col 2: Pmod1, Col 3: Stim2, Col 4: Pmod2, Col 5: TargetDot)
    contrast_basis = [0 1 0 1 0]; 

    for sub_idx = 1:length(subj_nb_list)
        subs = subj_nb_list(sub_idx);
        if subs < 10
            sub_nb = ['0' num2str(subs)];
        else
            sub_nb = num2str(subs);
        end

        run_nb = length(options.Sessions_names.(['subj' sub_nb]));

        for jrun = 1:run_nb
            rootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/fMRI_DATA_2024_sorted/PASSIVE_DC/Multiple_regressors/SOUNDFMRI_SUJET';
            NregfilePath = [rootPath sub_nb '_PASSIVE_DC/multiple_regressors_run' sprintf('%d.txt', jrun-1)];
            data = load(NregfilePath);
            [~, RONI] = size(data);

            % Concatenate contrast vector across all combined runs
            contrast = [contrast contrast_basis zeros(1, RONI)];
        end
    end

    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name = 'Pmod_FFX_Group';
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = contrast;
    matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{steps}.spm.stats.con.delete = 1;
end
