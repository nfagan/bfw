import shared_utils.io.fload;

conf = bfw.config.load();

event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
event_files = shared_utils.io.find( event_p, '.mat' );

save_plot_p = fullfile( conf.PATHS.data_root, 'plots' );

look_save_p = fullfile( save_plot_p, 'looking_behavior', datestr(now, 'mmddyy') );
shared_utils.io.require_dir( look_save_p );

cont = Container();
evt_info = Container();

spike_map = containers.Map();

update_spikes = true;

look_back = -0.5;
look_ahead = 0.5;

fs = 1e3;

upper_distance_threshold = 1; % longest time allowed between events
lower_distance_threshold = 100 / 1e3;  % shortest time between events, ms

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  unified = fload( fullfile(unified_p, events.unified_filename) );
  plex_file = unified.m1.plex_filename;
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  spikes = fload( spike_file );
  
  if ( ~spikes.is_link )
    spike_map( plex_file ) = spikes;
  elseif ( ~spike_map.isKey(plex_file) )
    spikes = fload( fullfile(spike_p, spikes.data_file) );
    spike_map( plex_file ) = spikes;
  else
    spikes = spike_map( plex_file );
  end
  
  %   convert spike times in plexon time (a) to matlab time (b)
  clock_a = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  clock_b = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  unit_indices = arrayfun( @(x) x, 1:numel(spikes.data), 'un', false );
  
  C = bfw.allcomb( {rois, monks, unit_indices} );
  C1 = bfw.allcomb( {rois, monks} );
  
  %   first get event info
  
  for j = 1:size(C1, 1)
    roi = C1{j, 1};
    monk = C1{j, 2};
    row = events.roi_key( roi );
    col = events.monk_key( monk );
    
    evts = events.times{row, col};
%     evt_lengths = events.lengths{row, col}; % to seconds
    evt_lengths = events.durations{row, col};
    
    n_evts = numel( evts );
    
    evt_distances = diff( evts );
    median_evt_distance = median( evt_distances );
    min_evt_distance = min( evt_distances );
    max_evt_distance = max( evt_distances );
    dev_evt_distance = std( evt_distances );
    
    perc_above_threshold_distance = perc( evt_distances(:) >= upper_distance_threshold );
    perc_below_threshold_distance = perc( evt_distances(:) <= lower_distance_threshold );
    
    median_evt_length = median( evt_lengths );
    max_evt_length = max( evt_lengths );
    dev_evt_length = std( evt_lengths );
    
    if ( isempty(min_evt_distance) ), min_evt_distance = NaN; end
    if ( isempty(max_evt_distance) ), max_evt_distance = NaN; end
    if ( isempty(max_evt_length) ), max_evt_length = NaN; end
    
    labs = SparseLabels.create( ...
        'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified.m1.unified_filename ...
      , 'session_name', unified.m1.mat_directory_name ...
      , 'meas_type', 'undefined' ...
    );
    
    cont1 = Container( n_evts, labs );
    cont2 = Container( median_evt_distance, labs );
    cont3 = Container( max_evt_distance, labs );
    cont4 = Container( min_evt_distance, labs );
    cont5 = Container( dev_evt_distance, labs );
    cont6 = Container( perc_above_threshold_distance, labs );
    cont7 = Container( perc_below_threshold_distance, labs );
    
    conts = extend( cont1, cont2, cont3, cont4, cont5, cont6, cont7 );
    conts('meas_type') = { 'n_events', 'median_distance', 'max_distance' ...
      , 'min_distance', 'dev_distance' ...
      , 'perc_above_threshold_distance', 'perc_below_threshold_distance' };
    
    cont1 = Container( median_evt_length, labs );
    cont2 = Container( max_evt_length, labs );
    
    conts2 = extend( cont1, cont2 );
    conts2('meas_type') = { 'median_length', 'max_length' };
    
    evt_info = evt_info.extend( conts, conts2 );
  end
  
  if ( ~update_spikes ), continue; end
  
  %   then get spike info
  
  N = size(C, 1);
