function mua = GetMUA(varargin)
% getMUA - Get MUA timestamps.
%       
% This function is based on the bz_GetSpikes, I updated so it creates a new
% file that has the MUA so it can be used in other analysis that is not
% required single cell clusters. The documentation below is from
% bz_GetSpikes, input/output fields are maintained but I removed the
% support for neurosuite files.
%
% Eliezyer de Oliveira - 17/Dec/2020
%
% USAGE
%
%    mua = bz_getSpikes(varargin)
% 
% INPUTS
%
%    spikeGroups     -vector subset of shank IDs to load (Default: all)
%    region          -string region ID to load neurons from specific region
%                     (requires sessionInfo file or units->structures in xml)
%    UID             -vector subset of UID's to load 
%    basepath        -path to recording (where .dat/.clu/etc files are)
%    getWaveforms    -logical (default=true) to load mean of raw waveform data
%    forceReload     -logical (default=false) to force loading from
%                     res/clu/spk files
%    onlyLoad        -[shankID cluID] pairs to EXCLUSIVELY LOAD from 
%                       clu/res/fet to mua.cellinfo.mat file
%    saveMat         -logical (default=false) to save in buzcode format
%    noPrompts       -logical (default=false) to supress any user prompts
%    verbose         -logical (default=false)
%    keepCluWave     -logical (default=false) to keep waveform from .spk files
%                       as in previous bz_getSpikes functions (before 2019)
%                       If false (default), it instead uses waveforms directly from
%                       .dat files.  
%    sortingMethod   - [], 'kilosort' or 'clu'. If [], tries to detect a
%                   kilosort folder or clu files. 
%    
% OUTPUTS
%
%    mua - cellinfo struct with the following fields
%          .sessionName    -name of recording file
%          .UID            -unique identifier for each neuron in a recording
%          .times          -cell array of timestamps (seconds) for each neuron
%          .spindices      -sorted vector of [spiketime UID], useful for 
%                           input to some functions and plotting rasters
%          .region         -region ID for each neuron (especially important large scale, high density probes)
%          .shankID        -shank ID that each neuron was recorded on
%          .maxWaveformCh  -channel # with largest amplitude spike for each neuron
%          .rawWaveform    -average waveform on maxWaveformCh (from raw .dat)
%          .cluID          -cluster ID, NOT UNIQUE ACROSS SHANKS
%          .numcells       -number of cells/UIDs
%          .filtWaveform   -average filtered waveform on maxWaveformCh
%           
% NOTES
%
% This function can be used in several ways to load spiking data.
% Specifically, it loads spiketimes for individual neurons and other
% sessionInfodata that describes each neuron.  Spiketimes can be loaded using the
% UID(1-N), the shank the neuron was on, or the region it was recorded in.
% The default behavior is to load all mua in a recording. The .shankID
% and .cluID fields can be used to reconstruct the 'units' variable often
% used in FMAToolbox.
% units = [mua.shankID mua.cluID];
% 
% 
% first usage recommendation:
% 
%   mua = bz_getSpikes('saveMat',true); Loads and saves all spiking data
%                                          into buzcode format .cellinfo. struct
% other examples:
%
%   mua = bz_getSpikes('spikeGroups',1:5); first five shanks
%
%   mua = bz_getSpikes('region','CA1'); cells tagged as recorded in CA1
%
%   mua = bz_getSpikes('UID',[1:20]); first twenty neurons
%
%
% written by David Tingley, 2017
% added Phy loading by Manu Valero, 2019 (previos bz_LoadPhy)

% TO DO: Get waveforms by an independent function (ie getWaveform) that
% generates a waveform.cellinfo.mat file with all channels waves.
%% Deal With Inputs 
spikeGroupsValidation = @(x) assert(isnumeric(x) || strcmp(x,'all'),...
    'spikeGroups must be numeric or "all"');

p = inputParser;
addParameter(p,'spikeGroups','all',spikeGroupsValidation);
addParameter(p,'region','',@isstr); % won't work without sessionInfodata 
addParameter(p,'UID',[],@isvector);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'getWaveforms',true)
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'noPrompts',false,@islogical);
addParameter(p,'onlyLoad',[]);
addParameter(p,'verbose',false,@islogical);
addParameter(p,'keepCluWave',false,@islogical);
addParameter(p,'sortingMethod',[],@isstr);

parse(p,varargin{:})

spikeGroups = p.Results.spikeGroups;
region = p.Results.region;
UID = p.Results.UID;
basepath = p.Results.basepath;
getWaveforms = p.Results.getWaveforms;
forceReload = p.Results.forceReload;
saveMat = p.Results.saveMat;
noPrompts = p.Results.noPrompts;
onlyLoad = p.Results.onlyLoad;
verbose = p.Results.verbose;
keepCluWave = p.Results.keepCluWave;
sortingMethod = p.Results.sortingMethod;

[sessionInfo] = bz_getSessionInfo(basepath, 'noPrompts', noPrompts);
baseName = bz_BasenameFromBasepath(basepath);

mua.samplingRate = sessionInfo.rates.wideband;
nChannels = sessionInfo.nChannels;

