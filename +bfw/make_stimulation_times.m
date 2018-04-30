function make_stimulation_times(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'stim' );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

pl2_map = bfw.get_plex_channel_map();

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  unified = shared_utils.io.fload( mats{i} );
  
  sync_id = unified.m1.plex_sync_id;
  
  fields = fieldnames( unified );
  first = sync_id;
  
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
  
  stim_pulse_raw = PL2Ad( pl2_file, pl2_map('stimulation') );
  sham_pulse_raw = PL2Ad( pl2_file, pl2_map('sham_stimulation') );
  start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );
 
  start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );
  stim_pulses = bfw.get_pulse_indices( stim_pulse_raw.Values, 48 );
  sham_pulses = bfw.get_pulse_indices( sham_pulse_raw.Values, 48 );

  binned_stim = bfw.bin_pulses( stim_pulses, start_pulses );
  binned_sham = bfw.bin_pulses( sham_pulses, start_pulses );
  
  sync_index = unified.(first).plex_sync_index;
  
  if ( sync_index < 1 || sync_index > numel(binned_stim) )
    warning( 'Sync index for "%s" must be > 1 and <= %d; was %d.' ...
      , mats{i}, numel(binned_stim), sync_index ); 
    continue;
  end
  
  id_times = (0:numel(stim_pulse_raw.Values)-1) .* (1/stim_pulse_raw.ADFreq);
  
  stim = struct();
  stim.stimulation_times = id_times( binned_stim{sync_index} );
  stim.sham_times = id_times( binned_sham{sync_index} );
  stim.unified_filename = unified_filename;
  
  shared_utils.io.require_dir( save_p );
  
  save( output_filename, 'stim' );
end

end