function make_cs_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

data_root = conf.PATHS.data_root;

isd = params.input_subdir;
osd = params.output_subdir;
mid = params.cs_monk_id;

cs_unified_p = bfw.get_intermediate_directory( fullfile('cs_unified', mid, isd), conf );
unified_p = bfw.get_intermediate_directory( fullfile('unified', isd), conf );
save_p = bfw.get_intermediate_directory( fullfile('cs_sync', mid, osd), conf );

mats = bfw.require_intermediate_mats( params.files, cs_unified_p, params.files_containing );

pl2_map = bfw.get_plex_channel_map();

copy_fields = { 'plex_filename', 'plex_directory' };

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  cs_unified = shared_utils.io.fload( mats{i} );
  unified = shared_utils.io.fload( fullfile(unified_p, cs_unified.unified_filename) );
  
  sync_id = unified.m1.plex_sync_id;
  
  first = sync_id;
  
  unified_filename = cs_unified.cs_unified_filename;
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
  
  sync_index = cs_unified.plex_sync_index;
  
  if ( sync_index < 1 || sync_index > numel(binned_sync) )
    warning( 'Sync index for "%s" must be > 1 and <= %d; was %d.' ...
      , mats{i}, numel(binned_sync), sync_index ); 
    continue;
  end
  
  id_times = (0:numel(sync_pulse_raw.Values)-1) .* (1/sync_pulse_raw.ADFreq);
  
  current_plex_sync = binned_sync{sync_index};
  current_plex_start = start_pulses(sync_index);
  
  if ( numel(current_plex_sync) == 0 )
    error( 'No sync times were found for "%s" and index %d. Check your plex_sync_map.json file.' ...
      , mats{i}, sync_index );
  end
  
  mat_sync = cs_unified.data.sync.sync_times(1:cs_unified.data.sync.sync_stp-1);
  assert( numel(mat_sync) == numel(current_plex_sync), ['Mismatch between' ...
    , ' number of plex sync and mat sync pulses.'] );
  
  current_plex_sync = arrayfun( @(x) id_times(x), current_plex_sync );
  
  sync = struct();
  
  sync.plex_sync = [ mat_sync(:), current_plex_sync(:) ];
  sync.sync_key = { 'mat', 'plex' };
  
  for j = 1:numel(copy_fields)
    sync.(copy_fields{j}) = unified.(first).(copy_fields{j});
  end
  
  sync.cs_unified_filename = cs_unified.cs_unified_filename;
  
  shared_utils.io.require_dir( save_p );
  save( output_filename, 'sync' );
end

end