cellinfofile = [basepath filesep sessionInfo.FileName '.mua.cellinfo.mat'];
datfile = [basepath filesep sessionInfo.FileName '.dat'];
%% if the cellinfo file exist and we don't want to re-load files
if exist(cellinfofile,'file') && forceReload == false
    disp('loading mua from cellinfo file..')
    load(cellinfofile)
        
    %If regions have been added since creation... add them
    if ~isfield(mua,'region') & isfield(sessionInfo,'region')
        if ~isfield(mua,'numcells')
            mua.numcells = length(mua.UID);
        end
        if isfield(mua,'maxWaveformCh')
            for cc = 1:mua.numcells
                mua.region{cc} = sessionInfo.region{mua.maxWaveformCh(cc)==sessionInfo.channels};
            end
        end
        
        if saveMat
            save(cellinfofile,'mua')
        end
    end
    
    if ~noPrompts & saveMat == 0 %Inform the user that they should save a file for later
        savebutton = questdlg(['Would you like to save your mua in ',...
            sessionInfo.FileName,'.mua.cellinfo.mat?  ',...
            'This will save significant load time later.']);
        if strcmp(savebutton,'Yes'); 
            saveMat = true; 
        end
    end
    
else
    % find res/clu/fet/spk files or kilosort folder here...
%     kilosort_path = dir([basepath filesep '*kilosort*']);
    %Finding kilosort folder, case insensitive - added by EFO
    temp = dir(basepath);
    aux  = strfind(lower({temp.name}),lower('kilosort'));
    fold_idx = find(cellfun(@(x) ~isempty(x),aux));
    %in case of multiple folders, it's going to take the first one in the
    %list
    if ~isempty(fold_idx)
        kilosort_path = temp(fold_idx(1));
    else
        kilosort_path = [];
    end
    
    if strcmpi(sortingMethod, 'kilosort') || ~isempty(kilosort_path) % LOADING FROM KILOSORT

        disp('loading mua from Kilosort/Phy format...')
        fs = mua.samplingRate; 
        spike_cluster_index = readNPY(fullfile(kilosort_path.name, 'spike_clusters.npy'));
        spike_times = readNPY(fullfile(kilosort_path.name, 'spike_times.npy'));
        cluster_group = tdfread(fullfile(kilosort_path.name,'cluster_group.tsv'));
        
        %extracting shank information if it's kilosort2/phy2 output
        if exist(fullfile(kilosort_path.name,'cluster_info.tsv'),'file')
            cluster_info = tdfread(fullfile(kilosort_path.name,'cluster_info.tsv'));
            if isfield(cluster_info,'ch') %if it has the channel field
                clu_channels = cluster_info.ch;
                shanks = zeros(size(clu_channels));
                
                for s = 1:sessionInfo.spikeGroups.nGroups
                    temp1 = ismember(clu_channels,sessionInfo.spikeGroups.groups{s});
                    shanks(temp1) = s;
                end
            end
        else %otherwise try to load shanks.npy from kilosort1/phy1
            try
                shanks = readNPY(fullfile(kilosort_path.name, 'shanks.npy')); % done
            catch
                shanks = ones(size(cluster_group.cluster_id));
                warning('No shanks.npy file, assuming single shank!');
            end
        end
        mua.sessionName = sessionInfo.FileName;
        jj = 1;
        for ii = 1:length(cluster_group.group)
            if strcmpi(strtrim(cluster_group.group(ii,:)),'mua')
                ids = find(spike_cluster_index == cluster_group.cluster_id(ii)); % cluster id
                mua.cluID(jj) = cluster_group.cluster_id(ii);
                mua.UID(jj) = jj;
                mua.times{jj} = double(spike_times(ids))/fs; % cluster time
                mua.ts{jj} = double(spike_times(ids)); % cluster time
                cluster_id = find(cluster_group.cluster_id == mua.cluID(jj));
                mua.shankID(jj) = double(shanks(cluster_id));
                jj = jj + 1;
            end
        end

        if ~isfield(mua,'region') && isfield(mua,'maxWaveformCh') && isfield(sessionInfo,'region')
            for cc = 1:length(mua.times)
                mua.region{cc} = [sessionInfo.region{find(mua.maxWaveformCh(cc)==sessionInfo.channels)} ''];
            end
        end
    else
        error('Unit format not recognized...');
    end

    % get waveforms from .dat file if possible, should be better than .spk
    % and as of 8/2020 is default to overwrite any .spk.  Will keep
    % .spk-based mua if no .dat present however.
    if any(getWaveforms) && ~keepCluWave
        nPull = 1000;  % number of mua to pull out
        wfWin = 0.008; % Larger size of waveform windows for filterning
        filtFreq = 500;
        hpFilt = designfilt('highpassiir','FilterOrder',3, 'PassbandFrequency',filtFreq,'PassbandRipple',0.1, 'SampleRate',fs);
        wfWin = round((wfWin * fs)/2);%in samples
        for ii = 1 : size(mua.times,2)
            spkTmp = mua.times{ii};
            if length(spkTmp) > nPull
                spkTmp = spkTmp(randperm(length(spkTmp)));
                spkTmp = spkTmp(1:nPull);
            end
            wf = [];
            for jj = 1 : length(spkTmp)
                if verbose
                    fprintf(' ** %3.i/%3.i for cluster %3.i/%3.i  \n',jj, length(spkTmp), ii, size(mua.times,2));
                end
                %updated by EFO on 18/11/2020, bz_LoadBinary needs offset input in
                %samples and not in seconds
                wf = cat(3,wf,bz_LoadBinary([sessionInfo.session.name '.dat'],'offset',round(spkTmp(jj)*fs) - (wfWin),...
                    'samples',(wfWin * 2)+1,'frequency',sessionInfo.rates.wideband,'nChannels',sessionInfo.nChannels));
            end
            wf = mean(wf,3);
            if isfield(sessionInfo,'badchannels')
                wf(:,ismember(sessionInfo.channels,sessionInfo.badchannels))=0;
            end
            for jj = 1 : size(wf,2)          
                wfF(:,jj) = filtfilt(hpFilt,wf(:,jj) - mean(wf(:,jj)));
            end
            %updated by EFO on 18/11/2020 to only get the max channel on
            %the respective shank, avoiding getting waveform of a dead
            %channel
            shank_ch = sessionInfo.spikeGroups.groups{mua.shankID(ii)}+1; %Channels are 0-based
            [~, maxCh] = max(abs(wfF(wfWin,shank_ch)));
            maxCh = shank_ch(maxCh);
            rawWaveform = detrend(wf(:,maxCh) - mean(wf(:,maxCh))); 
            filtWaveform = wfF(:,maxCh) - mean(wfF(:,maxCh));
            mua.rawWaveform{ii} = rawWaveform(wfWin-(0.002*fs):wfWin+(0.002*fs)); % keep only +- 1ms of waveform
            mua.filtWaveform{ii} = filtWaveform(wfWin-(0.002*fs):wfWin+(0.002*fs)); 
            mua.maxWaveformCh(ii) = sessionInfo.channels(maxCh);
        end
    end

    if ~isempty(onlyLoad)
        toRemove = true(size(mua.UID));
        for cc = 1:size(onlyLoad,1)
            whichUID = ismember(mua.shankID,onlyLoad(cc,1)) & ismember(mua.cluID,onlyLoad(cc,2));
            toRemove(whichUID) = false;
            if ~any(whichUID)
                display(['No unit with shankID:',num2str(onlyLoad(cc,1)),...
                    ' cluID:',num2str(onlyLoad(cc,2))])
            end
        end
        mua = removeCells(toRemove,mua,getWaveforms);
    end

    %% save to buzcode format (before exclusions)
    if saveMat
        save(cellinfofile,'mua')
    end

