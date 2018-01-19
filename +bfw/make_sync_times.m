function make_sync_times()

conf = bfw.config.load();

data_p = fullfile( conf.PATHS.data_root, 'intermediates', 'unified' );

mats = shared_utils.io.find( data_p, '.mat' );

pl2_map = bfw.get_plex_channel_map();

for i = 1:numel(mats)
  unified = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( unified );
  
  pl2_file = unified.(fields{1}).plex_filename;
  pl2_dir = unified.(fields{1}).plex_directory;
  
  pl2_file = fullfile( pl2_dir, pl2_file );
  
  sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
  start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );

  ai_fs = start_pulse_raw.ADFreq;

  sync_pulses = bfw.get_pulse_indices( sync_pulse_raw.Values );
  start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );

  id_times = bfw.get_ad_id_times( numel(sync_pulse_raw.Values), ai_fs );

  binned = bfw.bin_pulses( sync_pulses, start_pulses );
  
  d = 10;
  
end

end