function [INDEX,EVENT,DATA,prevSample] = get_EEG_data(cfg,blocksize,prevSample,chanindx,INDEX,EVENT,DATA)

% determine number of samples available in buffer
hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true);

% determine the samples to process
if strcmp(cfg.bufferdata, 'last')
    begsample  = hdr.nSamples*hdr.nTrials - blocksize + 1;
    endsample  = hdr.nSamples*hdr.nTrials;
elseif strcmp(cfg.bufferdata, 'first')
    begsample  = prevSample+1;
    endsample  = prevSample+blocksize ;
else
    error('unsupported value for cfg.bufferdata');
end

% this allows overlapping data segments
overlap = cfg.overlap;
if overlap && (begsample>overlap)
    begsample = begsample - overlap;
    endsample = endsample - overlap;
end

% remember up to where the data was read
prevSample  = endsample;

% read data segment from buffer
sig = ft_read_data(cfg.datafile, 'header', hdr, 'dataformat', cfg.dataformat, 'begsample', begsample, 'endsample', endsample, 'chanindx', chanindx, 'checkboundary', false);
evt = ft_read_event(cfg.datafile, 'header', hdr, 'dataformat', cfg.dataformat, 'begsample', begsample, 'endsample', endsample, 'chanindx', chanindx, 'checkboundary', false);
idx = [begsample; endsample];
INDEX = [INDEX idx];
EVENT = [EVENT evt];
DATA = cat(2,DATA,sig);
