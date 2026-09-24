%% soundfmri
% october 2025 J Boyer
% goal = extract subjects' single-trial beta estimate, one per trial, in a
% given ROI in .csv file

% update 13/11/25
% we want single trial single voxel data
% + info about trial labels (snr12345) and about trial numbers (1-440 or
% 450)
% for 27 subjects x 2 conditions A/P

% V3 = same but averaged value across RFE voxels

% V4 = decision values (one per trial per subject) -- for now clusters at
% unc p 001
% all cluster
% only audit voxels of cluster
% all but audit voxels of cluster

%% INPUT = decoding single trial values from decoding_get_neural_values.m (.mat file)
%% OUTPUT = .csv file with 1 value per trial (with SNR label) for each subject / condition Active or Passive / ROI A1 or noA1 ==> for python model comparison, etc.

%% Set up
clear; clc; close all;
%subjects = [2 3 4 5 6 7 8 9 10 12 13 14 15 18 19 20 21 22 23 24 26 27 28 29 30 32]; % NO 25
%subjects = [2 3 4 5 6 7 8 10 12 13 14 15 18 19 20 21 23 24 25 26 27 28 30 32];
subjects = [29]; % NO 25

active = false; passive = false;

%output_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/for_thomas_dval_3/';
%output_dir = '/Volumes/jboyer/elefanto/ConsciousnessTeam_Data/SOUNDFMRIxSOUNDMODEL/V5_decisionValues_new/5ROIs_conjunction_dvals/';
output_dir = '/Volumes/jboyer/elefanto/ConsciousnessTeam_Data/SOUNDFMRIxSOUNDMODEL/V6/';

addpath(genpath('/Users/julieboyer/Desktop/GLMsingle/'));
addpath('/Applications/spm12/');
addpath('/Applications/spm12/toolbox/marsbar/');

%conditions = {'active','passive'};
conditions = {'passive'};

%input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR/unc001/';
%input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI/unc001/';
input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/LORO_XSNR_ROI2/unc001/';
%input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/MVPA/withTDT/new_codes/FirstLevel/ROI/snr/old_attempts/new_ROIs_4_conj_CSF/results_xval/';
%input_dir = '/Volumes/DisqueJulie/JulieBoyer2025/SOUNDFMRI 2025/Unsmoothed_indivGLMsingle_modelC/V12_indivClusters_onlyHeschl/';

correction = 'unc001';

roi_list = {'_A1_thr10','_NoA1_thr10'};


%% loop across conditions and subjects to load data
for iroi = 1:numel(roi_list)
    for icond = 1:length(conditions)
        fprintf('\n Condition : %s \n', conditions{icond});
        if strcmp(conditions{icond},'active')
            active = true; passive = false;
        elseif strcmp(conditions{icond},'passive')
            passive = true; active = false;
        end
        for sbj_nb = subjects
            if sbj_nb<10
                sb = ['0' num2str(sbj_nb)];
            else
                sb = num2str(sbj_nb);
            end
            % decision values + true labels + decoding performance (AUC) -- stim (snr 2-5) vs no stim
            if active
                %tmp = [input_dir '/' roi_list{iroi} '/subj' num2str(sbj_nb) '_active'];
                %if isfolder(tmp)
                    %load([tmp '/decoding_out.mat']);
                    %load([tmp '/true_labels.mat']);
                    load([input_dir 'subj' sb '_active' roi_list{iroi} '/decoding_out.mat']);
                    load([input_dir 'subj' sb '_active' roi_list{iroi} '/true_labels.mat']);
                    load([input_dir 'subj' sb '_active' roi_list{iroi} '/res_cfg.mat']);
                    dvals = []; %preds = []; labels = []; 
                    for i = 1:size(decoding_out,2)
                        dvals = [dvals; -decoding_out(i).decision_values];
                    end
                %else
                %    break
                %end
            elseif passive
                %tmp = [input_dir '/' roi_list{iroi} '/subj' num2str(sbj_nb) '_passive'];
                %if isfolder(tmp)
                    %load([tmp '/decoding_out.mat']);
                    %load([tmp '/true_labels.mat']);
                    load([input_dir 'subj' sb '_passive' roi_list{iroi} '/decoding_out.mat']);
                    load([input_dir 'subj' sb '_passive' roi_list{iroi} '/true_labels.mat']);
                    load([input_dir 'subj' sb '_passive' roi_list{iroi} '/res_cfg.mat']);
                dvals = []; %preds = []; labels = [];
                for i = 1:size(decoding_out,2)
                    dvals = [dvals; -decoding_out(i).decision_values];
                end
                % else
                %     break
                % end
            end
            %final_matrix = horzcat(true_labels,dvals);
            chunks = cfg.files.chunk;
            T = table(chunks,true_labels, dvals);
            % save([output_dir 'subj_' num2str(sbj_nb) '_' conditions{icond} '_fullCluster.mat'],"final_matrix");
            % writematrix(final_matrix,[output_dir 'subj_' num2str(sbj_nb) '_' conditions{icond} '_fullCluster.csv'])
            %save([output_dir 'subj_' num2str(sbj_nb) '_' conditions{icond} roi_list{iroi} '.mat'],"final_matrix");
            %writematrix(final_matrix,[output_dir 'subj_' num2str(sbj_nb) '_' conditions{icond} roi_list{iroi} '.csv'])
            writetable(T,[output_dir 'subj_' num2str(sbj_nb) '_' conditions{icond} roi_list{iroi} '.csv']);

        end
    end
end
