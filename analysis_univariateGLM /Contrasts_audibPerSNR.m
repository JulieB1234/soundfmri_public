function Contrasts_audibPerSNR(~)

%% with a little help from chatGPT to account for all possible missing regressors combinations
% Define the base contrast
%base_contrast = [-1 1 1 1 -1 1 1 1 0 0 0 0 0];
% base_contrast = [-1 -1 -1 -1 -1 ... % 5 first = audib1 (and 5 snrs) for vowel A
%                  1 1 1 1 1 ... % audib2 for vowel A
%                  1 1 1 1 1 ... % audib3
%                  1 1 1 1 1 ... % audib4
%                  -1 -1 -1 -1 -1 ... % audib1 for vowel E
%                  1 1 1 1 1 ... % audib2 for vowel E
%                  1 1 1 1 1 ... % audib3
%                  1 1 1 1 1 ... % audib4
%                  0 0 0 0 0];
base_contrastSNR3 = [0 0 -1 0 0 ... % 5 first = audib1 (and 5 snrs) for vowel A
                 0 0 1 0 0 ... % audib2 for vowel A
                 0 0 1 0 0 ... % audib3
                 0 0 1 0 0 ... % audib4
                 0 0 -1 0 0 ... % audib1 for vowel E
                 0 0 1 0 0 ... % audib2 for vowel E
                 0 0 1 0 0 ... % audib3
                 0 0 1 0 0 ... % audib4
                 0 0 0 0 0];
base_contrastSNR4 = [0 0 0 -1 0 ... % 5 first = audib1 (and 5 snrs) for vowel A
                 0 0 0 1 0 ... % audib2 for vowel A
                 0 0 0 1 0 ... % audib3
                 0 0 0 1 0 ... % audib4
                 0 0 0 -1 0 ... % audib1 for vowel E
                 0 0 0 1 0 ... % audib2 for vowel E
                 0 0 0 1 0 ... % audib3
                 0 0 0 1 0 ... % audib4
                 0 0 0 0 0];
base_contrastSNR3_A = [0 0 -1 0 0 ... % 5 first = audib1 (and 5 snrs) for vowel A
                 0 0 1 0 0 ... % audib2 for vowel A
                 0 0 1 0 0 ... % audib3
                 0 0 1 0 0 ... % audib4
                 0 0 0 0 0 ... % audib1 for vowel E
                 0 0 0 0 0 ... % audib2 for vowel E
                 0 0 0 0 0 ... % audib3
                 0 0 0 0 0 ... % audib4
                 0 0 0 0 0];
base_contrastSNR3A_SNR4E = [0 0 -1 0 0 ... % 5 first = audib1 (and 5 snrs) for vowel A
                 0 0 1 0 0 ... % audib2 for vowel A
                 0 0 1 0 0 ... % audib3
                 0 0 1 0 0 ... % audib4
                 0 0 0 -1 0 ... % audib1 for vowel E
                 0 0 0 1 0 ... % audib2 for vowel E
                 0 0 0 1 0 ... % audib3
                 0 0 0 1 0 ... % audib4
                 0 0 0 0 0];
base_contrastSNR4A_SNR3E = [0 0 0 -1 0 ... % 5 first = audib1 (and 5 snrs) for vowel A
                 0 0 0 1 0 ... % audib2 for vowel A
                 0 0 0 1 0 ... % audib3
                 0 0 0 1 0 ... % audib4
                 0 0 -1 0 0 ... % audib1 for vowel E
                 0 0 1 0 0 ... % audib2 for vowel E
                 0 0 1 0 0 ... % audib3
                 0 0 1 0 0 ... % audib4
                 0 0 0 0 0];

%etc.

%% Define here the bazse contrast as a function of contrast we want
base_contrast = base_contrastSNR3;

% Number of regressors
regressors_of_interest_indices = find(base_contrast); %[3, 8, 13, 18, 23, 28, 33, 38] example
num_regressors_of_interest = length(regressors_of_interest_indices);


% Initialize contrasts structure
contrasts = struct();
%%
% Generate all possible combinations of missing regressors
for i = 0:(2^num_regressors_of_interest - 1)
    % Convert the index to binary to get missing regressor pattern
    missing_pattern = bitget(i, num_regressors_of_interest:-1:1); %num_regressors:-1:1 generates a sequence
    % starting at num_regressors, decrementing by 1, and ending at 1.


    % Create contrast name based on missing pattern
    contrast_name = 'HnotH_';
    for j = 1:num_regressors_of_interest
        if missing_pattern(j) == 1
            %contrast_name = [contrast_name 'Miss' num2str(j)];
            contrast_name = [contrast_name 'Miss' num2str(regressors_of_interest_indices(j))];
        end
    end
    if all(missing_pattern == 0)
        contrast_name = [contrast_name 'noMiss'];
    end

    % Generate the contrast vector based on missing pattern
    contrast_vector = base_contrast;
    for j = 1:num_regressors_of_interest
        if missing_pattern(j) == 1
            %contrast_vector(j) = 0;
            contrast_vector(regressors_of_interest_indices(j)) = 0;
        end
    end

    % Save contrast in the structure
    contrasts.(contrast_name) = contrast_vector;
end
%%

% Save contrasts to .mat files
list = fieldnames(contrasts);
%filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Audib/Contrasts';
filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts';
for c = 1:length(list)
    contrast_data = contrasts.(list{c});
    save(fullfile(filename, [list{c} '.mat']), 'contrast_data');
end

% Also save the indices of the regressors of interest to get them in the
% next function...
save('/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts/RegIndices.mat','regressors_of_interest_indices');
end
