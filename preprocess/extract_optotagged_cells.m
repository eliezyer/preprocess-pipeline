%making optotagging analysis
function [optotag] = extract_optotagged_cells(basepath)

%function to determine whether cells were optotagged or not. preliminary
%set of heuristics to determine that, likely to change.
%
% Eliezyer de Oliveira 23/11/2020
cd(basepath)
spikes = bz_GetSpikes;
load('digital_input_ts.mat')
d = digital_input_ts;
pulse_intervals = [];
for a = 1:length(d.channel)
    
    start_ch = d.channel(a).start;
    stop_ch  = d.channel(a).stop;
    %first I have to identify the blocks
    if ~isempty(start_ch)
        thresh = median(diff(start_ch))+std(diff(start_ch)); %threshold for space between pulses
        
        block_stim = [1 find(diff(start_ch)>thresh)+1 length(start_ch')];
        for aa = 1:length(block_stim)-1
            block_interval = [block_stim(aa):block_stim(aa+1)-1];
            pulse_intervals{a,aa} = [start_ch(block_interval); stop_ch(block_interval)]';
        end
    end
end

pulse_info.pulse_intervals = pulse_intervals;
pulse_info.pulse_intervals_info = ['time in seconds of [start stop] stimulation,' ...
    'rows are uLED channels stimulated, columns are blocks of different intensity'];

%get number of spikes inside the stimulation and prior to stimulation,
%absolute number
for a = 1:size(pulse_intervals,1) %channel loop
    for aa = 1:size(pulse_intervals,2) %block stimulation loop
        spike_in  = [];
        spike_out = [];
        p = [];
         for aaa = 1:length(pulse_intervals{a,aa})
            spike_in(aaa,:) = cellfun(@(x) length(Restrict(x,pulse_intervals{a,aa}(aaa,:))),spikes.times);
            spike_out(aaa,:) = cellfun(@(x) length(Restrict(x,[pulse_intervals{a,aa}(aaa,1)-0.05 pulse_intervals{a,aa}(aaa,1)])),spikes.times);
         end
         for b = 1:size(spike_in,2)
             [p(b)] = ranksum(spike_in(:,b),spike_out(:,b));
             spk_zscore(b) = (mean(spike_in(:,b)) - mean(spike_out(:,b)))./std((spike_in(:,b)));
         end
         pulses_spikes(a,aa).spike_in  = spike_in;
         pulses_spikes(a,aa).spike_out = spike_out;
         pulses_spikes(a,aa).p_value   = p;
         pulses_spikes(a,aa).spk_zscore= spk_zscore;
    end    
end 

%% starting set of heuristics to determine if the cell is responsive to light or not

% rearranging data
temp = {pulses_spikes(:,:).spike_in};
temp2=(cell2mat(cellfun(@(x) mean(x),temp','UniformOutput',false)));
%reshaping to have format uLED x pulse intensity x number of cells
temp_in = reshape(temp2,[size(pulses_spikes) length(spikes.times)]);

temp = {pulses_spikes(:,:).spike_out};
temp2=(cell2mat(cellfun(@(x) mean(x),temp','UniformOutput',false)));
%reshaping to have format uLED x pulse intensity x number of cells
temp_out = reshape(temp2,[size(pulses_spikes) length(spikes.times)]);

%get ModIdx
ModIndex_spikes = (temp_in-temp_out)./(temp_in+temp_out);

%get p-value ranksums
temp = cell2mat({pulses_spikes(:,:).p_value}');
%reshaping to have format uLED x pulse intensity x number of cells
p_values = reshape(temp,[size(pulses_spikes) length(spikes.times)]);


%determing cells that are responsive here
%get significant pvalues
logical_p = p_values<0.05;
%sum through all the intensities and get cells that at least had 5 pulse
%intensity with significant spiking
temp_cand = squeeze(sum(logical_p,2))>4; %temporary candidates

[uLED,cells] = find(temp_cand);

%only cells that have at least 5 pulse intensities with ModIndex over 0.5
temp_mod = false(1,length(cells));
for a = 1:length(uLED)
    temp_mod(a)=sum(ModIndex_spikes(uLED(a),:,cells(a))>=0.5)>4;
end

%% preparing structure of optotagging

light_responsive = false(1,size(spikes.times,2));
%these are the cells that were optotagged
light_responsive(cells(temp_mod)) = true;

m.pulse_info                = pulse_info;
m.pulses_spikes             = pulses_spikes;
m.spike_in_info             = 'Field in pulses_spikes. Number of spikes inside the light pulse';
m.spike_out_info            = 'Field in pulses_spikes. Number of spikes outside the light pulse';
m.p_value_info              = 'Field in pulses_spikes. P value on the ranksum test on the number of spikes inside vs outside the pulse';
m.p_value_info              = 'Field in pulses_spikes. Zscored mean spike rate inside the pulses, the zscored is calculated in relation to the mean and std of spike rating outside the pulse times (prior to pulse).';
m.ModIndex                  = ModIndex_spikes;
m.ModIndex_info             = 'Modulation index of cells by light, calculated as (A-B)/(A+B), where A is ';
m.light_responsive          = light_responsive;
m.light_responsive_info     = 'Cells that are responsive to light, according to the heuristics used in our algorithm';
m.function_used             = which('extract_optotagged_cells');
[~,temp]                    = fileparts(basepath);
m.session                   = temp;


optotag = m;
save('optotag.mat','optotag');
