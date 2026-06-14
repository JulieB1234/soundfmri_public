function [matlabbatch, options] = FirstLevelParameters_mw3(options,sub_nb)

%% specification
%global options;

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

steps = 0;

if ismember('specify',options.steps_to_run) % Specify 1st level, ie create GLM using multiple regressors and timing file
    disp('Defining specification...')
    steps = steps+1;

    resultsRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_MWnewER_3/results_1stLevel';
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

    matlabbatch{steps}.spm.stats.fmri_spec.dir = {resultsFolderPath};
    matlabbatch{steps}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{steps}.spm.stats.fmri_spec.timing.RT = 1.66;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{steps}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

    for jrun = 1:run_nb %length(options.Sessions_names) %(1 to 20)
            rootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/SOUNDFMRI_SUJET';
            MultReg_root = [rootPath sub_nb '_PASSIVE/multiple_regressors_run'];
            MultReg_root2 = sprintf('%d.txt',jrun-1);
            NregfilePath = [MultReg_root MultReg_root2];
            data = load(NregfilePath);
            [numScans, numNreg] = size(data);
            disp(['Number of scans: ' num2str(numScans) ' for run ' num2str(jrun-1)]);
            disp(['Number of regressors: ' num2str(numNreg) ' for run ' num2str(jrun-1)]);
            rootSubj = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/SOUNDFMRI_SUJET';
            functionalName = 's8wts_OC_run%d.nii';
            functional_root = [rootSubj  sub_nb '_PASSIVE/'];
            functional_file = sprintf([functional_root functionalName], jrun-1);
            vol_nb = numScans;
            for i = 1:vol_nb % total number of scans in the run's nifti file
                matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).scans{i,1} = [functional_file ',' num2str(i)];
            end
            % get timing files
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            timingRootPath = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_MWnewER_3/timing_files';
            % generate the filename based on GLM type and PMod version
            filename_baseTF = fullfile(timingRootPath, sprintf('mw3_timing_file_passive_subject%i_run%i', str2double(sub_nb), jrun-1));

            timingFilePath = [filename_baseTF '.mat'];

            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi = {timingFilePath};
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).regress = struct('name', {}, 'val', {});
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).multi_reg = {NregfilePath}; % comment this line to test the cdesign matrix wuthout nuisance regressors
            matlabbatch{steps}.spm.stats.fmri_spec.sess(jrun).hpf = 128;
        % for each run, check the number of nuisance regressors
        if numNreg == 66
            RONI_ok(jrun) = true;
        elseif numNreg ~= 66
            RONI_ok(jrun) = false;
            RONI_corr(jrun) = numNreg;
        end
    end

end
% Masking specification (we don't have one)

matlabbatch{steps}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {}); % fill if ANOVA design
matlabbatch{steps}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{steps}.spm.stats.fmri_spec.volt = 1;
matlabbatch{steps}.spm.stats.fmri_spec.global = 'None';
matlabbatch{steps}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{steps}.spm.stats.fmri_spec.mask = {''};
matlabbatch{steps}.spm.stats.fmri_spec.cvi = 'AR(1)';
%% estimation

if ismember('estimate',options.steps_to_run)
    disp('Defining estimation...')

    steps = steps+1;

    % go fetch the SPM.mat file created just before
    matlabbatch{steps}.spm.stats.fmri_est.spmmat            = {[resultsFolderPath '/SPM.mat']};
    matlabbatch{steps}.spm.stats.fmri_est.write_residuals  = 0;
    matlabbatch{steps}.spm.stats.fmri_est.method.Classical = 1;
end

%% contrasts

% current model regressors
% 1 = stim probed + 2 pmod
% 2 = stim not probed + 1 pmod
% 3 = fixation point
% 4 5 6 7 = resp screen (1: quiz, 2: RT, 3: MW, 4: 'click to continue' / none)
% 8 = keypress

%% NEW REGRESSORS (V4)
% 1 stim heard
% 2 stim heard x pmod intensiy
% 3 stim not heard
% 4 stim not heard x pmod intensiy
% 5 stim not probed
% 6 stim not probed x pmod intensiy
% 7 fix point
% 8 9 10 11 the 4 possible resp. screens
% 12 keypress

% BASE CON : 0 0 0 0 0 0 0 0 0 0 0 0

