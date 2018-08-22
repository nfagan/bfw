import shared_utils.io.fload;

conf = bfw.config.load();

% extract information from "intermediate" folders, these data have already
% been extracted by bfw function. (e.g bfw.make_spikes, bfw.make_events), they generated intermediate files.
% stored in .../data/brains/free_viewing/intermediates/...
event_p = bfw.get_intermediate_directory( 'events' );
unified_p = bfw.get_intermediate_directory( 'unified' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );
sync_p = bfw.get_intermediate_directory( 'sync' );
spike_p = bfw.get_intermediate_directory( 'spikes' );
event_files = shared_utils.io.find( event_p, '.mat' );

psth = Container();
evt_info = Container();
all_event_lengths = Container();
all_event_times = Container();
all_spike_times = Container();
rasters = Container();

spike_map = containers.Map();

look_back = -0.5;
look_ahead = 0.5;
spike_bin_size = 0.1; % 100 ms

fs = 1e3; % not sure what this is

% I should probably do some visualization here.
% for i = 1:numel(event_files)
for i = 1:2
  fprintf( '\n %d of %d', i, numel(event_files) );
  
  events = fload( event_files{i} );
  % documents for "event" variable
  % times: event start time 
  % durations: length of event in ms scale, not sure what is lengths(seem redundant)
  % params : duration = 30, we have 10ms bin, we define 3 consecutive bins
  %          as start of an event
  %          mutual_method = 'plus-minus' or 'duration', the method used to
  %          smooth the event, it looked for the window defined by plus_minus_duration. 
  % make an event graph
  % relevant function: plot_psth make_spikes
  
  unified = fload( fullfile(unified_p, events.unified_filename) );
  % documents for "unified" variable (seemed to be a file, every time info
  % stored here.
  % plex_sync_times: clock in plexon?
  % sync_times: clocks for two monkeys, they are matlab clocks?
  % reward_sync_times: 
  % position: eye tracker position?
  % time: eye tracker time
  % mat_index: ?
  % plex_sync_index: ?
  plex_file = unified.m1.plex_filename;
  
  sync_file = fullfile( sync_p, events.unified_filename );
  spike_file = fullfile( spike_p, events.unified_filename );
  
  if ( exist(sync_file, 'file') == 0 || exist(spike_file, 'file') == 0 )
    fprintf( '\n Missing sync or spike file for "%s".', events.unified_filename );
    continue;
  end
  
  sync = fload( sync_file );
  % what is this? different from "unified"
  spikes = fload( spike_file ); 
  % seemed like a table of selected units for analysis  
  % should plot spike trains 
  
  if ( ~spikes.is_link )
    spike_map( plex_file ) = spikes;
  elseif ( ~spike_map.isKey(plex_file) )
    spikes = fload( fullfile(spike_p, spikes.data_file) );
    spike_map( plex_file ) = spikes;
  else
    spikes = spike_map( plex_file );  % why? should assign spikes variable to spike_map
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
  
  for j = 1:size(C1,1)
    roi = C1{j, 1};
    monk = C1{j, 2};
    row = events.roi_key( roi );
    col = events.monk_key( monk );
    
    evts = events.times{row, col};
%     evt_lengths = events.lengths{row, col}; % to seconds
    evt_lengths = events.durations{row, col};
    
    evt_lengths = Container( evt_lengths(:) ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified.m1.unified_filename ...
      , 'session_name', unified.m1.mat_directory_name ...
      , 'meas_type', 'undefined' ...
    );
    
    all_event_lengths = all_event_lengths.append( evt_lengths );
    all_event_times = all_event_times.append( set_data(evt_lengths, evts(:)) );
    
  end
  
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
    
    unit_start = unit.start; % is this determined by spike sorting?
    unit_stop = unit.stop;
    spike_times = unit.times;
    channel_str = unit.channel_str;
    region = unit.region;
    unit_name = unit.name;
    % unified_filename = spikes.unified_filename;
    unified_filename = unified.m1.unified_filename;
    mat_directory_name = unified.m1.mat_directory_name;
    
    event_times = events.times{row, col};
    
    if ( isempty(event_times) || isempty(spike_times) ), continue; end
    
    if ( unit_start == -1 ), unit_start = spike_times(1); end
    if ( unit_stop == -1 ), unit_stop = spike_times(end); end
    
    within_time_bounds = spike_times >= unit_start & spike_times <= unit_stop;
    
    spike_times = spike_times(within_time_bounds);
    
    if ( isempty(spike_times) ), continue; end
    
    mat_spikes = bfw.clock_a_to_b( spike_times, clock_a, clock_b );
    
    [raw_psth, bint] = looplessPSTH( mat_spikes, event_times, look_back, look_ahead, 0.1 );
%     raw_psth = zeros( 1, 2 );
    raster = bfw.make_raster( mat_spikes, event_times, look_back, look_ahead, fs );
    
    n_events = numel( event_times );
    
    cont_ = Container( raw_psth, ...
        'channel', channel_str ...
      , 'region', region ...
      , 'unit_name', unit_name ...
      , 'looks_to', roi ...
      , 'looks_by', monk ...
      , 'unified_filename', unified_filename ...
      , 'session_name', mat_directory_name ...
      , 'n_events', sprintf( 'n_events__%d', n_events ) ...
      );
    
    all_spike_times = all_spike_times.append( set_data(cont_, {mat_spikes}) );
    
    psth = psth.append( cont_ );
    
    unqs = cont_.field_label_pairs();
    
    rasters = rasters.append( Container(raster, unqs{:}) );
  end
  
end

%   make units unique

psth = psth.require_fields( 'unit_id' );
[I, C] = psth.get_indices( {'channel', 'region', 'unit_name', 'session_name'} );
for i = 1:numel(I)
  psth('unit_id', I{i}) = sprintf( 'unit__%d', i );
end
rasters = rasters.require_fields( 'unit_id' );
for i = 1:size(C, 1)
  ind = rasters.where(C(i, :));
  rasters('unit_id', ind) = sprintf( 'unit__%d', i );
end
all_spike_times = all_spike_times.require_fields( 'unit_id' );
for i = 1:size(C, 1)
  ind = all_spike_times.where(C(i, :));
  all_spike_times('unit_id', ind) = sprintf( 'unit__%d', i );
end
%%

all_runs = all_spike_times( 'unified_filename' );

one_run = all_runs{1};

one_run_events = all_event_times.only( one_run );
one_run_spikes = all_spike_times.only( one_run );

one_run_eye_m1_events = all_event_times.only( {one_run, 'eyes', 'm1'} );

one_run_unit_ids = one_day_spikes( 'unit_id' );

one_run_unit = one_day_spikes( {one_run_unit_ids{1}, 'eyes', 'm1'} );

one_run_unit = one_run_unit(1);

%%

[I, C] = all_spike_times.get_indices( {'unit_id', 'unified_filename'} );

for i = 1:size(C, 1)
  one_unit = all_spike_times.only( C(i, :) );
  one_unit = one_unit(1);
  
  session_name = one_unit( 'unified_filename' );
  
  one_session_events = all_event_times.only( session_name );
  one_session_lengths = all_event_lengths.only( session_name );
  
  [all_event_indices, all_event_combination] = one_session_events.get_indices( {'looks_to', 'looks_by', 'unified_filename'} );
  
  for j = 1:numel(all_event_indices)
    
    unique_events = one_session_events( all_event_indices{j} );
    unique_event_lengths = one_session_lengths.only( all_event_combination(j, :) );
    
  end
end



