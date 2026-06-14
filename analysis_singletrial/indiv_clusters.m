%% Soundfmri: compute spm T maps and thresholds to make individual masks with univariate results
% J Boyer - Oct. 2025


%% set up
clear; clc; close all;
addpath('/Applications/spm12/');
addpath('/Applications/spm12/toolbox/CyclotronResearchCentre-SPM_ClusterSizeThreshold/'); % not sure -- i only use spm function actually
outputdirbase = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/Oct25/indivClusters/';
SPM_pmod_conj_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/CONJUNCTION/Results/FirstLevel/';
p_unc = .001;
p_corr = .05;

subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 25 26 27 28 29 30 32];

%% loop across subjects
for isubj = subjects
    % prepare outputdir
    outputdir = [outputdirbase 'subj' num2str(isubj) '/'];
    if ~isfolder(outputdir)
        mkdir(outputdir);
    end
    % load indiv SPM.mat
    if isubj < 10
        load([SPM_pmod_conj_dir 'subj0' num2str(isubj) '/SPM.mat']);
        SPMfolder = [SPM_pmod_conj_dir 'subj0' num2str(isubj)];
    else
        load([SPM_pmod_conj_dir 'subj' num2str(isubj) '/SPM.mat']);
        SPMfolder = [SPM_pmod_conj_dir 'subj' num2str(isubj)];
    end
    % --- get the thresholds ----------------------------------------------
    % get the contrasts -- there are 2, 1 is active, 2 is passive
    n_contr = numel(SPM.xCon);
    contrasts = cell(1,n_contr);
    % loop across contrasts
    for con = 1:n_contr
        tmap = fullfile(SPMfolder, sprintf('spmT_%04d.nii', con));
        if ~exist(tmap,'file')
            warning('T-map not found for contrast %d, skipping', con);
            continue
        end
        contrasts{con} = SPM.xCon(con).name;


        % --- uncorrected p < .001 ---
        df  = [SPM.xCon(con).eidf SPM.xX.erdf]; % numerator, denominator dfs
        t_unc = spm_invTcdf(1 - p_unc, df(2)); % critical T
        out_unc = fullfile(outputdir, [contrasts{con} '_spmT_thr_unc001.nii']);
        threshold_image(tmap, t_unc, out_unc);

        % --- FWE peak-corrected p < .05 ---
        % Build xSPM request
        xSPM = struct();
        xSPM.swd       = SPMfolder;
        xSPM.Ic        = con;
        xSPM.n         = 1;
        xSPM.Im        = [];
        xSPM.pm        = []; % No masking
        xSPM.Ex        = 0; % No exclusive mask
        xSPM.k         = 0; % minimum cluster size
        xSPM.u         = p_corr;
        xSPM.thresDesc = 'FWE';
        try
            [SPM, xSPMout] = spm_getSPM(xSPM);
            t_fwe1 = xSPMout.u;
            out_fwe = fullfile(outputdir, [contrasts{con} '_spmT_thr_FWE05.nii']);
            threshold_image(tmap, t_fwe1, out_fwe);
        catch ME
            warning('FWE threshold failed for contrast %d: %s', con, ME.message);
        end
    end

end



%% helper function(s)

function threshold_image(infile, thr, outfile)
V = spm_vol(infile);
Y = spm_read_vols(V);
mask = Y >= thr;
Y_thr = Y .* mask;
Vout = V;
Vout.fname = outfile;
spm_write_vol(Vout, Y_thr);
fprintf(' -> wrote %s\n', outfile);
end

function threshold_image_positive(infile, thr, outfile)
V = spm_vol(infile); Y = spm_read_vols(V);
mask = Y >= thr;
Ythr = zeros(size(Y)); Ythr(mask)=Y(mask);
Vout=V; Vout.fname=outfile; spm_write_vol(Vout,Ythr);
fprintf(' -> wrote %s  (%d voxels)\n',outfile,nnz(mask));
end
