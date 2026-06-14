function matlabbatch=FirstLevelParameters_FIRpassive(options,sub_nb)


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


%% CREATE BATCH -- specification

steps = 0;

if ismember('specify',options.steps_to_run) % Specify 1st level, ie create GLM using multiple regressors and timing file
    disp('Defining specification...')
    steps = steps+1;

    % result folder & path
    %resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/1stLevel_wholeBrain/';
    %resultsRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/1stLevel_new_allSNRs_12_7_preOnset/';
    resultsRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/FIR/1stLevel_new_allSNRs_12_7_preOnset/noSNR1/';
    %resultsRootPath = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/1stLevel_wholeBrain/passive_withAllNregs/testTimings/';
    resultsFolderPath = fullfile(resultsRootPath, ['results_subj' sub_nb 'passiveSNR_wholebrain']);
    % check if the folder already exists; if not, create it
    if ~exist(resultsFolderPath, 'dir')
        mkdir(resultsFolderPath);
    end
    addpath(resultsFolderPath);

    matlabbatch{steps}.spm.stats.fmri_spec.dir = {resultsFolderPath}; %{'/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/ACTIVE'};
    matlabbatch{steps}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{steps}.spm.stats.fmri_spec.timing.RT = 1.66;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

    % loop across sessions
    for jrun = 1:run_nb 
        % get the scans & Nregs
        NregfilePath = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET' sub_nb '_PASSIVE/multiple_regressors_run' sprintf('%d.txt',jrun-1)];
        %NregfilePath = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressorsMOD/SOUNDFMRI_SUJET' sub_nb '_PASSIVE/multiple_regressorsCUT42_run' sprintf('%d.txt',jrun-1)];
        data = load(NregfilePath);
        [vol_nb, numNreg] = size(data);
        disp(['Number of scans: ' num2str(vol_nb) ' for run ' num2str(jrun-1)]);
        disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
        functional_file = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET' sub_nb '_PASSIVE/s8wts_OC_run' sprintf('%d.nii',jrun-1)];
        for i = 1:vol_nb % total number of scans in the run
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
        end

        % get the timing files
        nb = str2double(sub_nb);
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        %timingFilePath = ['/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/TimingFiles/timing_file_passive_subject' num2str(nb) '_run' num2str(jrun-1) '_FIRpreTR.mat'];
        timingFilePath = ['/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/FIR/TimingFiles/timing_file_passive_subject' num2str(nb) '_run' num2str(jrun-1) '_FIRpreTR_noSNR1.mat'];
        
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath}; 
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath}; 
        matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        % for each run, check the number of nuisance regressors
        if numNreg == 66
            RONI_ok(jrun) = true;
        elseif numNreg ~= 66
            RONI_ok(jrun) = false;
            RONI_corr(jrun) = numNreg;
        end
    end


    %% not ROI based anymore because too fat for storage & too long +++
    % try whole brain then we'll apply rois
    % Masking specification 
    matlabbatch{steps}.spm.stats.fmri_spec.mask = {''}; %Alizée's code : [rootSubj dir_sess_func.name filesep ExplicitMasking] --> path for .nii file; only if masking wanted
    
    % FIR stuff
    matlabbatch{steps}.spm.stats.fmri_spec.bases.fir.length = options.FIRwindow; 
    matlabbatch{steps}.spm.stats.fmri_spec.bases.fir.order = options.FIRorder;

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

if ismember('contrasts',options.steps_to_run)
    disp('Defining contrasts...')
    steps = steps+1;
    % find SPM.mat
    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};

    % !! not the same as active !!
    % regressors = 1 2 3 4 5 6 7 8 9 10 11 12 with
    % - 1-5 = vowA, snr 1 - 5
    % - 6-10 = vowE, snr 1 - 5
    % - 11-12 = only 2 extra regressors (fixation point, keypress1)
    % ALL must be expanded with nBins = 12 regressors (instead of the HRF
    % convolution)

    % We need an F contrast to test each bin separately (here, against
    % chance)
    % format must be : (for classical number of nuisance regs and runs but
    % it can vary)
    % - 12 columns (one per time bin)
    % - 11 runs x [12 conditions x 12 time bins] + 66 nuisance regressors] =
    % 2310 regressors in total (+ an extra 11 at the end = one constant per
    % run but we dont care about them)

    %nBins = options.FIRorder + 1; % that's what chatgpt says but no apparently 
    nBins = options.FIRorder;
    nSNR  = 5;
    nStim = 2;
    nExtra = 2;
    nCondsTotal = nStim * nSNR + nExtra;    % = 12
    nRegPerSess = nCondsTotal * nBins;


    %% F contrast for each snr alone
    % (question: "does the FIR for snr5 deviate from baseline (across all bins)?”)
    % indices of snr5 for both stim types
    cond_snr5_stim1 = 5;   % 5th condition
    cond_snr5_stim2 = 10;  % 10th condition
    cond_snr4_stim1 = 4;
    cond_snr4_stim2 = 9;  
    cond_snr3_stim1 = 3;
    cond_snr3_stim2 = 8;
    cond_snr2_stim1 = 2;
    cond_snr2_stim2 = 7;
    cond_snr1_stim1 = 1;
    cond_snr1_stim2 = 6;

    %% F-contrast for snr5 bins (A+E pooled)
    contrast_basis_F = zeros(nBins, nRegPerSess);
    for b = 1:nBins
        idx1 = (cond_snr5_stim1-1)*nBins + b;
        idx2 = (cond_snr5_stim2-1)*nBins + b;
        contrast_basis_F(b, [idx1 idx2]) = 1;
    end

    contrast_F_full = [];
    for jrun = 1:run_nb
        if RONI_ok(jrun)
            nNuis = 66;
        else
            nNuis = RONI_corr(jrun);
        end
        pad = zeros(size(contrast_basis_F,1), nNuis);
        contrast_F_full = [contrast_F_full contrast_basis_F pad];
    end

    matlabbatch{steps}.spm.stats.con.consess{1}.fcon.name   = 'snr5 (all bins) pooled stim';
    matlabbatch{steps}.spm.stats.con.consess{1}.fcon.weights = {contrast_F_full};
    matlabbatch{steps}.spm.stats.con.consess{1}.fcon.sessrep = 'none';




    % Clean old contrasts
    matlabbatch{steps}.spm.stats.con.delete = 0;

end
