%% TreeBH Step 2 & 3: Model Level & Contrast Level FDR Testing with Dual Output
% Includes Conjunction Null (Active & Passive) as an explicit 7th contrast in GLM 1.
clear; clc; close all; 
addpath('/Applications/spm12/');

%% INPUT = 2nd level SPM.mat files for analyses to add in the correction
%% OUTPUT = stats text + .nii thresholded fMRI maps (1 value per voxel)

%% 1. Configuration & Setup
alpha_global = 0.05;

% Output Directory for Scaled Thresholded Maps
output_dir = fullfile(pwd, 'TreeBH_V5_Results');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Define Path to SPM's Canonical T1 Template
canonical_t1 = fullfile(spm('Dir'), 'canonical', 'avg152T1.nii');

% Base directories where SPM.mat and spmT maps live
glm1_base = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/CONJUNCTION/Results/SecondLevel_pmod/';

% GLM 1 Contrasts (Original 6)
glm1_spm_mat = fullfile(glm1_base, 'SPM.mat');
glm1_files = {
    fullfile(glm1_base, 'spmT_0001.nii');  % 1: Active
    fullfile(glm1_base, 'spmT_0002.nii');  % 2: Passive
    fullfile(glm1_base, 'spmT_0003.nii');  % 3: Active minus Passive
    fullfile(glm1_base, 'spmT_0004.nii');  % 4: Passive minus Active
    fullfile(glm1_base, 'spmT_0005.nii');  % 5: minus Active
    fullfile(glm1_base, 'spmT_0006.nii')   % 6: minus Passive
};

% GLM 3 Contrasts (4 total)
glm3_dirs = {
    '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/with_snr1/2ndLevel/con2_H_minus_notH_thresh/';
    '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_ActiveHnotH_v2/with_snr1/2ndLevel/con5_notH_minus_noS/';
    '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/uniV_MWnewER_3/unconscious2/results_2ndLevel/con2_Probed_notH_noS/';
    '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/MW/Results/2ndLevelAll27_new/'
};
glm3_files   = cellfun(@(d) fullfile(d, 'spmT_0001.nii'), glm3_dirs, 'UniformOutput', false);
glm3_spm_mats = cellfun(@(d) fullfile(d, 'SPM.mat'), glm3_dirs, 'UniformOutput', false);

%% 2. Resample avg152T1 & Generate 0.2 Thresholded Mask
disp('Resampling avg152T1.nii to functional image dimensions...');
ref_func_file = glm1_files{1};
flags = struct('mask', 0, 'mean', 0, 'interp', 0, 'which', 1);
spm_reslice({ref_func_file; canonical_t1}, flags);

[dir_c, name_c, ext_c] = fileparts(canonical_t1);
resampled_t1_path = fullfile(dir_c, ['r' name_c ext_c]);
V_mask = spm_vol(resampled_t1_path);
t1_data_resampled = spm_read_vols(V_mask);

% Create logical brain mask
brain_mask = (t1_data_resampled >= 0.2) & ~isnan(t1_data_resampled);
fprintf('Mask generated successfully!\n');
fprintf('  Functional Grid Dimensions : %d x %d x %d\n', V_mask.dim);
fprintf('  Retained Search Space (N)  : %d in-brain voxels\n\n', sum(brain_mask(:)));

%% 3. Load & Convert spmT Maps to p-Value Vectors
disp('Converting T-maps to p-value vectors using thresholded MNI search space...');
p_glm1 = get_pvals_for_model(glm1_files, glm1_spm_mat, brain_mask);

% --- Compute Conjunction Null (Active & Passive) ---
p_conj = max(p_glm1{1}, p_glm1{2});
p_glm1{7} = p_conj; % Add as 7th contrast

p_glm3 = cell(numel(glm3_files), 1);
for i = 1:numel(glm3_files)
    p_temp = get_pvals_for_model(glm3_files(i), glm3_spm_mats{i}, brain_mask);
    p_glm3{i} = p_temp{1};
end

%% 4. LEVEL 1: Test Models via Simes Omnibus Test
disp('========================================================================');
disp('--- LEVEL 1: Model Level Testing (Omnibus Simes across all voxels) ---');
disp('========================================================================');
p_omnibus_glm1 = combine_simes(p_glm1);
p_omnibus_glm3 = combine_simes(p_glm3);
p_level1_raw   = [p_omnibus_glm1; p_omnibus_glm3];

% Calculate BH Adjusted q-values
[p_level1_adj, sig_level1] = bh_correction(p_level1_raw, alpha_global);

fprintf('GLM 1 Omnibus | Raw p = %.5e | Adj q = %.5e | Pass Level 1: %d\n', ...
    p_level1_raw(1), p_level1_adj(1), sig_level1(1));
fprintf('GLM 3 Omnibus | Raw p = %.5e | Adj q = %.5e | Pass Level 1: %d\n\n', ...
    p_level1_raw(2), p_level1_adj(2), sig_level1(2));

