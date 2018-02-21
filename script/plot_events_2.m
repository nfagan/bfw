conf = bfw.config.load();

event_mats = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('events_per_day'), [] );
event_p = bfw.get_intermediate_directory( 'events' );

event_info = Container();

got_event_info_keys = false;

for i = 1:numel(event_mats)
  events_file = shared_utils.io.fload( event_mats{i} );
  
  if ( events_file.is_link ), continue; end
  
  event_info = append( event_info, events_file.event_info );
  
  if ( ~got_event_info_keys )
    event_info_key = events_file.event_info_key;
    event_params = shared_utils.io.fload( fullfile(event_p, events_file.unified_filename) );
  end
end

event_param_str = sprintf( 'dur_%d_window_%d_step_%d' ...
  , event_params.params.duration, event_params.window_size, event_params.step_size );

if ( event_params.params.fill_gaps )
  fill_gaps_str = sprintf( 'fill_gaps_dur_%d', event_params.params.fill_gaps_duration );
  event_param_str = sprintf( '%s_%s', event_param_str, fill_gaps_str );
end

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'looking_behavior', datestr(now, 'mmddyy') );
plot_p = fullfile( plot_p, event_param_str );

shared_utils.io.require_dir( plot_p );

conf = bfw.config.load();

%%

subset_event_info = event_info({'m1', 'mutual', 'm2'});

%%

event_times = set_data( subset_event_info, subset_event_info.data(:, event_info_key('times')) );

%%

[I, C] = event_times.get_indices( {'unified_filename', 'looks_to', 'looks_by'} );

event_distances = Container();

for i = 1:numel(I)
  subset = event_times(I{i});
  
  if ( shape(subset, 1) == 1 ), continue; end
  
  distances = diff( subset.data );
  
  event_distances = append( event_distances, Container(distances, one(subset.labels)) );
end

%%

event_counts = subset_event_info.each1d( {'unified_filename', 'looks_to', 'looks_by'}, @(x) size(x, 1) );

summarized_dists = event_distances.each1d( {'looks_to', 'looks_by'}, @rowops.nanmedian );

summarized_counts = event_counts.each1d( {'looks_to', 'looks_by'}, @rowops.nanmedian );

%%  N events

f = figure(1); 

for i = 1:2

pl = ContainerPlotter();

plt = event_counts;

clf( f );

if ( i == 1 )
  plt = plt.each1d( {'looks_to', 'looks_by', 'session_name'}, @rowops.sum );
  append_file = 'per_day';
else
  append_file = 'per_run';
end

pl.y_label = 'Number of events';

plt('session_name') = 'a';

pl.bar( plt, 'looks_by', 'looks_to', 'session_name' );

base_filename = 'n_events';
filename = strjoin( flat_uniques(plt, {'looks_by', 'looks_to'}), '_' );
filename = sprintf( '%s_%s_%s', base_filename, filename, append_file );

shared_utils.plot.save_fig( gcf(), fullfile(plot_p, filename), {'epsc', 'png', 'fig'} );

end

%%  event distances

pl = ContainerPlotter();
figure(1); 
clf();

pl.y_label = 'Event distance (s)';

plt = summarized_dists;
append_file = 'per_day';

plt('session_name') = 'a';

pl.bar( plt, 'looks_by', 'looks_to', 'session_name' );

base_filename = 'event_distances';
filename = strjoin( flat_uniques(plt, {'looks_by', 'looks_to'}), '_' );
filename = sprintf( '%s_%s_%s', base_filename, filename, append_file );

shared_utils.plot.save_fig( gcf(), fullfile(plot_p, filename), {'epsc', 'png', 'fig'} );

