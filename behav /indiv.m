%% 2024 updated script for behavioural data analysis from Soundfmri, active sessions
% Julie Boyer, juliechezboyer@wanadoo.fr

% updated 14.11.25

%% Setup

clear; clc;
close all;

%dossA = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/';
%dossP = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/';
dossA = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/1_16/';
dossP = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/1_16/';
targetDirectory = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/indiv_figures_paper2026/';
fileA = dir([dossA 'Subject_*.mat']);
fileP = dir([dossP 'Subject_*.mat']);

% Plots setup
%X = [-20, -11.5, -9.5, -7.5, -3]; % for plots (X axis)
size = 10; % size for axes' titles
markersize = 20; % size for the dots representing the mean data
fontsize = 20; % size for axes' labels
linewidth = 2.5;

color1 = [56, 126, 246] / 255; % blue
color2 = [225, 49, 154] / 255; % pink
color3 = [50, 205, 50] / 255; % green
color4 = [255, 255, 31] / 255; % yellow

black = [0, 0, 0];


% Set up the number of SNR
snr_nb = 5;

file = fileA;
% Prepare data matrices
mean_perf_A = nan(length(file), snr_nb);
mean_audib_A = nan(length(file), snr_nb);
std_audib_A = nan(length(file), snr_nb);
std_audib_base_A = nan(length(file), snr_nb);

mean_perf_E = nan(length(file), snr_nb);
mean_audib_E = nan(length(file), snr_nb);
std_audib_E = nan(length(file), snr_nb);
std_audib_base_E = nan(length(file), snr_nb);

file = fileP;
MW_sound = nan(length(file), snr_nb); % resp 1
MW_envt = nan(length(file), snr_nb); % resp 2
MW_thoughts = nan(length(file), snr_nb); % resp 3
MW_nothing = nan(length(file), snr_nb); % resp 4

clear file; 



