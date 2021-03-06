function [returnVar,msg] = split_dat_file_groups(basepath)

%This function is to split a binary .dat file into smaller files based on
%the anatomical groups of a .xml file. These may correspond to different shanks
% or different brain areas recorded by neuropixels. This function is intended
% to help overcome RAM memory problems, where the spike sorting gets too much
% spikes to handle at once.
% This function will skip anatomical groups where all the channels were
% skipped
%
% The whole function is running on int12 because this was primarly intended
% to neuropixels recordings, but eventually I need to make it compatible to
% int16.
%
% Eliezyer de Oliveira 31/21/2020

cd(basepath)

datFiles = dir('*.dat');
%all dat files you don't want to run this script on, add more as you need.
dats2notuse = {'analogin.dat','auxiliary.dat','digitalin.dat','supply.dat','time.dat'};
%we only use the dat file recording the amplifier
dat2use = ~ismember({datFiles.name},dats2notuse);
if sum(dat2use)
    fname = datFiles(dat2use).name;
else
    error('no .dat file matching script search')
end

%loading xml file to identify anatomical groups
d   = dir('*.xml');
if ~isempty(d)
    par = LoadXml(fullfile(basepath,d(1).name));
else
    error('the .xml file is missing')
end


nbChan = par.nChannels;

infoFile = dir(fname);

chunk = 1e6;
nbChunks = floor(infoFile.bytes/(nbChan*chunk*2));
warning off
if nbChunks==0
    chunk = infoFile.bytes/(nbChan*2);
end

%% this is where we start the chopping
%loop through anatomical groups
for a = 1:length(par.AnatGrps)
    %first we check if the whole group was skipped
    if ~(sum(par.AnatGrps(a).Skip) == length(par.AnatGrps(a).Skip))
       
        
        % CREATE A FOLDER HERE TO SAVE .DAT AND MAT FILE WITH CHANNEL
        % INFO
        %creating the new .dat file
        fname_split = [fname(1:end-4) '_group_' num2str(a) '.dat'];
        if ~exist(fname_split(1:end-4),'dir')
            mkdir(fname_split(1:end-4))
        end
        cd(fname_split(1:end-4))
        disp(['Creating ' fname_split ' file'])
        file_id = fopen(fname_split,'w');
%         skip = 0;
        
        
        %starting script
        disp(['Splitting group ' num2str(a)])
        try
            %getting number of channels
            
            
            for ix=0:nbChunks-1
                m = memmapfile(fullfile(datFiles(dat2use).folder,fname),'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
                d = m.Data;
                d = double(reshape(d,[nbChan chunk])');
                
                %channel number of this shank
                CHnum = par.AnatGrps(a).Channels+1; %neuroscope is 0-based
                %channels to use
                useCH=~logical(par.AnatGrps(a).Skip);
                new_d = zeros(size(d,1),sum(useCH));
                if sum(useCH)>0 && sum(useCH)==length(useCH)
                    %keeping only the channels of the anatomical group that
                    %weren't skipped
                    new_d = d(:,CHnum(useCH));
                end
                new_d = new_d';
                fwrite(file_id,int16(new_d(:)),'int16');
%                 skip = skip + numel(new_d)*2;
                clear d m
            end
            
            
            
            newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;
            
            if newchunk
                m = memmapfile(fullfile(datFiles(dat2use).folder,fname),'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
                d = m.Data;
                d = double(reshape(d,[nbChan newchunk])');
                
                %channel number of this shank
                CHnum = par.AnatGrps(a).Channels+1; %neuroscope is 0-based
                %channels to use
                useCH=~logical(par.AnatGrps(a).Skip);
                new_d = zeros(size(d,1),sum(useCH));
                if sum(useCH)>0 && sum(useCH)==length(useCH)
                    %keeping only the channels of the anatomical group that
                    %weren't skipped
                    new_d = d(:,CHnum(useCH));
                end
                new_d = new_d';
                fwrite(file_id,int16(new_d(:)),'int16');
%                 skip = skip + numel(new_d)*2;
                clear d m
            end
            warning on
            returnVar = 1;
            msg = '';
            
        catch
            fprintf(['Error occurred in processing ' fname_split '. File not processed.\n']);
            keyboard
            returnVar = 0;
            msg = lasterr;
        end
        clear m
    else
        disp('Whole group was skipped on .xml, skipping its split too')
    
    fclose(file_id)
    end
    %SAVE ORIGINAL CHANNEL INFO IN A MAT FILE AND TXT FILE
    original_channel_order = CHnum(useCH);
    save('original_channel_order.mat','original_channel_order')
    fid = fopen('original_channel_order.txt','w');
    fprintf(fid,'%d\n',original_channel_order);
    fclose(fid);
    cd ..
    
end
end