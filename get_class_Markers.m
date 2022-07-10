function [class_MARK,class_MARK_idx] = get_class_Markers(cfg,blocksize,prevSample,class, tr, class_MARK, class_MARK_idx)

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

class_MARK = [class_MARK,(class*100+tr)*ones(1,length(begsample:endsample))]; % "class" defines the 1st digit(MSB); "trial" defines the 2nd and 3rd digits(LSB);
curr_class_MARK_idx = [begsample; endsample];
class_MARK_idx = [class_MARK_idx curr_class_MARK_idx];