end

%% EXCLUSIONS %%

%filter by spikeGroups input
if ~strcmp(spikeGroups,'all')
    [toRemove] = ~ismember(mua.shankID,spikeGroups);
    mua = removeCells(toRemove,mua,getWaveforms);
end

%filter by region input
if ~isempty(region)
    if ~isfield(mua,'region') %if no region information in metadata
        error(['You selected to load cells from region "',region,...
            '", but there is no region information in your sessionInfo'])
    end
    
   toRemove = ~ismember(mua.region,region);
    if sum(toRemove)==length(mua.UID) %if no cells from selected region
        warning(['You selected to load cells from region "',region,...
            '", but none of your cells are from that region'])
    end
    
    mua = removeCells(toRemove,mua,getWaveforms);
end

%filter by UID input
if ~isempty(UID)
	[toRemove] = ~ismember(mua.UID,UID);
    mua = removeCells(toRemove,mua,getWaveforms);   
end

%% Generate spindices matrics
mua.numcells = length(mua.UID);
for cc = 1:mua.numcells
    groups{cc}=mua.UID(cc).*ones(size(mua.times{cc}));
end
if mua.numcells>0
    alltimes = cat(1,mua.times{:}); groups = cat(1,groups{:}); %from cell to array
    [alltimes,sortidx] = sort(alltimes); groups = groups(sortidx); %sort both
    mua.spindices = [alltimes groups];
end

%% Check if any cells made it through selection
if isempty(mua.times) | mua.numcells == 0
    mua = [];
end

end

%%
function mua = removeCells(toRemove,mua,getWaveforms)
%Function to remove cells from the structure. toRemove is the INDEX of
%the UID in mua.UID
    mua.UID(toRemove) = [];
    mua.times(toRemove) = [];
    mua.region(toRemove) = [];
    mua.shankID(toRemove) = [];
    if isfield(mua,'cluID')
        mua.cluID(toRemove) = [];
    elseif isfield(mua,'UID_kilosort')
        mua.UID_kilosort(toRemove) = [];
    end
    
    if any(getWaveforms)
        mua.rawWaveform(toRemove) = [];
        mua.maxWaveformCh(toRemove) = [];
        if isfield(mua,'filtWaveform')
            mua.filtWaveform(toRemove) = [];
        end
    end
end





