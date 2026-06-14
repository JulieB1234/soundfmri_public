%% 2024 updated script for behavioural data analysis from Soundfmri, active sessions
% Julie Boyer, juliechezboyer@wanadoo.fr

% updated 14.11.25

%% Setup

clear; clc;
close all;

doss = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/ACTIVE/';
file = dir([doss 'Subject_*.mat']);

% Plots setup
%X = [-20, -11.5, -9.5, -7.5, -3]; % for plots (X axis)
%size = 10; % size for axes' titles

color1 = [50, 205, 50] / 255; % green
color2 = [225, 49, 154] / 255; % pink
black = [0, 0, 0];

angle= 45;


% Set up the number of SNR
snr_nb = 5;

% Prepare data matrices
mean_perf_A = nan(length(file), snr_nb);
mean_audib_A = nan(length(file), snr_nb);
std_audib_A = nan(length(file), snr_nb);
std_audib_base_A = nan(length(file), snr_nb);

mean_perf_E = nan(length(file), snr_nb);
mean_audib_E = nan(length(file), snr_nb);
std_audib_E = nan(length(file), snr_nb);
std_audib_base_E = nan(length(file), snr_nb);


group = true;  % Set group to true if the user chooses group
indiv = false;
for idir = 1:length(file) % loop over subjects available

    load([doss file(idir).name]);

    name = ['subj_' regexp(file(idir).name, '\d+', 'match','once')];
    subjectNumber = regexp(name, '\d+', 'match');
    subj_nb = str2double(subjectNumber);

    %targetDirectory = "/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/Fig_Sept25/";
    targetDirectory = "/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/figs_nov25/";

    % Loop over all Stim intensities to compute trial data for each stim intensity level

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
    if indiv == true
        % not here
    end
end

targetDirectory = "/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/figs_niv25/";
cd '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/';

doss = '/Users/julieboyer/Desktop/PHD/SOUNDFMRI 2023/DATA_behav/PASSIVE/';
file = dir([doss 'Subject_*.mat']);
V1 = true;

% Plots setup
X = [-20, -11.5, -9.5, -7.5, -3];


color1 = [56, 126, 246] / 255;
color2 = [225, 49, 154] / 255;
color3 = [102, 205, 170] / 255; % Light Sea Green
color4 = [255, 223, 56] / 255;  % Soft Yellow
black = [0, 0, 0];
snr_nb = 5;

% Prepare data matrices for passive session
MW_sound = nan(length(file), snr_nb); % resp 1
MW_envt = nan(length(file), snr_nb); % resp 2
MW_thoughts = nan(length(file), snr_nb); % resp 3
MW_nothing = nan(length(file), snr_nb); % resp 4
% just for letter A
MW_sound_A = nan(length(file), snr_nb); % resp 1
MW_envt_A = nan(length(file), snr_nb); % resp 2
MW_thoughts_A = nan(length(file), snr_nb); % resp 3
MW_nothing_A = nan(length(file), snr_nb); % resp 4
% just for letter E
MW_sound_E = nan(length(file), snr_nb); % resp 1
MW_envt_E = nan(length(file), snr_nb); % resp 2
MW_thoughts_E = nan(length(file), snr_nb); % resp 3
MW_nothing_E = nan(length(file), snr_nb); % resp 4

group = true;  % Set group to true if the user chooses group
indiv = false; % Set indiv to false

for idir = 1:length(file) % loop over subjects available
    load(file(idir).name);
    name = ['subj_' regexp(file(idir).name, '\d+', 'match','once')];
    subjectNumber = regexp(name, '\d+', 'match');
    subj_nb = str2double(subjectNumber);
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
            % just A
            MW_sound_A(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                1 & trials.snr_num == snrnum & trials.stimulus_num == 1) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 1)*100;
            MW_envt_A(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                2 & trials.snr_num == snrnum & trials.stimulus_num == 1) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 1)*100;
            MW_thoughts_A(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                3 & trials.snr_num == snrnum & trials.stimulus_num == 1) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 1)*100;
            MW_nothing_A(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                4 & trials.snr_num == snrnum & trials.stimulus_num == 1) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 1)*100;
            % just E
            MW_sound_E(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                1 & trials.snr_num == snrnum & trials.stimulus_num == 2) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 2)*100;
            MW_envt_E(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                2 & trials.snr_num == snrnum & trials.stimulus_num == 2) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 2)*100;
            MW_thoughts_E(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                3 & trials.snr_num == snrnum & trials.stimulus_num == 2) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 2)*100;
            MW_nothing_E(idir,snrnum) = nnz(trials.question_num == 3 & trials.answer_num == ...
                4 & trials.snr_num == snrnum & trials.stimulus_num == 2) / nnz(trials.question_num ...
                == 3 & trials.snr_num == snrnum & trials.stimulus_num == 2)*100;
        end
    end
    if indiv == true
        % not here
    end
