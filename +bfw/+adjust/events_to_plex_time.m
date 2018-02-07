function events_to_plex_time(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  unified = fload( fullfile(unified_p, events.unified_filename) );
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  full_filename = fullfile( spike_save_p, events.unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, allow_overwrite) ), continue; end
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  
  %   convert spike times in plexon time (a) to matlab time (b)
  clock_a = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  clock_b = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  
  C = bfw.allcomb( {rois, monks} );
  
  %   then get spike info
  
  N = size(C, 1);
  
  for j = 1:N
    fprintf( '\n\t %d of %d', j, N );
    
    roi = C{j, 1};
    monk = C{j, 2};
    
    row = events.roi_key(roi);
    col = events.monk_key(monk);
    
    unified_filename = spikes.unified_filename;
    mat_directory_name = unified.m1.mat_directory_name;
    
    event_times = events.times{row, col};
    event_ids = events.identifiers{row, col};
    looked_first_indices = events.looked_first_indices{row, 1};
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    event_times = bfw.clock_a_to_b( event_times, clock_b, clock_a );
    
    %   discard events that occur before the first spike, or after the
    %   last spike
    in_bounds_evts = event_times >= mat_spikes(1) & event_times <= mat_spikes(end);
    
    event_times = event_times( in_bounds_evts );
    event_ids = event_ids( in_bounds_evts );
    
    if ( strcmp(monk, 'mutual') )
      looked_first_indices = looked_first_indices( in_bounds_evts );
    else
      looked_first_indices = NaN;
    end    
    
  end
  
  shared_utils.io.require_dir( spike_save_p );
  
  do_save( full_filename, spike_struct );
end

end