%% fix 18 02 2026
% when a stim onset vector is empty (often it's stim heard) for a given run
% the pmod column is missing 
% so the contrast basis should contain one less regressor
% now timing files function gives this for missing regs:
% pre allocated vector: 0 0 0 0 0 0 0 0 0 0 0 0
% if stim onset missing (ionset 1 2 or 3) => eg stim heard: 1 2 0 0 0 0 0 0
% 0 0 0 0 -- so missing pmod column takes value 2
% --> must then be deleted from contrast base not just equal to 0 instead
% of 1 like it is the case for the stim onset
%%


% if ismember('contrasts',options.steps_to_run)
%     disp('Defining contrasts...')
%     steps = steps+1;
% 
%     % HnotH contrast (1)
%     matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
%     base_contrast = [1 0 -1 0 0 0 0 0 0 0 0 0];
%     % *stim_heard* ; pmod1 ; *stim_notheard* ; pmod2 ; stim_notprobed ; pmod3 ; fix point ; respscreen1 ; respscreen2 ; respscreen3 ; respscreen4 ; keypress
%     con = [];
%     clear jrun;
%     for jrun = 1:run_nb
%         new_base_contrast = base_contrast;
%         % Define number of nuisance regressors (RONI <3)
%         if RONI_ok(jrun) == true
%             fprintf('\n number of nreg ok for run %d \n', jrun);
%             RONI = 66;
%         elseif RONI_ok(jrun) == false
%             fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
%             RONI = RONI_corr(jrun);
%         end
%         % Check if the regressor is missing
%         % 1/ adapt contrast basis to missing stim onset
%         regressors_of_interest_indices = find(base_contrast); % 1 3
%         num_regressors_of_interest = numel(regressors_of_interest_indices); % 2
%         for ireg = 1:num_regressors_of_interest
%             regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
%             if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(regressor_index) ~= 0
%                 new_base_contrast(regressors_of_interest_indices(ireg)) = 0;
%             end
%         end
%         % 2/ adapt contrast basis to missing pmod column
%         if any((options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}) == 2)
%             missing_pmod = find((options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun})==2);
%             % remove corresponding zero from basis contrast
%             new_base_contrast(missing_pmod) = [];
%         end
%         % compute the contrast chuncks for each run
%         con = [con new_base_contrast zeros(1,RONI)];
%     end
% 
%     matlabbatch{steps}.spm.stats.con.consess{1}.tcon.name    = 'HnotH';
%     matlabbatch{steps}.spm.stats.con.consess{1}.tcon.weights = con;
%     matlabbatch{steps}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
% 
%     % intensity pmod contrast (2)
%     matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
%     base_contrast = [0 1 0 1 0 1 0 0 0 0 0 0];
%     % stim_heard ; *pmod1* ; stim_notheard ; *pmod2* ; stim_notprobed ; *pmod3* ; fix point ; respscreen1 ; respscreen2 ; respscreen3 ; respscreen4 ; keypress
%     con = [];
%     clear jrun;
%     for jrun = 1:run_nb
%         new_base_contrast = base_contrast;
%         % Define number of nuisance regressors (RONI <3)
%         if RONI_ok(jrun) == true
%             fprintf('\n number of nreg ok for run %d \n', jrun);
%             RONI = 66;
%         elseif RONI_ok(jrun) == false
%             fprintf('\n using %d nuisance regressors instead of 66... \n', RONI_corr(jrun))
%             RONI = RONI_corr(jrun);
%         end
%         % Check if the regressor is missing
%         % 1/ adapt contrast basis to missing stim onset
%         regressors_of_interest_indices = find(base_contrast); % 2 4 6
%         num_regressors_of_interest = numel(regressors_of_interest_indices); % 3
%         for ireg = 1:num_regressors_of_interest
%             regressor_index = regressors_of_interest_indices(ireg); % Get the actual index
%             if options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}(regressor_index) ~= 0
%                 new_base_contrast(regressors_of_interest_indices(ireg)) = 0;
%             end
%         end
%         % 2/ adapt contrast basis to missing pmod column
%         if any((options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun}) == 2)
%             missing_pmod = find((options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun})==2);
%             % remove corresponding zero from basis contrast
%             new_base_contrast(missing_pmod) = [];
%         end
%         % compute the contrast chuncks for each run
%         con = [con new_base_contrast zeros(1,RONI)];
%     end
% 
%     matlabbatch{steps}.spm.stats.con.consess{2}.tcon.name    = 'int_pmod';
%     matlabbatch{steps}.spm.stats.con.consess{2}.tcon.weights = con;
%     matlabbatch{steps}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
% 
% end
if ismember('contrasts',options.steps_to_run)
    disp('Building Contrast Vectors...')
    steps = steps+1;
    matlabbatch{steps}.spm.stats.con.spmmat = {[resultsFolderPath '/SPM.mat']};
    
    % Define templates
    con_names = {'HnotH', 'Intensity_All'};
    con_vecs  = [1 0 -1 0 0 0 0 0 0 0 0 0;  % Heard > NotHeard
                 0 1  0 1  0 1 0 0 0 0 0 0]; % All Pmods combined

    for c = 1:length(con_names)
        final_vec = [];
        for jrun = 1:run_nb
            % Get the 1x12 binary mask of dummy columns
            missing_mask = options.missing_regressors.(sprintf('subj%i', str2double(sub_nb))){jrun};
            
            % Zero out weights for this run where columns are dummies
            current_run_con = con_vecs(c, :);
            current_run_con(logical(missing_mask)) = 0;
            
            % Add Nuisance Regressors (Realignment)
            RONI = 66; if ~RONI_ok(jrun); RONI = RONI_corr(jrun); end 
            final_vec = [final_vec current_run_con zeros(1, RONI)];
        end
        
        matlabbatch{steps}.spm.stats.con.consess{c}.tcon.name = con_names{c};
        matlabbatch{steps}.spm.stats.con.consess{c}.tcon.weights = final_vec;
        matlabbatch{steps}.spm.stats.con.consess{c}.tcon.sessrep = 'none';
    end
end
end