end


%% same but subplot

L.AutoUpdate = 'on';
f = set(gcf,'Position',[-170 1022 1318 1022]);
size_titles = 15; % size for axes' titles
markersize = 35; % size for the dots representing the mean data
fontsize = 32; % size for axes' labels
legendsize = 26;
numsize = 26;


linewidth = 4;
linew_std = 2;

% AVERAGE

%figure;
subplot(2,2,3);
%subplot(1,4,1);
hold on;

% Define Y1 and Y2 --> mean performances
Y1 = mean_perf_A(:, :); Y2 = mean_perf_E(:, :);

% Plot means of subjects' performances
plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', black); 
plot(X,mean(Y2(:,1:snr_nb),1), 'k:', 'LineWidth', linewidth, 'color', black); % ':' or '--'
plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);
plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);
% add STD bars
for i = 1:snr_nb
    plot([X(i) X(i)],[mean(Y1(:,i),1)-std(Y1(:,i))/sqrt(length(file)-1) mean(Y1(:,i),1)+std(Y1(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
    plot([X(i) X(i)],[mean(Y2(:,i),1)-std(Y1(:,i))/sqrt(length(file)-1) mean(Y2(:,i),1)+std(Y2(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
end

% Add legend, etc.
%xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',fontsize);
ylabel({'Averaged performance (%)' ; ' '}, 'FontSize',fontsize);
plot([-25 0],[75 75],'--', 'Color',black);
%legend('A','E', 'Position',[0.91 0.8 0.07 0.08], 'Fontsize',legendsize, 'EdgeColor','white');

%set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'no sound'; 'level 1'; 'level 2'; 'level 3'; 'level 4'});
set(gca,'FontSize',numsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'N'; '-11.5'; '-9.5'; '-7.5'; '-3'});
set(gca,'FontSize',numsize,'YTick',0:20:100);
axis([-21 0 ylim]);

title({'Identification performance (%)';' '},'FontSize',fontsize);
xtickangle(angle)

subplot(2,2,1);
%subplot(1,4,2);
hold on;

% Define Y1 and Y2 --> mean audibilities
Y1 = mean_audib_A(:, :);
Y2 = mean_audib_E(:, :);

% Plot means of subjects' audib
plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', black);
plot(X,mean(Y2(:,1:snr_nb),1), 'k:', 'LineWidth', linewidth, 'color', black);
plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);
plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);

% add STD bars
for i = 1:snr_nb
    plot([X(i) X(i)],[mean(Y1(:,i),1)-std(Y1(:,i))/sqrt(length(file)-1) mean(Y1(:,i),1)+std(Y1(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
    plot([X(i) X(i)],[mean(Y2(:,i),1)-std(Y2(:,i))/sqrt(length(file)-1) mean(Y2(:,i),1)+std(Y2(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
end

% Add legend, etc.
%xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',fontsize);
legend('A','E','Location','northwest','Fontsize',legendsize, 'EdgeColor','white');
ylabel('Averaged audibility (a.u.)', 'FontSize',fontsize);
%legend('A','E','Location','northwest');
%set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'no sound'; 'level 1'; 'level 2'; 'level 3'; 'level 4'});
set(gca,'FontSize',numsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'N'; '-11.5'; '-9.5'; '-7.5'; '-3'});
set(gca,'FontSize',numsize,'YTick',0:1:4);
%ylabel({'Summary statistics'}, 'FontSize', legendsize);
xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',legendsize);
axis([-21 0 ylim]);
xtickangle(angle)

title({'Mean audibility',' '},'FontSize',fontsize);


subplot(2,2,2);
%subplot(1,4,3);
hold on;

% Define Y1 and Y2 --> variability of audibilities
Y1 = std_audib_A(:, :);
Y2 = std_audib_E(:, :);

% Plot means of subjects' audibility variability
plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', black);
plot(X,mean(Y2(:,1:snr_nb),1), 'k:', 'LineWidth', linewidth, 'color', black);
plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);
plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',black,'MarkerSize',markersize);

% add STD bars
for i = 1:snr_nb
    plot([X(i) X(i)],[mean(Y1(:,i),1)-std(Y1(:,i))/sqrt(length(file)-1) mean(Y1(:,i),1)+std(Y1(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
    plot([X(i) X(i)],[mean(Y2(:,i),1)-std(Y2(:,i))/sqrt(length(file)-1) mean(Y2(:,i),1)+std(Y2(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std);
end

% Add legend, etc.
%xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',fontsize);
ylabel('Audibility varibility (a.u.)', 'FontSize',fontsize);
%legend('A', 'E','Location','northwest');
%set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'no sound'; 'level 1'; 'level 2'; 'level 3'; 'level 4'});
set(gca,'FontSize',numsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'N'; '-11.5'; '-9.5'; '-7.5'; '-3'})
set(gca,'FontSize',numsize,'YTick',0:0.2:1);
axis([-21 0 ylim]);
xtickangle(angle);

title({'Audibility variability',' '},'FontSize',fontsize);


subplot(2,2,4);
%subplot(1,4,4);
hold on;

% mind wandering
X = [-20, -10, -7.5, -5, -1]; 
%mw_colors = colormap(cool(4)); % full = 256
mw_colors = [58 34 235; 255 172 46; 181 22 22; 0 186 123]/255;

% Define Ys --> means
Y1 = MW_sound(:, :);
Y2 = MW_envt(:, :);
Y3 = MW_thoughts(:,:);
Y4 = MW_nothing(:,:);
% Plot means of subjects' performances
plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', mw_colors(1,:));
plot(X,mean(Y2(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', mw_colors(2,:));
plot(X,mean(Y3(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', mw_colors(3,:));
plot(X,mean(Y4(:,1:snr_nb),1), 'k-', 'LineWidth', linewidth, 'color', mw_colors(4,:));
% plot(X,mean(Y1(:,1:snr_nb),1), 'k-', 'LineWidth', 4, 'color', black);
% plot(X,mean(Y3(:,1:snr_nb),1), 'k-.', 'LineWidth', 4, 'color', black);
% plot(X,mean(Y4(:,1:snr_nb),1), 'k:', 'LineWidth', 4, 'color', black);
% plot(X,mean(Y2(:,1:snr_nb),1), 'k--', 'LineWidth', 4, 'color', black);

plot(X,mean(Y1(:,1:snr_nb),1), 'k.','Color',mw_colors(1,:),'MarkerSize',markersize);
plot(X,mean(Y2(:,1:snr_nb),1), 'k.','Color',mw_colors(2,:),'MarkerSize',markersize);
plot(X,mean(Y3(:,1:snr_nb),1), 'k.','Color',mw_colors(3,:),'MarkerSize',markersize);
plot(X,mean(Y4(:,1:snr_nb),1), 'k.','Color',mw_colors(4,:),'MarkerSize',markersize);
% add STD bars
for i = 1:snr_nb
    plot([X(i) X(i)],[mean(Y1(:,i),1)-std(Y1(:,i))/sqrt(length(file)-1) mean(Y1(:,i),1)+std(Y1(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std,'Color',mw_colors(1,:));
    plot([X(i) X(i)],[mean(Y2(:,i),1)-std(Y2(:,i))/sqrt(length(file)-1) mean(Y2(:,i),1)+std(Y2(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std,'Color',mw_colors(2,:));
    plot([X(i) X(i)],[mean(Y3(:,i),1)-std(Y3(:,i))/sqrt(length(file)-1) mean(Y3(:,i),1)+std(Y3(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std,'Color',mw_colors(3,:));
    plot([X(i) X(i)],[mean(Y4(:,i),1)-std(Y4(:,i))/sqrt(length(file)-1) mean(Y4(:,i),1)+std(Y4(:,i))/sqrt(length(file)-1)],'k-', 'LineWidth',linew_std,'Color',mw_colors(4,:));
end

% Add legend, etc.
%xlabel('Stimulus intensity level (SNR, in dB)', 'FontSize',fontsize);
ylabel('Proportion of response type (%)', 'FontSize',fontsize);
%plot([-25 0],[50 50],'--', 'Color',black);
%legend('Sound', 'Environment', 'Thoughts', 'Nothing','Position',[0.92 0.6 0.07 0.15], 'Fontsize',legendsize, 'EdgeColor','white');
%legend('Sound', 'Environment', 'Thoughts', 'Nothing','Location', 'Best', 'Fontsize',legendsize-2, 'EdgeColor','white');
%set(gca,'FontSize',fontsize,'XTick',[-20 -11.5 -9.5 -7.5 -3],'XTickLabel',{'no sound'; 'level 1'; 'level 2'; 'level 3'; 'level 4'});
set(gca,'FontSize',numsize,'XTick',[-20, -10, -7.5, -5, -1],'XTickLabel',{'N'; '-10'; '-7.5'; '-5'; '-1'}); 
set(gca,'FontSize',numsize,'YTick',0:20:100);
axis([-21 0 ylim]);
title({'Mind wandering responses (%)';' '},'FontSize',fontsize);
xtickangle(angle)