%% 5. LEVEL 2: Test Contrasts within Significant GLMs
disp('========================================================================');
disp('--- LEVEL 2: Contrast Level Testing (Simes per Contrast) ---');
disp('========================================================================');
contrast_names_1 = {'Active', 'Passive', 'Act-Pass', 'Pass-Act', 'minus Active', 'minus Passive', 'Conjunction Active&Passive'};

% --- GLM 1 Contrasts ---
if sig_level1(1)
    disp('Testing GLM 1 Contrasts...');
    p_c_glm1_raw = cellfun(@simes_p, p_glm1);
    [q_c_glm1, sig_c_glm1] = bh_correction(p_c_glm1_raw, alpha_global);
    
    for i = 1:numel(contrast_names_1)
        fprintf('  GLM 1 [%-26s] | Raw p = %.5e | Adj q = %.5e | Pass Level 2: %d\n', ...
            contrast_names_1{i}, p_c_glm1_raw(i), q_c_glm1(i), sig_c_glm1(i));
    end
else
    sig_c_glm1 = false(1, 7);
    disp('GLM 1 did not pass Level 1. Pruning all GLM 1 contrasts.');
end
fprintf('\n');

% --- GLM 3 Contrasts ---
if sig_level1(2)
    disp('Testing GLM 3 Contrasts...');
    p_c_glm3_raw = cellfun(@simes_p, p_glm3);
    [q_c_glm3, sig_c_glm3] = bh_correction(p_c_glm3_raw, alpha_global);
    
    contrast_names_3 = {'3a_H-NH_Act', '3a_NH-N_Act', '3b_NH-N_Pass', '3c_H-NH_Pass'};
    for i = 1:numel(contrast_names_3)
        fprintf('  GLM 3 [%-26s] | Raw p = %.5e | Adj q = %.5e | Pass Level 2: %d\n', ...
            contrast_names_3{i}, p_c_glm3_raw(i), q_c_glm3(i), sig_c_glm3(i));
    end
else
    sig_c_glm3 = false(size(glm3_files));
    disp('GLM 3 did not pass Level 1. Pruning all GLM 3 contrasts.');
end
fprintf('\n');

%% 6. LEVEL 3: Voxel-Wise Thresholding with Top-Down Alpha Scaling
disp('========================================================================');
disp('--- LEVEL 3: Voxel-Wise Testing & Thresholding ---');
disp('========================================================================');

% Calculate Top-Down Scaled Alpha Thresholds
n_glm1_total = numel(contrast_names_1);
n_glm1_passed = sum(sig_c_glm1);
alpha_glm1_l3 = alpha_global * (n_glm1_passed / n_glm1_total);

n_glm3_total = numel(glm3_files);
n_glm3_passed = sum(sig_c_glm3);
alpha_glm3_l3 = alpha_global * (n_glm3_passed / n_glm3_total);

fprintf('Top-Down Alpha Scaling Ratios:\n');
fprintf('  GLM 1: %d/%d passed -> Target Alpha Level 3 = %.4f\n', n_glm1_passed, n_glm1_total, alpha_glm1_l3);
fprintf('  GLM 3: %d/%d passed -> Target Alpha Level 3 = %.4f\n\n', n_glm3_passed, n_glm3_total, alpha_glm3_l3);

% --- Process GLM 1 Surviving Contrasts ---
if sig_level1(1) && n_glm1_passed > 0
    disp('--- GLM 1 Voxel-Wise Summary ---');
    process_level3_voxels_glm1(glm1_files, glm1_spm_mat, p_glm1, ...
        contrast_names_1, sig_c_glm1, brain_mask, alpha_glm1_l3, output_dir);
end

% --- Process GLM 3 Surviving Contrasts ---
if sig_level1(2) && n_glm3_passed > 0
    disp('--- GLM 3 Voxel-Wise Summary ---');
    process_level3_voxels_standard(glm3_files(sig_c_glm3), glm3_spm_mats(sig_c_glm3), ...
        contrast_names_3(sig_c_glm3), brain_mask, alpha_glm3_l3, 'GLM3', output_dir);
end

disp('Level 3 thresholding complete! All maps saved.');

