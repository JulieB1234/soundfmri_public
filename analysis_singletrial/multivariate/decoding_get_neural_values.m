% j boyer / the decoding toolbox / chatgpt
% for soundfmri - january 2026


%% objective
% For each fold (run r = 1..9):
% - Training
% runs ≠ r (so 8/9th of trials)
% trials where snr ∈ {1,5}
% - Testing
% run = r (so 1/9th of trials)
% trials where snr ∈ {1,2,3,4,5} (i.e. all)

% This gives: FOR EACH SUBJECT
% - 9 trained SVMs with 9 hyperplans
% - Each model tested on all SNRs, run-wise independent
% - Decision value per test trial
% - RFE performed only on SNR 1 vs 5 training data
% - RFE - selected voxels across run

%% set ups

clear; clc; close all;

warning('off');

addpath('/Applications/decoding_toolbox/');
addpath('/Applications/spm12/');
addpath('/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes');

temp = spm_vol('/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Scans/SOUNDFMRI_SUJET02_ACTIVE/wts_OC_run0.nii');
ref_img = temp(1);

%% ===================== USER PARAMETERS =====================

subjects = [2 3 4 5 6 7 8 9]; % rajout < 10 en noA1
%subjects = [29];
% ERROR : 29P --> empty FWEc mask !
conditions = {'active','passive'};
snr_train  = [1 5];

analysis = 'ROI';
decoder  = 'libsvm';
method   = 'classification';

%mask_dir   = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/indivClusters/';
%mask_base = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/new_ROIs_2/unc001/';
mask_base = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/old_attempts/new_ROIs_4_conj_CSF/conjROIs_indivClusters/';

input_base = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelD/';
output_base= '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI3/';

%threshold = 10; % 10 25 50

