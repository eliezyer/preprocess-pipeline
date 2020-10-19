
function [digital_input_ts] = extract_intan_TTL_timestamp(basedir)
% function to extract digital inputs from intan and organize them into a
% structure
%    INPUT:
%           basedir - directory where digital inputs are located
%    
%    OUTPUT:
%           ouputstruct - structure with all the channels from intan with
%           start stop of all the TTLs detected. Example:
%                outputstruct.channel(2).start
%                outputstruct.channel(2).stop
% developed by Eliezyer de Oliveira 2020

%% script starts here.

%% load digital inputs from intan splitted into channels
[dig_in_data] = Load_intanDigIn(basedir);

%% get sampling rate from xml file
temp = dir('*.xml');
xml_file = LoadXml(temp.name);
sr = xml_file.SampleRate;

%% identify start and end of each TTL

%creating time vector
time_vec = linspace(0,size(dig_in_data,1)/sr,size(dig_in_data,1));

%getting start and stop times for each channel
temp = diff(dig_in_data);
for a = 1:size(dig_in_data,2)
    m.channel(a).start = time_vec(find(temp(:,a)==1)+1);
    m.channel(a).stop  = time_vec(find(temp(:,a)==-1));
end

%save in a structure
digital_input_ts = m;
digital_input_ts.channel_info = ['number of channels identified in the system.'...
    ' Each index of the structure correspond to a channel, start and stop variables ',...
    'are in seconds'];
digital_input_ts.sr = sr;
digital_input_ts.sr_info = 'sampling rate in Hz, identified in the .xml file';
script_loc = which('extract_intan_TTL_timestamp');
digital_inputs_ts.script_info = ['file generate by extract_intan_TTL_timestamp ',...
    'located at ' script_loc];

save('digital_input_ts','digital_input_ts')
