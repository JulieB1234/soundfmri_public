%% Julie BOYER 2024 -- SOUNDFMRI analysis -- for trial by trial activity analysis using GLMSingle (Prince et al)

% Warning: i suppressed the part that checked glmsingle hasn't be run yet
% for the selected subject so check manually beforehand

%% 20/11/25
% version for SMOOTHED scan data

%% set up
% Start fresh
clear
clc
close all

% Load SPM
addpath('/Applications/spm12/');
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
addpath(genpath("/Users/julieboyer/Desktop/GLMsingle/"));

spm_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE/Results/Results_indiv_ActiveClassic/';
scan_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Scans/';
reg_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/ACTIVE/Multiple_regressors/';

%subj_nb_list = {'2','3','4','5','6','7','8','9','10','12','13','14','15','18','19','20','21','22','23','24','25','26','27','28','29','30','32'};
subj_nb_list = {'25'};
onecond = false;

% main loop across subjects
for isubj = 1:length(subj_nb_list)
    subject_number = subj_nb_list{isubj};
    % Setup and load data
    if str2double(subject_number) < 10
        SPM_folder = [spm_dir 'results_subj0',subject_number];
        Scan_folder = [scan_dir 'SOUNDFMRI_SUJET0', subject_number, '_ACTIVE/'];
    else
        SPM_folder = [spm_dir 'results_subj',subject_number];
        Scan_folder = [scan_dir 'SOUNDFMRI_SUJET', subject_number, '_ACTIVE/'];
    end
    tr          = 1.66;
    stimdur     = 0.2;

    %outputdir = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/smoothed_indivGLMsingle_modelC/active/subj',subject_number];
        outputdir = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelD/active/V1/subj',subject_number];

    if ~exist(outputdir)
        mkdir(outputdir);
    end

    % Load design matrix
    load(sprintf('%s/SPM.mat',SPM_folder));

    % Modify it a little bit first (just keep snr1 to 5 and regroup both vowels together)
    cond = {};
    for i=1:length(SPM.Sess) % for each run
        if onecond == false
            for j = 1:5 % for each condition
                cond{i,j} = [SPM.Sess(i).U(j).ons ; SPM.Sess(i).U(j+5).ons];
                cond{i,j} = sort(cond{i,j});
            end
        else
            j=cd; % function of condition we want
            cond{i} = [SPM.Sess(i).U(j).ons ; SPM.Sess(i).U(j+5).ons];
            cond{i} = sort(cond{i});
        end
    end
    clear i ; clear j;
    % Adapt design matrices to GLMsingle (time = scans)

    %% subj25A problem +++
    % a priori its trial 150 the last of the 3rd run that's outside
    % scanning --> should be removed as well as the corresponding label
    % (snr5) BUT it's not and 'stimorder' is shifted compared to
    % trials.snr_num -- re-do and fix +++
    %%

    %%% Maybe create different design matrices: one for the on-off model (just
    %%% snr 5 +/- 4, and one with all snrs
    % only if one condition alone
    if onecond == true
        % Adapt design matrices to GLMsingle (time = scans)
        design = cell(1,length(SPM.Sess));
        for i=1:length(SPM.Sess)  % for each run
            %ncond = length(SPM.Sess(i).U);    % number of conditions
            nvol = length(SPM.Sess(i).row);   % number of volumes
            design{i} = zeros(nvol,1);
            design{i}(round(cond{i}/tr)+1) = 1;  % set all of the onsets
        end
    else
        design = cell(1,length(SPM.Sess));%crotte = [];
        clear temp;
        for i=1:length(SPM.Sess)  % for each run
            nvol = length(SPM.Sess(i).row);
            design{i} = zeros(nvol,5);
            if regexp('25',subject_number) == 1 % special case: last onset of run2 (3rd one) is outside scanning with rounding
                for j=1:5
                    temp = (round(cond{i,j}/tr)+1)';
                    if max(temp) > nvol
                        for k = 1:length(temp)
                            if temp(k) > nvol
                                temp(k) = nvol;
                            end
                        end
                    end
                    design{i}(temp,j) = 1;
                end
           %elseif regexp('32',subject_number) == 1 % special case: 3 last trials of run7 (8th one) were outside scanning during acquisition
                % ACTUALLY NO THIS CASE WILL BE DEALT WITH FOR BETA
                % EXTRACTION RESHAPE
            else
                for j=1:5 %4   % for each condition
                    design{i}(round(cond{i,j}/tr)+1,j) = 1;
                end
            end
        end
    end

    % Check design matrices
    figure(1);clf
    for d = 1:length(design)
        subplot(3,3,d)
        imagesc(design{d}); colormap gray; drawnow
        xlabel('Conditions')
        ylabel('TRs')
        title(sprintf('Design matrix for run%i',d))
    end
    numruns = length(design);


    % Load fMRI data
    data = cell(1,length(SPM.Sess));
    datafiles = dir(sprintf('%s/s8wts*.nii',Scan_folder));
    spmInfoScan = {};
    for i=1:length(datafiles)
        tmp = niftiread(sprintf('%s%s',Scan_folder,datafiles(i).name));
        data{i} = tmp;
        % also use spm to extract inversion matrices (to later put ROI
        % coordinates into the right space)
        spmInfoScan{i} = spm_vol(sprintf('%s%s',Scan_folder,datafiles(i).name));
        %Y = spm_read_vols(V);
    end

    % Just checking
    for x = 1:numruns
        disp(size(data{1,x}));
    end


    % Call main function
    % Adapt the options here ++
    opt = struct('wantmemoryoutputs',[1 1 1 1], 'wantpercentbold',0);
    if ~isfield(opt,'wantglmdenoise') || isempty(opt.wantglmdenoise)
        opt.wantglmdenoise = 1;
    end
    opt.wantfracridge = 0;
    opt.firdelay = 15; %default = 30
    active = true;
    if ~isfield(opt,'extraregressors') || isempty(opt.extraregressors)
        opt.extraregressors = cell(1,numruns);
        for irun = 1:numruns
            if str2double(subject_number) < 10
                opt.extraregressors{1,irun} = load(sprintf([reg_dir 'SOUNDFMRI_SUJET0%s_ACTIVE/multiple_regressors_run%i.txt'], subject_number, irun-1));
            else
                opt.extraregressors{1,irun} = load(sprintf([reg_dir 'SOUNDFMRI_SUJET%s_ACTIVE/multiple_regressors_run%i.txt'], subject_number, irun-1));
            end
        end
    end
    [results] = GLMestimatesingletrial(design,data,stimdur,tr,[outputdir '/GLMsingle'],opt);
end
