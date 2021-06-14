%finding noise periods during optotagging and interpolating
load('recording_intervals.mat')
load('digital_input_ts.mat')
fname = '210302.dat';
%find intervals for opto tagging recording
temp = strfind(recording_intervals.folders_name,'opto');
dir2use = cellfun(@(x) ~isempty(x),temp);
%getting the intervals we are going to work with
wrk_intervals = [recording_intervals.stop_times(find(dir2use)-1) recording_intervals.stop_times(find(dir2use))];

%getting ttls from the interval we are interested
for a = 1:length(digital_input_ts.channel)
    temp = Restrict(digital_input_ts.channel(a).start,wrk_intervals);
    if ~isempty(temp)
        ttlOI(a).start = temp;
        ttlOI(a).stop = Restrict(digital_input_ts.channel(a).stop,wrk_intervals);
    end
    
end

data = bz_LoadBinary(fname,'frequency',30000,'start',wrk_intervals(1),...
    'duration',diff(wrk_intervals),'nChannels',102);
ts_binary = linspace(wrk_intervals(1),wrk_intervals(2),size(data,1));

% tempidx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(2).start(450)-0.005 ttlOI(2).stop(450)+0.005]));

%identifying uLED that are giving too big noise
%check std of signal 25 ms before pulse (-25 to -5 ms)
bad_uLED = [];
for a = 1:length(ttlOI)
    if ~isempty(ttlOI(a).start)
        baseline_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).start-0.025 ttlOI(a).start-0.010]));
        start_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).start-0.010 ttlOI(a).start+0.015]));
        stop_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).stop-0.010 ttlOI(a).stop+0.030]));
        
        var_bl    = mean(double(data(baseline_idx,:)),1);
        var_start = mean(double(data(start_idx,:)),1);
        var_stop  = mean(double(data(stop_idx,:)),1);
        %check if any variance goes over ridiculous amounts
        if (sum((var_start./var_bl)>5) > 5) || (sum((var_stop./var_bl)>5) > 5)
            bad_uLED = [bad_uLED a];%mark as bad uLED
        end
    end
end

%% plot for checking
figure
scatter(ones(size(var_bl)),var_bl,'ok')
hold on
scatter(2*ones(size(var_start)),var_start,'ok')
scatter(3*ones(size(var_stop)),var_stop,'ok')
%% cleaning the data

%0)delete the data matrix and set up some parameters
clear data
sr = 30000; %make this automatic by reading xml file
nbChan = 102; %also get it automatically from xml file
%1)then create a copy of the .dat file and allocate to memory (memmapfile)
disp('Creating artifact_free.dat file')
copystring = ['! rsync -a -v -W -c -r ', ...
    fname, ' ',...
    [fname(1:end-4),'artifact_free.dat']];
eval(copystring)
%2) I have to get the bad_uLED and get the timestamps and convert to offset
%the memmapfile
new_fname = [fname(1:end-4),'artifact_free.dat'];
for a = 1:length(bad_uLED)%this is the channel list
    
    start = ttlOI(bad_uLED(a)).start;
    stop = ttlOI(bad_uLED(a)).stop;
    for aa = 1:length(start)%this is the pulse stimulation list
        
        offset2use = round((start(aa)-0.010)*sr)*nbChan*2;%this has to be on function of the ttl timestamp
        duration = round(0.075*sr);
        infoFile = dir(new_fname);
        m = memmapfile(new_fname,'Format','int16',...
            'Offset',offset2use,'Repeat',duration*nbChan,'writable',true);
        d = m.Data;
        d = double(reshape(d,[nbChan duration])');
        temp_t = linspace(-0.010,0.065,size(d,1));
        aux_bef = temp_t<-0.001;
        aux_aft = temp_t>0.055;
        %doing for each shank separately with channels that were not skipped
        %on neuroscope
        new_d = interp1([temp_t(aux_bef),temp_t(aux_aft)],...
            d([find(aux_bef),find(aux_aft)],:),temp_t,'pchip');
        
        new_d = new_d';
        m.Data = int16(new_d(:));
        clear d m
        
    end
end
%

%% cleaning stimulus by stimulus instead of removing whole LED


%identifying uLED that are giving too big noise
%check std of signal 25 ms before pulse (-25 to -5 ms)

sr = 30000; %make this automatic by reading xml file
nbChan = 102; %also get it automatically from xml file
%1)then create a copy of the .dat file and allocate to memory (memmapfile)
fname = '201215.dat';
disp('Creating artifact_free.dat file')
copystring = ['! rsync -a -v -W -c -r ', ...
    fname, ' ',...
    [fname(1:end-4),'artifact_free.dat']];
eval(copystring)
%2) I have to get the bad_uLED and get the timestamps and convert to offset
%the memmapfile
new_fname = [fname(1:end-4),'artifact_free.dat'];
for a = 1:length(ttlOI)
    start = ttlOI(bad_uLED(a)).start;
    stop = ttlOI(bad_uLED(a)).stop;
    
    
    for aa = 1:length(start)%this is the pulse stimulation list
        baseline_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).start(aa)-0.025 ttlOI(a).start(aa)-0.010]));
        start_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).start(aa)-0.010 ttlOI(a).start(aa)+0.015]));
        stop_idx = ismember(ts_binary,Restrict(ts_binary,[ttlOI(a).stop(aa)-0.010 ttlOI(a).stop(aa)+0.030]));
        
        var_bl    = mean(double(data(baseline_idx,:)),1);
        var_start = mean(double(data(start_idx,:)),1);
        var_stop  = mean(double(data(stop_idx,:)),1);
        %check if any variance goes over ridiculous amounts
        if (sum((var_start./var_bl)>10) > 1) || (sum((var_stop./var_bl)>10) > 1)
            
            offset2use = round((start(aa)-0.010)*sr)*nbChan*2;%this has to be on function of the ttl timestamp
            duration = round(0.075*sr);
            infoFile = dir(new_fname);
            m = memmapfile(new_fname,'Format','int16',...
                'Offset',offset2use,'Repeat',duration*nbChan,'writable',true);
            d = m.Data;
            d = double(reshape(d,[nbChan duration])');
            temp_t = linspace(-0.010,0.065,size(d,1));
            aux_bef = temp_t<-0.001;
            aux_aft = temp_t>0.055;
            %doing for each shank separately with channels that were not skipped
            %on neuroscope
            new_d = interp1([temp_t(aux_bef),temp_t(aux_aft)],...
                d([find(aux_bef),find(aux_aft)],:),temp_t,'pchip');
            
            new_d = new_d';
            m.Data = int16(new_d(:));
            clear d m
            
        end
    end
end
