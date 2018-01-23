event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
event_files = shared_utils.io.find( event_p, '.mat' );

cont = Container();

for i = 1
  events = shared_utils.io.fload( event_files{i} );
  unified = shared_utils.io.fload( fullfile(unified_p, events.unified_filename) );
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = shared_utils.io.fload( sync_file );
  spikes = shared_utils.io.fload( spike_file );
  
  event_times = events.times;
  
  for j = 1:size(event_times, 1)
        
  end
end