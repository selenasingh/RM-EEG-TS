%function ft_realtime_fileproxy(cfg)

% FT_REALTIME_FILEPROXY reads continuous data from an EEG/MEG file and writes it to a
% FieldTrip buffer. This works for any file format that is supported by FieldTrip.
%
% The FieldTrip buffer is a network transparent server that allows the acquisition
% client to stream data to it. An analysis client can connect to read the data upon
% request. Multiple clients can connect simultaneously, each analyzing a specific
% aspect of the data concurrently.
%
% Use as
%   ft_realtime_fileproxy(cfg)
% with the following configuration options
%   cfg.minblocksize         = number, in seconds (default = 0)
%   cfg.maxblocksize         = number, in seconds (default = 1)
%   cfg.channel              = cell-array, see FT_CHANNELSELECTION (default = 'all')
%   cfg.jumptoeof            = jump to end of file at initialization (default = 'no')
%   cfg.readevent            = whether or not to copy events (default = 'no'; event type can also be specified; e.g., 'UPPT002')
%   cfg.speed                = relative speed at which data is written (default = inf)
%
% The source of the data is configured as
%   cfg.source.dataset       = string
% or alternatively to obtain more low-level control as
%   cfg.source.datafile      = string
%   cfg.source.headerfile    = string
%   cfg.source.eventfile     = string
%   cfg.source.dataformat    = string, default is determined automatic
%   cfg.source.headerformat  = string, default is determined automatic
%   cfg.source.eventformat   = string, default is determined automatic
%
% The target to write the data to is configured as
%   cfg.target.datafile      = string, target destination for the data (default = 'buffer://localhost:1972')
%   cfg.target.dataformat    = string, default is determined automatic
%
% To stop this realtime function, you have to press Ctrl-C
%
% See also FT_REALTIME_SIGNALPROXY, FT_REALTIME_SIGNALVIEWER

% Copyright (C) 2008, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup the gTec System Interface:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create gtecDeviceInterface object
gds_interface = gtecDeviceInterface();

% define connection settings (loopback)
gds_interface.IPAddressHost = '127.0.0.1';
gds_interface.IPAddressLocal = '127.0.0.1';
gds_interface.LocalPort = 50224;
gds_interface.HostPort = 50223;

% get connected devices
connected_devices = gds_interface.GetConnectedDevices();

% create g.Nautilus configuration object
gnautilus_config = gNautilusDeviceConfiguration();
% set serial number in g.Nautilus device configuration
gnautilus_config.Name = connected_devices(1,1).Name;

% set configuration to use functions in gds interface which require device
% connection
gds_interface.DeviceConfigurations = gnautilus_config;

% get available channels
available_channels = gds_interface.GetAvailableChannels();
% get supported sensitivities
supported_sensitivities = gds_interface.GetSupportedSensitivities();
% get supported input sources
supported_input_sources = gds_interface.GetSupportedInputSources();

% if sampling rate 250Hz - 4 scans
% if sampling rate 500Hz - 8 scans 
% edit configuration to have a sampling rate of 500Hz, 8 scans, all
% available analog channels as well as ValidationIndicator and Counter.
% Acquire the internal test signal of g.Nautilus
gnautilus_config.SamplingRate = 500;
gnautilus_config.NumberOfScans = 8;
gnautilus_config.InputSignal = supported_input_sources(3).Value;
gnautilus_config.NoiseReduction = false;
gnautilus_config.CAR = false;
% acquire additional channels counter and validation indicator
gnautilus_config.Counter = true;
gnautilus_config.ValidationIndicator = true;
% do not acquire other additional channels
gnautilus_config.AccelerationData = false;
gnautilus_config.LinkQualityInformation = false;
gnautilus_config.BatteryLevel = false;
gnautilus_config.DigitalIOs = false;
for i=1:size(gnautilus_config.Channels,2)
    if (available_channels(1,i))
    	gnautilus_config.Channels(1,i).Available = true;
        gnautilus_config.Channels(1,i).Acquire = true;
        % set sensitivity to 187.5 mV
        gnautilus_config.Channels(1,i).Sensitivity = supported_sensitivities(6);
        % do not use channel for CAR and noise reduction
        gnautilus_config.Channels(1,i).UsedForNoiseReduction = false;
        gnautilus_config.Channels(1,i).UsedForCAR = false;
        % do not use filters
        gnautilus_config.Channels(1,i).BandpassFilterIndex = -1;
        gnautilus_config.Channels(1,i).NotchFilterIndex = -1;
        % do not use a bipolar channel
        gnautilus_config.Channels(1,i).BipolarChannel = -1;
    end
