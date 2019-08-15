function time_file = plex_fp_time(files, varargin)

bfw.validatefiles( files, 'unified' );

unified_file = shared_utils.general.get( files, 'unified' );

unified_filename = bfw.try_get_unified_filename( unified_file );

data_root = bfw.dataroot( varargin{:} );
pl2_map = bfw.get_plex_channel_map();

pl2_file = unified_file.m1.plex_filename;
pl2_dir = fullfile( unified_file.m1.plex_directory{:} );
pl2_dir = fullfile( data_root, pl2_dir );
pl2_file = fullfile( pl2_dir, pl2_file );

if ( ~shared_utils.io.fexists(pl2_file) )
  error( 'Skipping "%s" because the .pl2 file "%s" does not exist.' ...
    , unified_filename, pl2_file );
end

sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
id_times = (0:numel(sync_pulse_raw.Values)-1) .* (1/sync_pulse_raw.ADFreq);

time_file = struct();
time_file.unified_filename = unified_filename;
time_file.id_times = id_times;

end