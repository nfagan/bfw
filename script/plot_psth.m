event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
event_files = shared_utils.io.find( event_p, '.mat' );

cont = Container();

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
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
  
  %   convert spike times in plexon time (a) to matlab time (b)
  clock_a = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  clock_b = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  unit_indices = arrayfun( @(x) x, 1:numel(spikes.data), 'un', false );
  
  C = bfw.allcomb( {rois, monks, unit_indices} );
  
  N = size(C, 1);
%   N = 1;
  
  for j = 1:N
    roi = C{j, 1};
    monk = C{j, 2};
    unit_index = C{j, 3};
    
    row = events.roi_key(roi);
    col = events.monk_key(monk);
    
    unit = spikes.data(unit_index);
    
    spike_times = unit.times;
    channel_str = unit.channel_str;
    region = unit.region;
    unified_filename = spikes.unified_filename;
    
    event_times = events.times{row, col};
    
    if ( isempty(event_times) )
      continue;
    end
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    [psth, bint] = looplessPSTH( mat_spikes, event_times, -1, 1, 0.1 );
    
    cont_ = Container( psth, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      );
    
    cont = cont.append( cont_ );
  end
end

%%

pl = ContainerPlotter();
pl.x = bint;
pl.vertical_lines_at = 0;
pl.add_ribbon = true;

figure(1); clf();

plt = cont({'eyes'});

plt.plot( pl, 'looks_to', 'looks_by' );