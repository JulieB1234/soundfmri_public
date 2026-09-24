function asc = merge_eyelink_asc(asc1, asc2)


% asc = asc1;
% 
% % ---- sample offset ----
% sOffset = size(asc1.dat, 2);
% 
% % ---- concatenate raw data ----
% asc.dat = [asc1.dat, asc2.dat];
% 
% % ---- merge messages ----
% asc.msg = [asc1.msg; asc2.msg];
% % for i = numel(asc1.msg)+1:numel(asc.msg)
% %     asc.msg{i}.time = asc.msg{i}.time + sOffset;
% % end
% 
% % ---- helper to shift event times safely ----
% shift_times = @(x) cellfun(@(y) setfield(y,'time',y.time + sOffset), ...
%                            x, 'UniformOutput', false);
% 
% % % ---- merge fixations ----
% % asc.sfix = [asc1.sfix; asc2.sfix];
% % asc.efix = [asc1.efix; asc2.efix];
% % for i = numel(asc1.sfix)+1:numel(asc.sfix)
% %     asc.sfix{i}.time = asc.sfix{i}.time + sOffset;
% %     asc.efix{i}.time = asc.efix{i}.time + sOffset;
% % end
% % 
% % % ---- merge saccades ----
% % asc.ssacc = [asc1.ssacc; asc2.ssacc];
% % asc.esacc = [asc1.esacc; asc2.esacc];
% % for i = numel(asc1.ssacc)+1:numel(asc.ssacc)
% %     asc.ssacc{i}.time = asc.ssacc{i}.time + sOffset;
% %     asc.esacc{i}.time = asc.esacc{i}.time + sOffset;
% % end
% % 
% % % ---- merge blinks ----
% % asc.sblink = [asc1.sblink; asc2.sblink];
% % asc.eblink = [asc1.eblink; asc2.eblink];
% % for i = numel(asc1.sblink)+1:numel(asc.sblink)
% %     asc.sblink{i}.time = asc.sblink{i}.time + sOffset;
% %     asc.eblink{i}.time = asc.eblink{i}.time + sOffset;
% % end
% 
% % ---- fixations ----
% asc.sfix  = [asc1.sfix;  shift_times(asc2.sfix)];
% asc.efix  = [asc1.efix;  shift_times(asc2.efix)];
% 
% % ---- saccades ----
% asc.ssacc = [asc1.ssacc; shift_times(asc2.ssacc)];
% asc.esacc = [asc1.esacc; shift_times(asc2.esacc)];
% 
% % ---- blinks ----
% asc.sblink = [asc1.sblink; shift_times(asc2.sblink)];
% asc.eblink = [asc1.eblink; shift_times(asc2.eblink)];

asc = asc1;

% ---- concatenate continuous samples ----
asc.dat = [asc1.dat, asc2.dat];

% ---- concatenate all event text verbatim ----
asc.msg    = [asc1.msg;    asc2.msg];
asc.sfix   = [asc1.sfix;   asc2.sfix];
asc.efix   = [asc1.efix;   asc2.efix];
asc.ssacc  = [asc1.ssacc;  asc2.ssacc];
asc.esacc  = [asc1.esacc;  asc2.esacc];
asc.sblink = [asc1.sblink; asc2.sblink];
asc.eblink = [asc1.eblink; asc2.eblink];

end
