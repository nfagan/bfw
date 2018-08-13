function events_to_plex_time(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

event_p = bfw.get_intermediate_directory( 'events', conf );
sync_p = bfw.get_intermediate_directory( 'sync', conf );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

adjustment_name = 'to_plex_time';

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  
  if ( events.adjustments.isKey(adjustment_name) )
    fprintf( '\n "%s" is already in plexon time.', events.unified_filename );
    continue;
  end
  
  sync_file = fullfile( sync_p, events.unified_filename );
  
  if ( ~shared_utils.io.fexists(sync_file) )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  
  %   convert event times in matlab time (a) to plexon time (b)
  clock_a = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  clock_b = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  
  for j = 1:numel(events.times)
    ct = events.times{j};
    events.times{j} = bfw.clock_a_to_b( ct, clock_a, clock_b );
  end
  
  events.adjustments(adjustment_name) = params;
  
  save( event_files{i}, 'events' );
end

end