%% ===================== LOOP =====================
% loop across ROIs (audit and extra audit)
%for iroi = 1:2
for iroi = 2
    if iroi == 1 % only audit voxels
        mask_dir = [mask_base 'HO_thr' num2str(threshold) '/onlyA1/'];
    elseif iroi == 2 % audit voxels removed
        mask_dir = [mask_base 'HO_thr' num2str(threshold) '/noA1/'];
    end
    for sbj = subjects
        for ic = 1:numel(conditions)

            cond = conditions{ic};
            active = strcmp(cond,'active');
            passive = strcmp(cond,'passive');

            %% ---------- Paths ----------

            if iroi == 1
                outputdir = fullfile(output_base,sprintf('subj%02d_%s_A1_thr%i',sbj,cond,threshold));
            elseif iroi == 2
                outputdir = fullfile(output_base,sprintf('subj%02d_%s_NoA1_thr%i',sbj,cond,threshold));
            end
            if ~exist(outputdir,'dir'); mkdir(outputdir); end

            if active
                inputdir  = fullfile(input_base,cond,'V1',sprintf('subj%02d',sbj),'GLMsingle');
                mask_nii = [mask_dir 'subj' num2str(sbj) '/active.nii'];
            elseif passive
                inputdir  = fullfile(input_base,cond,'V1',sprintf('subj%i',sbj),'GLMsingle');
                mask_nii = [mask_dir 'subj' num2str(sbj) '/passive.nii'];
            end
            %% ---------- Load data ----------
            load(fullfile(inputdir,'TYPED_FITHRF_GLMDENOISE_RR.mat')); % modelmd
            load(fullfile(inputdir,'DESIGNINFO.mat'));                % stimorder, design

            betas  = modelmd;
            clabel = stimorder(:);
            n_trials = numel(clabel);
            n_runs   = size(design,2);

            %% ========================================================
            %% CHUNKS (LORO) — with subject 32 active exception
            %% ========================================================

            Pb32A = false;
            chunk = nan(n_trials,1);

            if sbj == 32 && active
                % ---- Special case: subject 32 active ----
                % 447 trials; last 3 trials of run 7 removed
                % Final structure: 9 runs (0–8 in original code)

                trials_per_run = 50;

                % runs 0–5 (6 runs of 50)
                for irun = 1:6
                    idx = (irun-1)*trials_per_run + (1:trials_per_run);
                    chunk(idx) = irun;
                end

                % remaining uneven runs
                chunk(301:347) = 7;   % run 6
                chunk(348:397) = 8;   % run 7
                chunk(398:447) = 9;   % run 8

                Pb32A = true;

            else
                % ---- Standard case ----
                trials_per_run = n_trials / n_runs;
                for irun = 1:n_runs
                    idx = (irun-1)*trials_per_run + (1:trials_per_run);
                    chunk(idx) = irun;
                end
            end

            % safety check
            if any(isnan(chunk))
                error('Chunk assignment failed for subject %d (%s)',sbj,cond);
            end

            %% ---------- Reshape data ----------
            SLbetas = reshape(betas,[],n_trials)';     % trials × voxels

            V = spm_vol(mask_nii);
            mask = spm_read_vols(V) > 0;
            mask_idx = find(mask);

            if (size(mask_idx,1)) ~= 0

                data = SLbetas(:,mask_idx);

                %% ---------- Recode labels ----------
                label = clabel;
                label(label == 1) = -1;
                label(label == 5) =  1;
                label(label > 1 & label < 5) = 1;   % dummy for intermediate SNRs

                %% ===================== TDT SETUP =====================

                cfg = decoding_defaults;
                cfg.analysis = analysis;
                cfg.decoding.method   = method;
                cfg.decoding.software = decoder;
                %cfg.results.output    = {'decision_values'}; % nope doesnt work if we do RFE
                cfg.results.output    = {'AUC'};
                cfg.results.dir       = outputdir;

                % Scaling (libsvm)
                cfg.scale.method     = 'min0max1';
                cfg.scale.estimation = 'all';

                % RFE
                cfg.feature_selection.method   = 'embedded';
                cfg.feature_selection.embedded = 'RFE';
                cfg.feature_selection.direction= 'backward';
                cfg.feature_selection.n_vox    = 'automatic';
                cfg.feature_selection.nested_n_vox = 'automatic';
                cfg.feature_selection.design = [];
                cfg.feature_selection.design.function.name = 'make_design_cv'; % we have a custom one

                % added
                cfg.zigzig = outputdir; % to take outputdir path within functions and store dvals into it
                cfg.clabel = clabel;
                %% ---------- Passed data ----------
                passed_data.data = double(data);
                passed_data.dim  = size(betas(:,:,:,1));
                passed_data.mask_index = mask_idx;

                [passed_data,cfg] = fill_passed_data(passed_data,cfg,label,chunk);

                if Pb32A
                    cfg.design.unbalanced_data = 'ok';
                end

                %% ===================== LORO DESIGN =====================

                runs = unique(chunk);
                n_runs_eff = numel(runs);

                cfg.design.train = zeros(n_trials,n_runs_eff);
                cfg.design.test  = zeros(n_trials,n_runs_eff);
                cfg.design.label = repmat(label,1,n_runs_eff);
                cfg.design.set   = 1:n_runs_eff;
                cfg.design.function = 'LORO_train15_testAll';

                for r = 1:n_runs_eff
                    is_train_run = chunk ~= runs(r);
                    is_test_run  = chunk == runs(r);
                    is_train_snr = ismember(clabel,snr_train);

                    cfg.design.train(:,r) = is_train_run & is_train_snr;
                    cfg.design.test(:,r)  = is_test_run;
                end

                %% ===================== RUN DECODING =====================

                %results = decoding(cfg,passed_data);
                results = decoding_julie(cfg,passed_data); % slightly modified just to store model parameters and dvals

                %% ===================== RECONSTRUCT DECISION VALUES =====================

                % dv = nan(n_trials,1);
                % for r = 1:n_runs_eff
                %     idx = cfg.design.test(:,r)==1;
                %     dv(idx) = results.decision_values.output(idx,r);
                % end
                %
                % %% ---------- Save ----------
                % save(fullfile(outputdir,'decision_values_LORO.mat'), ...
                %     'dv','clabel','chunk','snr_train','Pb32A');
                %
                % fprintf('Subject %d (%s) done\n',sbj,cond);

                %% ========================================================
                %% SAVE RFE-SELECTED VOXELS (ACROSS RUNS)
                %% ========================================================

                fs_index = results.feature_selection.fs_index;

                sel_vox = unique(cat(2,fs_index{:}));   % indices in masked space
                all_vox = mask_idx(sel_vox);

                volume = zeros(ref_img.dim);
                volume(all_vox) = 1;

                Vout = ref_img;
                Vout.fname = fullfile(outputdir,'RFEselected_voxels_acrossRuns.nii');
                spm_write_vol(Vout,volume);

                [x,y,z] = ind2sub(size(volume),find(volume));
                voxel_coords = [x y z];
                mni_coords = ref_img.mat * [voxel_coords'; ones(1,size(voxel_coords,1))];
                mni_coords = mni_coords(1:3,:)';

                save(fullfile(outputdir,'RFEselected_voxels_acrossRuns_VX.mat'), ...
                    'voxel_coords');
                save(fullfile(outputdir,'RFEselected_voxels_acrossRuns_MNI.mat'), ...
                    'mni_coords');

                fprintf('Subject %d (%s) done\n',sbj,cond);
            else % mask is empty
                fprintf('\n skipping subj %i cond %s : empty mask for roi number %i \n', sbj, cond, iroi);

            end
        end
    end
end
%% OUTPUT
% decoding_out.mat -> decision values
% res_AUC.mat -> AUC -> output -> AUC value
% true_labels.mat -> initial SNR labels (1-5)
