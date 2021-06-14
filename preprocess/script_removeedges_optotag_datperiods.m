%interpolating 2 ms of edge artifacts from uled stimulation
% load('recording_intervals.mat')
load('digital_input_ts.mat')
fname = 'amplifier_analogin_auxiliary_int16.dat';
%find intervals for opto tagging recording
% temp = strfind(recording_intervals.folders_name,'opto');
% dir2use = cellfun(@(x) ~isempty(x),temp);
%getting the intervals we are going to work with
wrk_intervals = [0 Inf];

%getting ttls from the interval we are interested
uLED_on = [];
for a = 1:length(digital_input_ts.channel)
    temp = Restrict(digital_input_ts.channel(a).start,wrk_intervals);
    if ~isempty(temp)
        ttlOI(a).start = temp;
        ttlOI(a).stop = Restrict(digital_input_ts.channel(a).stop,wrk_intervals);
        uLED_on = [uLED_on a];
    end
    
end


%% cleaning the data

%0)delete the data matrix and set up some parameters
sr = 30000; %make this automatic by reading xml file
nbChan = 102; %also get it automatically from xml file
%1)then create a copy of the .dat file and allocate to memory (memmapfile)
disp('Creating artifact_free.dat file')
copystring = ['! rsync -a -v -W -c -r ', ...
    fname, ' ',...
    [fname(1:end-4),'artifact_free.dat']];
eval(copystring)
%2) I have to get the uLED and get the timestamps and convert to offset
%the memmapfile
new_fname = [fname(1:end-4),'artifact_free.dat'];
for a = 1:length(uLED_on)%this is the channel list
    
    start = ttlOI(uLED_on(a)).start;
    stop = ttlOI(uLED_on(a)).stop;
    for aa = 1:length(start)%this is the pulse stimulation list
        
        offset2use = round((stop(aa)-0.003)*sr)*nbChan*2;%this has to be on function of the ttl timestamp
        duration = round(0.006*sr);
        infoFile = dir(new_fname);
        m = memmapfile(new_fname,'Format','int16',...
            'Offset',offset2use,'Repeat',duration*nbChan,'writable',true);
        d = m.Data;
        d = double(reshape(d,[nbChan duration])');
        temp_t = linspace(-0.003,0.003,size(d,1));
%         aux_bef = temp_t(1)<-0.001;
%         aux_aft = temp_t(2)>0.055;
        %doing for each shank separately with channels that were not skipped
        %on neuroscope
        new_d = interp1([temp_t(1:2),temp_t(end-1:end)],...
            d([1:2,length(temp_t)-1:length(temp_t)],:),temp_t,'pchip');
        
        new_d = new_d';
        m.Data = int16(new_d(:));
        clear d m
        
        %use also the stop 
        
        offset2use = round((start(aa)-0.003)*sr)*nbChan*2;%this has to be on function of the ttl timestamp
        duration = round(0.006*sr);
        infoFile = dir(new_fname);
        m = memmapfile(new_fname,'Format','int16',...
            'Offset',offset2use,'Repeat',duration*nbChan,'writable',true);
        d = m.Data;
        d = double(reshape(d,[nbChan duration])');
        temp_t = linspace(-0.003,0.003,size(d,1));
%         aux_bef = temp_t(1)<-0.001;
%         aux_aft = temp_t(2)>0.055;
        %doing for each shank separately with channels that were not skipped
        %on neuroscope
        new_d = interp1([temp_t(1:2),temp_t(end-1:end)],...
            d([1:2,length(temp_t)-1:length(temp_t)],:),temp_t,'pchip');
        
        new_d = new_d';
        m.Data = int16(new_d(:));
        clear d m
        
    end
end
%