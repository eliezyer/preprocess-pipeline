function extract_arduino_2afc_data(basepath)
%function to extract behavioral data from arduino log file and save it as a
%structure. This is mostly to make it easier to compare with the pokes
%recorded on intan and being able to align both data for analysis.
%
% This script is dependent on function extract_poke_info from the 
% behavior_box repository on github.
%
% Eliezyer de Oliveira, 2020

if nargin<1
    basepath = pwd;
end

%% script starts here

%loading .mat files
try
    load(fullfile(basepath,'mouse_info.mat'))
    load(fullfile(basepath,'session_info.mat'))
catch
    warning(['Unable to find .mat files in ' basedir]);
    return
end

%get informaton of the session based on the name
[up_path,basename] = fileparts(basepath);
session_day = basename(end-12:end-7);
session_time = basename(end-5:end);
animal_name = basename(1:end-16);
%getting pokes information
pokes = extract_poke_info(basepath);

%% preparing structure output to be saved
arduino_2afc.animal = animal_name;
arduino_2afc.animal_info = 'animal name';
arduino_2afc.day = session_day;
arduino_2afc.day_info = 'day of the session, in the format YYMMDD';
arduino_2afc.time = session_time;
arduino_2afc.time_info = 'time this session was started, in the format HHMMSS';
arduino_2afc.pokes = pokes;
arduino_2afc.pokes_info = 'poke information extracted using the function extract_poke_info';
arduino_2afc.session_info = session_info;
arduino_2afc.session_info_text = 'information about session ';

save(fullfile(up_path,['arduino_2afc.' session_day '.' session_time '.mat']),'arduino_2afc')