%% Helper Functions
function process_level3_voxels_glm1(file_list, spm_mat, p_cell, names, sig_flags, mask, alpha_target, out_dir)
    S = load(spm_mat);
    df = S.SPM.xX.erdf;
    mask_indices = find(mask);
    for i = 1:numel(names)
        if ~sig_flags(i); continue; end
        
        p_vals = p_cell{i};
        [q_vals, sig_voxels] = bh_correction(p_vals, alpha_target);
        
        % Calculate raw p-value cut-off threshold corresponding to target alpha
        if any(sig_voxels)
            p_threshold_cutoff = max(p_vals(sig_voxels));
        else
            p_threshold_cutoff = 0;
        end
        
        if i <= 6
            % Standard Contrast
            V = spm_vol(file_list{i});
            t_img = spm_read_vols(V);
            thresh_t_img = zeros(size(t_img));
            thresh_t_img(mask_indices(sig_voxels)) = t_img(mask_indices(sig_voxels));
            V_out = V;
        else
            % Conjunction Null (Active & Passive)
            V1 = spm_vol(file_list{1});
            V2 = spm_vol(file_list{2});
            t1_img = spm_read_vols(V1);
            t2_img = spm_read_vols(V2);
            
            min_t_img = min(t1_img, t2_img);
            thresh_t_img = zeros(size(min_t_img));
            thresh_t_img(mask_indices(sig_voxels)) = min_t_img(mask_indices(sig_voxels));
            V_out = V1;
        end
        
        clean_name = strrep(names{i}, ' ', '_');
        clean_name = strrep(clean_name, '&', '_and_');
        out_fname = fullfile(out_dir, sprintf('TreeBH_L3_GLM1_%s_alpha%.4f.nii', clean_name, alpha_target));
        
        V_out.fname = out_fname;
        spm_write_vol(V_out, thresh_t_img);
        
        [~, saved_name, saved_ext] = fileparts(out_fname);
        fprintf('  [%-26s] | Min Raw p = %.3e | Min Adj q = %.3e | Max Sig p-cutoff = %.3e | Sig Voxels = %d\n', ...
            names{i}, min(p_vals), min(q_vals), p_threshold_cutoff, sum(sig_voxels));
    end
    fprintf('\n');
end

function process_level3_voxels_standard(file_list, spm_mats, names, mask, alpha_target, glm_label, out_dir)
    for i = 1:numel(file_list)
        S = load(spm_mats{i});
        df = S.SPM.xX.erdf;
        
        V = spm_vol(file_list{i});
        t_img = spm_read_vols(V);
        
        p_vals = 1 - tcdf(t_img(mask), df);
        p_vals(isnan(p_vals)) = 1;
        p_vals(p_vals <= 0) = eps;
        p_vals(p_vals > 1) = 1;
        
        [q_vals, sig_voxels] = bh_correction(p_vals, alpha_target);
        
        if any(sig_voxels)
            p_threshold_cutoff = max(p_vals(sig_voxels));
        else
            p_threshold_cutoff = 0;
        end
        
        thresh_t_img = zeros(size(t_img));
        mask_indices = find(mask);
        thresh_t_img(mask_indices(sig_voxels)) = t_img(mask_indices(sig_voxels));
        
        clean_name = strrep(names{i}, ' ', '_');
        out_fname = fullfile(out_dir, sprintf('TreeBH_L3_%s_%s_alpha%.4f.nii', glm_label, clean_name, alpha_target));
        
        V_out = V;
        V_out.fname = out_fname;
        spm_write_vol(V_out, thresh_t_img);
        
        [~, saved_name, saved_ext] = fileparts(out_fname);
        fprintf('  [%-26s] | Min Raw p = %.3e | Min Adj q = %.3e | Max Sig p-cutoff = %.3e | Sig Voxels = %d\n', ...
            names{i}, min(p_vals), min(q_vals), p_threshold_cutoff, sum(sig_voxels));
    end
    fprintf('\n');
end

function p_cell = get_pvals_for_model(file_list, spm_mat_path, mask)
    S = load(spm_mat_path);
    df = S.SPM.xX.erdf; 
    
    p_cell = cell(numel(file_list), 1);
    for i = 1:numel(file_list)
        V = spm_vol(file_list{i});
        t_img = spm_read_vols(V);
        
        t_vals = t_img(mask);
        p_vals = 1 - tcdf(t_vals, df);
        
        p_vals(isnan(p_vals)) = 1; 
        p_vals(p_vals <= 0)  = eps;
        p_vals(p_vals > 1)   = 1;
        
        p_cell{i} = p_vals;
    end
end

function p_simes = simes_p(p_vals)
    p_sorted = sort(p_vals(:));
    n = numel(p_sorted);
    p_simes = min((n ./ (1:n)') .* p_sorted);
end

function p_omni = combine_simes(cell_pvals)
    all_p = vertcat(cell_pvals{:});
    p_omni = simes_p(all_p);
end

function [p_adj, sig] = bh_correction(p_vals, alpha)
    m = numel(p_vals);
    [p_sorted, idx] = sort(p_vals);
    
    q_sorted = p_sorted .* (m ./ (1:m)');
    for i = m-1:-1:1
        q_sorted(i) = min(q_sorted(i), q_sorted(i+1));
    end
    q_sorted = min(q_sorted, 1);
    
    p_adj = zeros(m, 1);
    p_adj(idx) = q_sorted;
    sig = p_adj <= alpha;
end
