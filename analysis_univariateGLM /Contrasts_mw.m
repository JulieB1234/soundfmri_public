function Contrasts_mw(~)

%% Passive condition ---- for Mindwandering-based contrasts
% Here are our regressors

% 'mw_answer_sound_vowel1' - 1
% 'mw_answer_other_vowel1' - 2
% 'mw_answer_sound_vowel2' - 3
% 'mw_answer_other_vowel2' - 4
% 'rt_question_vowel1'     - 5
% 'mw_question_vowel1'     - 6
% 'quiz_question_vowel1'   - 7
% 'none_question_vowel1'   - 8
% 'rt_question_vowel2'     - 9
% 'mw_question_vowel2'     - 10
% 'quiz_question_vowel2'   - 11
% 'none_question_vowel2'   - 12
% 'FixPoint'               - 13
% 'Keypress'               - 14
% Regressors of interest here will be: reg1, reg2, reg3, reg4 (n = 4) (2
% response types x 2 vowels)

%% with a little help from chatGPT to account for all possible missing regressors combinations
% Define the base contrast
base_contrast = [1 -1 1 -1 0 0 0 0 0 0 0 0 0 0];

% Number of regressors
num_regressors_of_interest = 4;

% Initialize contrasts structure
contrasts = struct();
%% CHANGES HERE -----------------------------------------------------------
% Generate all possible combinations of missing regressors
for i = 0:(2^num_regressors_of_interest - 1) 
    % Convert the index to binary to get missing regressor pattern
    missing_pattern = bitget(i, num_regressors_of_interest:-1:1);
    % Create contrast name based on missing pattern
    contrast_name = 'SnotS_'; % sound vs not sound
    for j = 1:num_regressors_of_interest
        if missing_pattern(j) == 1
            contrast_name = [contrast_name 'Miss' num2str(j)];
        end
    end
    if all(missing_pattern == 0)
        contrast_name = [contrast_name 'noMiss'];
    end

    % Generate the contrast vector based on missing pattern
    contrast_vector = base_contrast;
    for j = 1:num_regressors_of_interest
        if missing_pattern(j) == 1
            contrast_vector(j) = 0;
        end
    end

    % Save contrast in the structure
    contrasts.(contrast_name) = contrast_vector;
end

% Save contrasts to .mat files
list = fieldnames(contrasts);
%filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/Pipelines_tests/NEW_REG/Mindwandering/Contrasts';
filename = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/new_scripts_and_tests/PipelinesUniV_Sept24/8mmSmoothing/MW/Contrasts';

for c = 1:length(list)
    contrast_data = contrasts.(list{c});
    save(fullfile(filename, [list{c} '.mat']), 'contrast_data');
end
end
