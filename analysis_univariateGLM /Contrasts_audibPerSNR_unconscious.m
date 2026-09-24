function Contrasts_audibPerSNR_unconscious(~)

%% with a little help from chatGPT to account for all possible missing regressors combinations

%% update december 2025
% we want the contrast stim present not heard vs no stim
% so audib 1 x snr2-3-4-5 VS snr1
% also !! respScreen 1 and 2 regressors !! so 2 more non interest
% regressors than in classical pipeline not sure why - but since timing
% files are already made i'll leave it like this
% so same base contrast

% base_contrast = [-1 -1 -1 -1 -1 ... % 5 first = audib1 (and 5 snrs) for vowel A
%                  1 1 1 1 1 ... % audib2 for vowel A
%                  1 1 1 1 1 ... % audib3
%                  1 1 1 1 1 ... % audib4
%                  -1 -1 -1 -1 -1 ... % audib1 for vowel E
%                  1 1 1 1 1 ... % audib2 for vowel E
%                  1 1 1 1 1 ... % audib3
%                  1 1 1 1 1 ... % audib4
%                  0 0 0 0 0];

base_contrast_list = {};

% just 'stim not heard' alone
base_contrast_list{1} = [0 1 1 1 1 ... % audib1 (and 5 snrs) for vowel A
                  0 0 0 0 0 ... % audib2 for vowel A
                  0 0 0 0 0 ... % audib3
                  0 0 0 0 0 ... % audib4
                  0 1 1 1 1 ... % audib1 for vowel E
                  0 0 0 0 0 ... % audib2 for vowel E
                  0 0 0 0 0 ... % audib3
                  0 0 0 0 0 ... % audib4
                  0 0 0 0 0]; % non interest regressors

% stim not heard vs no stim -- TOO LONG (16 regressors = 65535 potential
% contrasts)
% base_contrast_list{2} = [-1 1 1 1 1 ... % audib1 (and 5 snrs) for vowel A
%                   -1 0 0 0 0 ... % audib2 for vowel A
%                   -1 0 0 0 0 ... % audib3
%                   -1 0 0 0 0 ... % audib4
%                   -1 1 1 1 1 ... % audib1 for vowel E
%                   -1 0 0 0 0 ... % audib2 for vowel E
%                   -1 0 0 0 0 ... % audib3
%                   -1 0 0 0 0 ... % audib4
%                   0 0 0 0 0]; % non interest regressors

% no stim alone
base_contrast_list{2} = [-1 0 0 0 0 ... % audib1 (and 5 snrs) for vowel A
                  -1 0 0 0 0 ... % audib2 for vowel A
                  -1 0 0 0 0 ... % audib3
                  -1 0 0 0 0 ... % audib4
                  -1 0 0 0 0 ... % audib1 for vowel E
                  -1 0 0 0 0 ... % audib2 for vowel E
                  -1 0 0 0 0 ... % audib3
                  -1 0 0 0 0 ... % audib4
                  0 0 0 0 0]; % non interest regressors

%contrast_names = {'SnotH','SnotH_noS','noS'};
contrast_names = {'SnotH','noS'};

% Define here the base contrast as a function of contrast we want
%base_contrast = base_contrast2;

for icon = 1:numel(base_contrast_list)
    base_contrast = base_contrast_list{icon};

    % Number of regressors
    regressors_of_interest_indices = find(base_contrast);
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
        contrast_name = contrast_names{icon};
        for j = 1:num_regressors_of_interest
            if missing_pattern(j) == 1
                %contrast_name = [contrast_name 'Miss' num2str(j)];
                contrast_name = [contrast_name 'M' num2str(regressors_of_interest_indices(j))];
            end
        end
        if all(missing_pattern == 0)
            contrast_name = [contrast_name 'noM'];
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

        % Save contrasts to .mat files
        list = fieldnames(contrasts);
        %filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Audib/Contrasts';
        %filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIBperSNR/Contrasts';
        filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIB_UNC/Contrasts';
        for c = 1:length(list)
            contrast_data = contrasts.(list{c});
            save(fullfile(filename, [list{c} '.mat']), 'contrast_data');
        end
    end
    % Also save the indices of the regressors of interest to get them in the
    % next function...
    save(['/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/ACTIVE_AUDIB_UNC/Contrasts/RegIndices_' contrast_names{icon} '.mat'],'regressors_of_interest_indices');

end

end