for idir = 1:length(fileA) % loop over subjects available
    % ACTIVE
    clear trials;
    load([dossA fileA(idir).name]);
    name = ['subj_' regexp(fileA(idir).name, '\d+', 'match','once')];
    subjectNumber = regexp(name, '\d+', 'match');
    subj_nb = str2double(subjectNumber);
    for snrnum = 1:snr_nb

        %% Compute individual mean & std of performance and audibility
        % mean performance for A and E
        mean_perf_A(idir,snrnum) = nnz(trials.correct == 1 & trials.snr_num ...
            == snrnum & trials.stimulus_num == 1)/nnz(trials.snr_num == snrnum ...
            & trials.stimulus_num == 1)*100;
        mean_perf_E(idir,snrnum) = nnz(trials.correct == 1 & trials.snr_num ...
            == snrnum & trials.stimulus_num == 2)/nnz(trials.snr_num == snrnum ...
            & trials.stimulus_num == 2)*100;
        % performance std for A and E
        std_perf_A(idir,snrnum) = std(trials.correct(trials.snr_num == snrnum ...
            & trials.stimulus_num == 1), 'omitnan');
        std_perf_E(idir,snrnum) = std(trials.correct(trials.snr_num == snrnum ...
            & trials.stimulus_num == 2), 'omitnan');
        % mean audibility for A and E
        mean_audib_A(idir,snrnum) = mean(trials.audib(trials.snr_num == ...
            snrnum & trials.stimulus_num == 1), 'omitnan');
        mean_audib_E(idir,snrnum) = mean(trials.audib(trials.snr_num == ...
            snrnum & trials.stimulus_num == 2), 'omitnan');
        % audibility std for A and E
        std_audib_A(idir,snrnum) = std(trials.audib(trials.snr_num == snrnum ...
            & trials.stimulus_num == 1), 'omitnan');
        std_audib_E(idir,snrnum) = std(trials.audib(trials.snr_num == snrnum ...
            & trials.stimulus_num == 2), 'omitnan');
    end

    % PASSIVE
    clear trials;
    load([dossP fileP(idir).name]);
    name = ['subj_' regexp(fileP(idir).name, '\d+', 'match','once')];
    subjectNumber = regexp(name, '\d+', 'match');
    check = str2double(subjectNumber);

    if ~isequal(check,subj_nb)
        error('not the same subject A/P');
    end
    %subj_nb = str2double(subjectNumber);

    for snrnum = 1:snr_nb
        %% Proportion of response types to MW probes, as a function of SNR
        % - 'S' = answer 1 = the sound
        % - 'E' = answer 2 = environment
        % - 'R' = answer 3 = thoughts
        % - 'P' = answer 4 = nothing / falling asleep
        MWresponses = {'The sound', 'The environment', 'My own thoughts', 'Nothing, I am falling asleep'};
        for iresp = 1:length(MWresponses)
            MW_sound(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                1 & trials.snr_num == snrnum) / nnz(trials.question_num == 3 & trials.snr_num == snrnum)*100;
            MW_envt(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                2 & trials.snr_num == snrnum) / nnz(trials.question_num == 3 & trials.snr_num == snrnum)*100;
            MW_thoughts(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                3 & trials.snr_num == snrnum) / nnz(trials.question_num == 3 & trials.snr_num == snrnum)*100;
            MW_nothing(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                4 & trials.snr_num == snrnum) / nnz(trials.question_num == 3 & trials.snr_num == snrnum)*100;
        end
    end

    f = figure('Position',[84 1066 1512 814],'PaperPositionMode','auto','PaperOrientation','landscape');
    % Active Perf
    X = [-20 -11.5 -9.5 -7.5 -3];
    subplot(2,2,1);
    hold on;

    Y1 = mean_perf_A(idir, :); % mean performance for condition A, for given subject
    Y2 = mean_perf_E(idir, :); % mean performance for condition E, for given subject

    % Plot individual performances of each subject
    plot(X, Y1, 'k-','LineWidth',linewidth, 'color', color1);
    plot(X, Y2, 'k-','LineWidth',linewidth, 'color', color2);
    plot(X, Y1, 'k.','Color',black,'MarkerSize',markersize);
    plot(X, Y2, 'k.','Color',black,'MarkerSize',markersize);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Averaged identification performance (%)', 'FontSize',size);
    plot([-25 0],[75 75],'--', 'Color',black);
    %legend('A', 'E','Location','best');
    set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'No sound'; '-11.5'; '-9.5'; '-7.5'; '-3'});
    axis([-21 0 ylim]);

    hold off;
    title('Active - Identification Performance for A and E');

    % Active Audib avg
    subplot(2,2,2);
    hold on;

    Y1 = mean_audib_A(idir, :);
    Y2 = mean_audib_E(idir, :);

    % Plot individual audibility of each subject
    plot(X, Y1, 'k-','LineWidth',linewidth, 'color', color1);
    plot(X, Y2, 'k-','LineWidth',linewidth, 'color', color2);
    plot(X, Y1, 'k.','Color',black,'MarkerSize',markersize);
    plot(X, Y2, 'k.','Color',black,'MarkerSize',markersize);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Averaged audibility (a.u.)', 'FontSize',size);
    %legend('A', 'E');
    set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'No sound'; '-11.5'; '-9.5'; '-7.5'; '-3'});
    axis([-21 0 ylim]);

    hold off;
    title('Active - Average Audibility for A and E');

    % Active Audib var
    subplot(2,2,3);
    hold on;

    Y1 = std_audib_A(idir, :);
    Y2 = std_audib_E(idir, :);

    % Plot individual audibility of each subject
    plot(X, Y1, 'k-','LineWidth',linewidth, 'color', color1);
    plot(X, Y2, 'k-','LineWidth',linewidth, 'color', color2);
    plot(X, Y1, 'k.','Color',black,'MarkerSize',markersize);
    plot(X, Y2, 'k.','Color',black,'MarkerSize',markersize);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Audibility varibility (a.u.)', 'FontSize',size);
    %legend('A', 'E','Location','best');
    set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'No sound'; '-11.5'; '-9.5'; '-7.5'; '-3'});
    axis([-21 0 ylim]);

    hold off;
    title('Active - Inter-trial Audibility Variability for A and E');

    % Passive
    X = [-20, -10, -7.5, -5, -1];
    subplot(2,2,4);
    hold on; 


    Y1 = MW_sound(idir, :);
    Y2 = MW_envt(idir, :);
    Y3 = MW_thoughts(idir,:);
    Y4 = MW_nothing(idir,:);

    plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color1);
    plot(X,mean(Y2(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color2);
    plot(X,mean(Y3(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color3);
    plot(X,mean(Y4(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color4);

    plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y3(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y4(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Proportion of response type (%)', 'FontSize',size);
    %legend('Sound', 'Environment', 'Thoughts', 'Nothing','Location','best','Fontsize',50);
    set(gca,'FontSize',fontsize,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
    axis([-21 0 ylim]);

    hold off; 
    title('Passive - Proportion of Mind Wandering Responses');

    sgtitle(['Subject ' num2str(subj_nb)],'Fontsize',40);
    

    % save .png
    saveas(gcf,[targetDirectory name '.png']);

end


%%
linewidth = 7;
    figure; hold on; 
    Y1 = MW_sound(idir, :);
    Y2 = MW_envt(idir, :);
    Y3 = MW_thoughts(idir,:);
    Y4 = MW_nothing(idir,:);

    plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color1);
    plot(X,mean(Y2(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color2);
    plot(X,mean(Y3(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color3);
    plot(X,mean(Y4(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', color4);

    plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y3(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);
    plot(X,mean(Y4(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',20);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Proportion of response type (%)', 'FontSize',size);
    legend('Sound', 'Environment', 'Thoughts', 'Nothing','Location','best','Fontsize',30);
    set(gca,'FontSize',fontsize,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'No sound'; '-10'; '-7.5'; '-5'; '-1'});
    axis([-21 0 ylim]);
%%

    figure; hold on; 
    Y1 = std_audib_A(idir, :);
    Y2 = std_audib_E(idir, :);

    % Plot individual audibility of each subject
    plot(X, Y1, 'k-','LineWidth',linewidth, 'color', color1);
    plot(X, Y2, 'k-','LineWidth',linewidth, 'color', color2);
    plot(X, Y1, 'k.','Color',black,'MarkerSize',markersize);
    plot(X, Y2, 'k.','Color',black,'MarkerSize',markersize);

    % Add legend, etc.
    xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',size);
    ylabel('Audibility varibility (a.u.)', 'FontSize',size);
    legend('A', 'E','Location','best','Fontsize',30);
%%