%   N = 1;
  
  for j = 1:N
    roi = C{j, 1};
    monk = C{j, 2};
    unit_index = C{j, 3};
    
    row = events.roi_key(roi);
    col = events.monk_key(monk);
    
    unit = spikes.data(unit_index);
    
    unit_start = unit.start;
    unit_stop = unit.stop;
    spike_times = unit.times;
    channel_str = unit.channel_str;
    region = unit.region;
    unit_name = unit.name;
    unified_filename = spikes.unified_filename;
    mat_directory_name = unified.m1.mat_directory_name;    
    
    event_times = events.times{row, col};
    
    if ( isempty(event_times) || isempty(spike_times) ), continue; end
    
    if ( unit_start == -1 ), unit_start = spike_times(1); end
    if ( unit_stop == -1 ), unit_stop = spike_times(end); end
    
    within_time_bounds = spike_times >= unit_start & spike_times <= unit_stop;
    
    spike_times = spike_times(within_time_bounds);
    
    if ( isempty(spike_times) ), continue; end
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    [psth, bint] = looplessPSTH( mat_spikes, event_times, look_back, look_ahead, 0.1 );
    raster = bfw.make_raster( mat_spikes, event_times, look_back, look_ahead, fs );
    
    n_events = numel( event_times );
    
    cont_ = Container( psth, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'unit_name', unit_name ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      , 'session_name', mat_directory_name ...
      , 'n_events', sprintf( 'n_events__%d', n_events ) ...
      );
    
    cont = cont.append( cont_ );
  end
end

if ( update_spikes )
  cont = cont.require_fields( 'unit_id' );
  [I, C] = cont.get_indices( {'channel', 'region', 'unit_name', 'session_name'} );

  for i = 1:numel(I)
    cont('unit_id', I{i}) = sprintf( 'unit__%d', i );
  end
end

%%  event info

pl = ContainerPlotter();

pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;

figure(1); clf(); colormap( 'default' );

plt = evt_info;

% plt = plt({'perc_below_threshold_distance'});
plt = plt({'median_length'});

plt('unified_filename') = 'a';

panels_are = { 'unified_filename', 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

filename = sprintf( 'event_length_%s', filename );
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

%%  n events per session

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;

figure(1); clf(); colormap( 'default' );

plt = evt_info;

plt = plt({'n_events'});
plt('unified_filename') = 'a';

panels_are = { 'unified_filename', 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

filename = sprintf( 'n_events_per_session_%s', filename );
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

%%

pl = ContainerPlotter();
pl.x = bint;
pl.vertical_lines_at = 0;
pl.add_ribbon = true;

figure(1); clf();

plt = cont;

plt = plt({'01162018', '01172018'});

plt = plt({'face', 'bla'});

plt.plot( pl, 'looks_to', 'looks_by' );

%%  per unit

date_dir = datestr( now, 'mmddyy' );

plt = cont({'01162018', '01172018'});

kind = 'per_unit';

save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth' );
save_plot_p = fullfile( save_plot_p, date_dir, kind );

shared_utils.io.require_dir( save_plot_p );

[I, C] = plt.get_indices( {'unit_id'} );

for i = 1:numel(I)
  subset = plt(I{i});
  
  pl.default();
  pl.x = bint;
  pl.vertical_lines_at = 0;
  
  figure(1); clf();
  
  subset.plot( pl, 'looks_to', {'looks_by', 'region', 'unit_id'} );
  
  filename = strjoin( subset.flat_uniques({'region', 'looks_to', 'looks_by', 'unit_id'}), '_' );
  
  saveas( gcf, fullfile(save_plot_p, [filename, '.eps']) );
  saveas( gcf, fullfile(save_plot_p, [filename, '.png']) );
  
end

