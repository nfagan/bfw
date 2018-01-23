function make_sync_times()

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'sync' );

do_save = true;

mats = shared_utils.io.find( data_p, '.mat' );

pl2_map = bfw.get_plex_channel_map();

copy_fields = { 'unified_filename', 'plex_filename', 'plex_directory' };

for i = 1:numel(mats)
  unified = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( unified );
  first = fields{1};
  
  pl2_file = unified.(first).plex_filename;
  pl2_dir = fullfile( unified.(first).plex_directory{:} );
  pl2_dir = fullfile( data_root, pl2_dir );
  
  pl2_file = fullfile( pl2_dir, pl2_file );
  
  sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
  start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );
  reward_pulse_raw = PL2Ad( pl2_file, pl2_map('reward') );

  sync_pulses = bfw.get_pulse_indices( sync_pulse_raw.Values );
  reward_pulses = bfw.get_pulse_indices( reward_pulse_raw.Values );
  start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );

  binned_sync = bfw.bin_pulses( sync_pulses, start_pulses );
  binned_reward = bfw.bin_pulses( reward_pulses, start_pulses );
  
  sync_index = unified.(first).plex_sync_index;
  
  if ( sync_index < 1 || sync_index > numel(binned_sync) )
    error( 'Sync index for "%s" must be > 1 and <= %d; was %d.' ...
      , mats{i}, numel(binned_sync), sync_index ); 
  end
  
  current_plex_sync = binned_sync{sync_index};
  current_plex_reward = binned_reward{sync_index};
  current_plex_start = start_pulses(sync_index);
  
  if ( numel(current_plex_sync) == 0 )
    error( 'No sync times were found for "%s" and index %d. Check your plex_sync_map.json file.' ...
      , mats{i}, sync_index );
  end
  
  mat_sync = unified.m2.plex_sync_times;
  mat_reward_sync = unified.m2.reward_sync_times;
  
  assert( numel(mat_reward_sync) == numel(current_plex_reward), ['Mismatch between' ...
    , ' number of plex reward sync and mat reward sync pulses.'] );
  
  %   current_sync should have one fewer element than mat_sync. This is
  %   because the first mat_sync time corresponds to the start_sync pulse
  assert( numel(mat_sync) == numel(current_plex_sync) + 1, ['Mismatch between' ...
    , ' number of plex sync and mat sync pulses.'] );
  
  current_plex_sync = [ current_plex_start; current_plex_sync ];
  
  sync = struct();
  
  sync.reward = [ mat_reward_sync(:), current_plex_reward(:) ];
  sync.plex_sync = [ mat_sync(:), current_plex_sync(:) ];
  sync.sync_key = { 'mat', 'plex' };
  
  for j = 1:numel(copy_fields)
    sync.(copy_fields{j}) = unified.(first).(copy_fields{j});
  end
  
  if ( do_save )
    shared_utils.io.require_dir( save_p );
    mat_dir_name = unified.(first).mat_directory_name;
    mat_filename = unified.(first).mat_filename;
    filename = bfw.make_intermediate_filename( mat_dir_name, mat_filename );
    save( fullfile(save_p, filename), 'sync' );
  end
end

end