end

% apply configuration to the gds interface
gds_interface.DeviceConfigurations = gnautilus_config;

% set configuration provided in DeviceConfigurations
gds_interface.SetConfiguration();

% get total number of channels:
num_channels = sum(available_channels);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup the default fieldtrip settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(cfg, 'target'),               cfg.target = [];                                  end % default is detected automatically
if ~isfield(cfg.target, 'headerformat'),  cfg.target.headerformat = [];                     end % default is detected automatically
if ~isfield(cfg.target, 'dataformat'),    cfg.target.dataformat = [];                       end % default is detected automatically
if ~isfield(cfg.target, 'datafile'),      cfg.target.datafile = 'buffer://localhost:1972';  end
if ~isfield(cfg, 'minblocksize'),         cfg.minblocksize = 0;                             end % in seconds
if ~isfield(cfg, 'maxblocksize'),         cfg.maxblocksize = 1;                             end % in seconds
if ~isfield(cfg, 'channel'),              cfg.channel = 'all';                              end
if ~isfield(cfg, 'jumptoeof'),            cfg.jumptoeof = 'no';                             end % jump to end of file at initialization
if ~isfield(cfg, 'readevent'),            cfg.readevent = 'no';                             end % capture events?
if ~isfield(cfg, 'speed'),                cfg.speed = inf ;                                 end % inf -> run as fast as possible
if ~isfield(cfg, 'channel'),              cfg.channel = ft_senslabel('eeg1020');            end

% ensure that the persistent variables related to caching are cleared
clear ft_read_header

hdr = [];
hdr.Fs = gnautilus_config.SamplingRate;   % sampling frequency
hdr.nChans = sum(available_channels);     % number of channels
hdr.label = cfg.channel;
hdr.nSamples = 0;
hdr.nSamplesPre = 0;
hdr.nTrials = 1;

blocksmp   = gnautilus_config.NumberOfScans; % Can change this to a different size if wanted
count       = 0;
prevSample  = 0;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the iterative loop where realtime incoming data is put into ft format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start GDS data acquisition
gds_interface.StartDataAcquisition();
% newsamples = gnautilus_config.NumberOfScans;
while true

    % increment the number of samples
    hdr.nSamples = hdr.nSamples + blocksmp;
    
    begsample  = prevSample+1;
    endsample  = prevSample+blocksmp;
    
    % remember up to where the data was read
    prevSample  = endsample;
    count       = count + 1;
    fprintf('processing segment %d from sample %d to %d\n', count, begsample, endsample);
    
    % read data segment from GDS interface
    try [scans_received, data] = gds_interface.GetData(gnautilus_config.NumberOfScans); catch ME, disp(ME.message); break; end
    
    % wait for a realistic amount of time
    pause(((endsample-begsample+1)/hdr.Fs)/cfg.speed);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % from here onward it is specific to writing the data to fieldtrip stream
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if count==1
        % flush the file, write the header and subsequently write the data segment
        ft_write_data(cfg.target.datafile, data(:,1:end-2)', 'header', hdr, 'dataformat', cfg.target.dataformat, 'append', false);
    else
        % write the data segment
        ft_write_data(cfg.target.datafile, data(:,1:end-2)', 'header', hdr, 'dataformat', cfg.target.dataformat, 'append', true);
    end % if count==1
end % while true

% stop data acquisition
gds_interface.StopDataAcquisition();

% delete gds_interface to close connection to device
delete(gds_interface)
