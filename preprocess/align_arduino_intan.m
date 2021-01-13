%intan records channels 0-indexed, the list below is already summed 1
%init poke enter:       ch 02
%right poke enter:      ch 03
%left poke enter:       ch 04
%trial available:       ch 10
%cue 1:                 ch 11
%cue 2:                 ch 12
function align_arduino_intan(basepath)


%% loading essentials
load(fullfile(basepath,'digital_input_ts'))
load(fullfile(basepath,'recording_intervals.mat'))
aux = dir(fullfile(basepath,'arduino_2afc.*'));
load(fullfile(basepath,aux.name))

%important parameters
binSize = 0.1; %in seconds

%% getting trial available information from both systems
%getting trial available on intan
bins_intan = linspace(0,recording_intervals.stop_times(end),recording_intervals.stop_times(end)/binSize);
trial_avail_intan = histcounts(digital_input_ts.channel(10).start,bins_intan);

%now getting trial available on arduino
temp = arduino_2afc.pokes.trial_avails/1000; %converting to seconds

%% getting the offset from intan recording behavior and arduino log file
%first identify which intan recording is the closest to arduino
time_intan = cellfun(@(x) str2num(x(end-5:end)),recording_intervals.folders_name);
%identify the folder
[~,I]=sort(abs(str2num(arduino_2afc.time)-time_intan));
%calculate the difference in time between arduino and intan based on the
%time recorded on their filename
temp_intan = recording_intervals.folders_name{I(1)}(end-5:end);
temp_ard = arduino_2afc.time;

h_intan = str2num(temp_intan(1:2));m_intan = str2num(temp_intan(3:4));s_intan = str2num(temp_intan(5:6));
h_ard = str2num(temp_ard(1:2));m_ard = str2num(temp_ard(3:4));s_ard = str2num(temp_ard(5:6));

temp_intan = h_intan*3600 + m_intan*60 + s_intan;
temp_ard = h_ard*3600 + m_ard*60 + s_ard;

time_offset = temp_ard-temp_intan;
arduino_offset = recording_intervals.stop_times(I(1))+time_offset;

%use this variable to cross-correlate with the intan, repeat for smaller
%timescales once you find the correct peak
trial_avail_arduino = histcounts(temp+arduino_offset,bins_intan);
trial_avail_intan = histcounts(digital_input_ts.channel(10).start,bins_intan);

[rho,lags] = xcorr(trial_avail_intan,trial_avail_arduino);

%identify the lag and fix
arduino_offset2 = arduino_offset+(27*binSize);

%make plots to compare random left pokes from arduino to intan and save in
%a separate folder so I can make sure the synchroniztion is correct