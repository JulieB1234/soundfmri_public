%% Julie BOYER 2024 -- SOUNDFMRI analysis -- for trial by trial activity analysis using GLMSingle (Prince et al)

% Start fresh
clear
clc
close all


% Load SPM, etc.
addpath('/Applications/spm12/');
spm('Defaults', 'fMRI');
spm_jobman('initcfg');
addpath(genpath('/Users/julieboyer/Desktop/GLMsingle/matlab'));
addpath("/Users/julieboyer/Desktop/GLMsingle/");

spm_dir = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/PASSIVE/Results/Results_indiv_CLASSIC/';
scan_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Scans/';
reg_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/PASSIVE/Multiple_regressors/';

%subj_nb_list = {'2','3','4','5','6','7','8','9','10','12','13','14','15','18','19','20','21','22','23','24','25','26','27','28','29','30','32'};
%subj_nb_list = {'20','21','22','23','24','25','26','27','28','29','30','32'};
subj_nb_list = {'5'};

for isubj = 1:length(subj_nb_list)
    subject_number = subj_nb_list{isubj};
    % Setup and load data
    if str2double(subject_number) < 10
        SPM_folder = [spm_dir 'results_subj0',subject_number];
        Scan_folder = [scan_dir 'SOUNDFMRI_SUJET0', subject_number, '_PASSIVE/'];
    else
        SPM_folder = [spm_dir 'results_subj',subject_number];
        Scan_folder = [scan_dir 'SOUNDFMRI_SUJET', subject_number, '_PASSIVE/'];
    end
    tr          = 1.66;
    stimdur     = 0.2;


    outputdir = ['/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelD/passive/V1/subj',subject_number];
    if ~exist(outputdir)
        mkdir(outputdir);
    end
    % Load design matrix
    load(sprintf('%s/SPM.mat',SPM_folder));

    % Modify it a little bit first (just keep snr1 to 5 and regroup both vowels
    % together)
    cond = {};
    for i=1:length(SPM.Sess) % for each run
        for j = 1:5 % for each condition
            cond{i,j} = [SPM.Sess(i).U(j).ons ; SPM.Sess(i).U(j+5).ons];
            cond{i,j} = sort(cond{i,j});
        end
    end

    clear i ; clear j;

    %% Adapt design matrices to GLMsingle (time = scans)
    design = cell(1,length(SPM.Sess));
    for i=1:length(SPM.Sess)  % for each run
        %ncond = length(SPM.Sess(i).U);    % number of conditions
        nvol = length(SPM.Sess(i).row);   % number of volumes
        design{i} = zeros(nvol,5);
        for j=1:5   % for each condition
            design{i}(round(cond{i,j}/tr)+1,j) = 1;  % set all of the onsets
        end
    end

    % ONLY FOR S25
    if str2double(subject_number) == 25
        temp = {};
        for g = 1:8
            temp{g} = design{g};
        end
        design = temp;
    end

    % Check design matrices
    figure(1);clf
    for d = 1:length(design)
        subplot(3,4,d)
        imagesc(design{d}); colormap gray; drawnow
        xlabel('Conditions')
        ylabel('TRs')
        title(sprintf('Design matrix for run%i',d))
    end
    numruns = length(design);

    %% Load fMRI data - with a correction of the order due to the presence of a 10th run...
    data = cell(1,length(SPM.Sess));
    %datafiles = dir(sprintf('%s/wts*.nii',Scan_folder));
    datafiles = dir(sprintf('%s/s8wts*.nii',Scan_folder));


    % Extract the run numbers from the filenames
    run_numbers = zeros(length(datafiles), 1);
    for i = 1:length(datafiles)
        tokens = regexp(datafiles(i).name, 'run(\d+)', 'tokens');
        run_numbers(i) = str2double(tokens{1}{1});
    end

    % Sort the run numbers and get the sorting indices
    [~, sorted_indices] = sort(run_numbers);
    spmInfoScan = {};
    for i=1:length(datafiles)
        tmp = niftiread(sprintf('%s%s',Scan_folder,datafiles(i).name));
        data{i} = tmp;
        % also use spm to extract inversion matrices (to later put ROI
        % coordinates into the right space)
        spmInfoScan{i} = spm_vol(sprintf('%s%s',Scan_folder,datafiles(i).name));
        %Y = spm_read_vols(V);
    end

    data = data(sorted_indices);

    % Just checking
    for x = 1:numruns
        disp(size(data{1,x}));
    end
    active = false;

    %% Call main function or load results if already processed

    % Adapt the options here ++
    opt = struct('wantmemoryoutputs',[1 1 1 1], 'wantpercentbold', 1);
    if ~isfield(opt,'wantglmdenoise') || isempty(opt.wantglmdenoise)
        opt.wantglmdenoise = 1;
    end
    if ~isfield(opt,'wantfracridge') || isempty(opt.wantfracridge)
        opt.wantfracridge = 1; % NO FRACDRIGE BOUHHHHHHH or yes for decoding lol
    end
    if ~isfield(opt,'extraregressors') || isempty(opt.extraregressors)
        opt.extraregressors = cell(1,numruns);

        for irun = 1:numruns
            if str2double(subject_number) < 10
                opt.extraregressors{1,irun} = load(sprintf([reg_dir 'SOUNDFMRI_SUJET0%s_PASSIVE/multiple_regressors_run%i.txt'], subject_number, irun-1));
            else
                opt.extraregressors{1,irun} = load(sprintf([reg_dir 'SOUNDFMRI_SUJET%s_PASSIVE/multiple_regressors_run%i.txt'], subject_number, irun-1));
            end
        end

    end
    [results] = GLMestimatesingletrial(design,data,stimdur,tr,[outputdir '/GLMsingle'],opt);

end
