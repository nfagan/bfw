function make_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'sync' );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

pl2_map = bfw.get_plex_channel_map();

copy_fields = { 'unified_filename', 'plex_filename', 'plex_directory' };

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  unified = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( unified );
  first = fields{1};
  
  unified_filename = unified.(first).unified_filename;
  output_filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  pl2_file = unified.(first).plex_filename;
  pl2_dir = fullfile( unified.(first).plex_directory{:} );
  pl2_dir = fullfile( data_root, pl2_dir );
  
  pl2_file = fullfile( pl2_dir, pl2_file );
  
  if ( ~shared_utils.io.fexists(pl2_file) )
    fprintf( '\n Skipping "%s" because the .pl2 file "%s" does not exist.' ...
      , unified_filename, pl2_file );
    continue;
  end
  
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
  
  id_times = (0:numel(sync_pulse_raw.Values)-1) .* (1/sync_pulse_raw.ADFreq);
  
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
  current_plex_sync = arrayfun( @(x) id_times(x), current_plex_sync );
  
  current_plex_reward = arrayfun( @(x) id_times(x), current_plex_reward );
  
  sync = struct();
  
  sync.reward = [ mat_reward_sync(:), current_plex_reward(:) ];
  sync.plex_sync = [ mat_sync(:), current_plex_sync(:) ];
  sync.sync_key = { 'mat', 'plex' };
  
  for j = 1:numel(copy_fields)
    sync.(copy_fields{j}) = unified.(first).(copy_fields{j});
  end
  
  shared_utils.io.require_dir( save_p );
  save( output_filename, 'sync' );
end

end