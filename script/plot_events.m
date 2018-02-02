import shared_utils.io.fload;

conf = bfw.config.load();

event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );

% event_files = shared_utils.io.find( event_p, '.mat' );
event_files = { fullfile(event_p, 'test_position_1.mat') };

first_event_file = fload( event_files{1} );
first_bounds_file = fload( fullfile(bounds_p, first_event_file.unified_filename) );
first_event_params = first_event_file.params;

save_plot_p = fullfile( conf.PATHS.data_root, 'plots' );

look_save_p = fullfile( save_plot_p, 'looking_behavior', datestr(now, 'mmddyy') );

event_param_str = sprintf( 'event_%s_%d', first_event_params.mutual_method, first_event_params.duration );
window_param_str = sprintf( 'window_%d_step_%d', first_bounds_file.window_size, first_bounds_file.step_size );
event_subdir = sprintf( '%s_%s', event_param_str, window_param_str );

look_save_p = fullfile( look_save_p, event_subdir );

shared_utils.io.require_dir( look_save_p );

evt_info = Container();
all_event_lengths = Container();
all_event_distances = Container();

spike_map = containers.Map();

upper_distance_threshold = 1; % longest time allowed between events
lower_distance_threshold = 100 / 1e3;  % shortest time between events, ms

for i = 1:numel(event_files)
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  unified = fload( fullfile(unified_p, events.unified_filename) );
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  
  C1 = bfw.allcomb( {rois, monks} );
  
  %   first get event info
  
  for j = 1:size(C1, 1)
    roi = C1{j, 1};
    monk = C1{j, 2};
    row = events.roi_key( roi );
    col = events.monk_key( monk );
    
    evts = events.times{row, col};
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
    min_evt_length = min( evt_lengths );
    dev_evt_length = std( evt_lengths );
    
    if ( isempty(min_evt_distance) ), min_evt_distance = NaN; end
    if ( isempty(max_evt_distance) ), max_evt_distance = NaN; end
    if ( isempty(min_evt_length) ), min_evt_length = NaN; end
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
    cont3 = Container( min_evt_length, labs );
    
    conts2 = extend( cont1, cont2, cont3 );
    conts2('meas_type') = { 'median_length', 'max_length', 'min_length' };
    
    evt_info = evt_info.extend( conts, conts2 );
    
    pairs = cont1.field_label_pairs();
    
    all_event_lengths = all_event_lengths.append( Container(evt_lengths(:), pairs{:}) );
    all_event_distances = all_event_distances.append( Container(evt_distances(:), pairs{:}) );
  end
  
end

%%  plot histogram of event lengths

pl = ContainerPlotter();

panels_are = { 'looks_to', 'looks_by' };

figure(1); clf();

pl.hist( all_event_lengths, 500, [], panels_are );

% filename = sprintf( 'event_length_histogram_', filename );
filename = 'event_length_histogram';
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

%%  plot histogram of event distances

pl = ContainerPlotter();

panels_are = { 'looks_to', 'looks_by' };

figure(1); clf();

pl.hist( all_event_distances, 500, [], panels_are );

% filename = sprintf( 'event_length_histogram_', filename );
filename = 'event_distance_histogram';
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

%%  plot bar of event distances

pl = ContainerPlotter();

figure(1); clf(); colormap( 'default' );

plt = all_event_distances;

% pl.summary_function = @min;

plt('unified_filename') = 'a';
plt('session_name') = 'b';

panels_are = { 'unified_filename', 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

meas_types = strjoin( plt('meas_type'), '_' );

filename = sprintf( 'event_distances_%s_%s', filename, meas_types );
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );


%%  event info

pl = ContainerPlotter();

pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;

figure(1); clf(); colormap( 'default' );

plt = evt_info;

% plt = plt({'perc_below_threshold_distance'});
plt = plt({'median_length'});

plt('unified_filename') = 'a';
plt('session_name') = 'b';

panels_are = { 'unified_filename', 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

meas_types = strjoin( plt('meas_type'), '_' );

filename = sprintf( 'event_length_%s_%s', filename, meas_types );
  
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
plt('session_name') = 'b';

panels_are = { 'unified_filename', 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

filename = sprintf( 'n_events_per_session_%s', filename );
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

%%  n events per day

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;

figure(1); clf(); colormap( 'default' );

plt = evt_info;

plt = plt({'n_events'});

plt = plt.each1d( {'session_name', 'meas_type', 'looks_to', 'looks_by'}, @rowops.sum );

plt('unified_filename') = 'a';
plt('session_name') = 'b';

panels_are = { 'session_name', 'meas_type' };
groups_are = { 'looks_to' };
x_is = 'looks_by';

pl.bar( plt, x_is, groups_are, panels_are );

filename = strjoin( plt.flat_uniques(plt.categories()), '_' );

filename = sprintf( 'n_events_per_day_%s', filename );
  
saveas( gcf, fullfile(look_save_p, [filename, '.eps']) );
saveas( gcf, fullfile(look_save_p, [filename, '.png']) );

