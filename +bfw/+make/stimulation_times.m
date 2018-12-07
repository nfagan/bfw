function stim_file = stimulation_times(files, conf)

%   STIMULATION_TIMES -- Make stimulation times file (in plexon time).
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `conf` (struct) |OPTIONAL|
%     FILES:
%       - 'unified'
%     OUT:
%       - `stim_file` (struct)

unified = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( unified );

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

data_root = bfw.dataroot( conf );
pl2_map = bfw.get_plex_channel_map();
  
sync_id = unified.m1.plex_sync_id;

pl2_file = unified.(sync_id).plex_filename;
pl2_dir = fullfile( unified.(sync_id).plex_directory{:} );
pl2_dir = fullfile( data_root, pl2_dir );

pl2_file = fullfile( pl2_dir, pl2_file );

if ( ~shared_utils.io.fexists(pl2_file) )
  error( '\n Skipping "%s" because the .pl2 file "%s" does not exist.' ...
    , unified_filename, pl2_file );
end

stim_pulse_raw = PL2Ad( pl2_file, pl2_map('stimulation') );
sham_pulse_raw = PL2Ad( pl2_file, pl2_map('sham_stimulation') );
start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );

start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );
stim_pulses = bfw.get_pulse_indices( stim_pulse_raw.Values, 48 );
sham_pulses = bfw.get_pulse_indices( sham_pulse_raw.Values, 48 );

binned_stim = bfw.bin_pulses( stim_pulses, start_pulses );
binned_sham = bfw.bin_pulses( sham_pulses, start_pulses );

sync_index = unified.(sync_id).plex_sync_index;

if ( sync_index < 1 || sync_index > numel(binned_stim) )
  error( 'Sync index for "%s" must be > 1 and <= %d; was %d.' ...
    , unified_filename, numel(binned_stim), sync_index );
end

id_times = (0:numel(stim_pulse_raw.Values)-1) .* (1/stim_pulse_raw.ADFreq);

stim_file = struct();
stim_file.stimulation_times = id_times( binned_stim{sync_index} );
stim_file.sham_times = id_times( binned_sham{sync_index} );
stim_file.unified_filename = unified_filename;

end