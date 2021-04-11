function events_file = raw_events(files, varargin)

%   RAW_EVENTS -- Create raw_events file.
%
%     Note that, in the files list below, <fixation> refers to a string
%     that is the subfolder giving the kind of fixations used to make
%     events, and must be a key of `files`.
%
%     See also bfw.make.help, bfw.make_raw_events,
%       bfw.make.defaults.raw_events
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `varargin` ('name', value)
%     FILES:
%       - 'time'
%       - 'bounds'
%       - <fixation>
%     OUT:
%       - `events_file` (struct)

defaults = bfw.make.defaults.raw_events();
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, {'rois', 'time', 'bounds', 'position', params.fixations_subdir} );

roi_file = shared_utils.general.get( files, 'rois' );
time_file = shared_utils.general.get( files, 'time' );
bounds_file = shared_utils.general.get( files, 'bounds' );
pos_file = shared_utils.general.get( files, 'position' );
fix_file = shared_utils.general.get( files, params.fixations_subdir );
  
%   Check whether to adjust the duration to match the given bin size.
if ( isfield(bounds_file.params, 'step_size') )
  step_size = bounds_file.params.step_size;
else  
  step_size = 1;
end

% Save the step size used.
params.step_size = step_size;

if ( params.use_bounds_file_for_rois )
  events_file = bounds_file_roi_method( bounds_file, fix_file, time_file, params );
else
  events_file = roi_file_roi_method( roi_file, pos_file, fix_file, time_file, params );
end

end

function tf = check_has_mutual_events(roi_file, params)

monk_ids = intersect( {'m1', 'm2'}, fieldnames(roi_file) );
tf = params.calculate_mutual && numel( monk_ids ) > 1;

end

function events_file = roi_file_roi_method(roi_file, pos_file, fix_file, time_file, params)

unified_filename = bfw.try_get_unified_filename( time_file );
events_file = empty_events_file( unified_filename, params );

has_mutual_events = check_has_mutual_events( roi_file, params );
[excl_roi_order, mut_roi_order] = params.roi_order_func( roi_file );

t = time_file.t;
step_size = params.step_size;
check_accept_mutual_event_func = params.check_accept_mutual_event_func;

exclusive_evts = find_exclusive_events_roi_method( t, step_size, fix_file, params );

excl_events = linearize_exclusive_evts( exclusive_evts );
excl_labels = fcat.from( excl_events );
m1_ind = find( excl_labels, 'm1' );
m2_ind = find( excl_labels, 'm2' );

% Add empty columns for mutual m1/m2 start/stop
curr_n_cols = size( excl_events.events, 2 );

if ( isempty(excl_events.events) )
  excl_events.events = zeros( 0, curr_n_cols + 4 );
else
  event_cols_copy = { 'start_index', 'stop_index', 'start_index', 'stop_index' };  
  for i = 1:4
    event_col_ind = excl_events.event_key(event_cols_copy{i});
    excl_events.events(:, end+1) = excl_events.events(:, event_col_ind);
  end
end

new_column_ids = { 'm1_source_start_index', 'm1_source_stop_index' ...
  , 'm2_source_start_index', 'm2_source_stop_index' };

for i = 1:4
  excl_events.event_key(new_column_ids{i}) = i + curr_n_cols;
end

starts = excl_events.events(:, excl_events.event_key('start_index'));
stops = excl_events.events(:, excl_events.event_key('stop_index'));
start_stops = [ starts, stops ];

[m1_roi_labels, m1_found_roi] = ...
  check_label_exclusive_events( start_stops, excl_roi_order, roi_file, pos_file, 'm1', m1_ind );
[m2_roi_labels, m2_found_roi] = ...
  check_label_exclusive_events( start_stops, excl_roi_order, roi_file, pos_file, 'm2', m2_ind );

roi_labels = cell( length(excl_labels), 1 );
roi_labels(m1_ind) = m1_roi_labels;
roi_labels(m2_ind) = m2_roi_labels;

m1_excl_roi_labels = cellfun( @(x) get_monk_id_roi_label('m1', x), roi_labels, 'un', 0 );
m2_excl_roi_labels = cellfun( @(x) get_monk_id_roi_label('m2', x), roi_labels, 'un', 0 );

excl_events.labels = [ excl_events.labels, roi_labels, m1_excl_roi_labels, m2_excl_roi_labels ];
excl_events.categories = [ excl_events.categories, {'roi', 'm1_roi', 'm2_roi'} ];

maybe_mutual_m1 = m1_ind(m1_found_roi);
maybe_mutual_m2 = m2_ind(m2_found_roi);

mutual_inputs = struct();
mutual_inputs.duration = params.duration;
mutual_inputs.step_size = params.step_size;
mutual_inputs.allow_keep_initiating_exclusive_event = params.allow_keep_initiating_exclusive_event;
mutual_inputs.mut_m1 = maybe_mutual_m1;
mutual_inputs.mut_m2 = maybe_mutual_m2;
mutual_inputs.roi_order = mut_roi_order;
mutual_inputs.check_accept_mutual_event_func = check_accept_mutual_event_func;

all_keep_exclusive = true( length(excl_labels), 1 );

if ( has_mutual_events )
  mut_outs = handle_mutual_events_roi_method( start_stops, roi_file, pos_file, time_file, mutual_inputs );
  
  if ( params.preserve_pre_032821_incorrect_exclusive_event_removal )
    %{
      pre 03/28/2021 - wrong indices
    %}
    m1_mut_ind = m1_ind(mut_outs.remove_m1);
    m2_mut_ind = m2_ind(mut_outs.remove_m2);
  else
    m1_mut_ind = maybe_mutual_m1(mut_outs.remove_m1);
    m2_mut_ind = maybe_mutual_m2(mut_outs.remove_m2);
  end

  all_keep_exclusive(m1_mut_ind) = false;
  all_keep_exclusive(m2_mut_ind) = false;
  
  adjust_excl_inds = mut_outs.adjust_exclusive_end_inds;
  excl_events.events(adjust_excl_inds, :) = mut_outs.adjusted_exclusive_event_info;
  
  excl_events.events = excl_events.events(all_keep_exclusive, :);
  excl_events.labels = excl_events.labels(all_keep_exclusive, :);
  
  excl_events.events = [ excl_events.events; mut_outs.events ];
  excl_events.labels = [ excl_events.labels; mut_outs.labels ];
end

events_file.events = excl_events.events;
events_file.event_key = excl_events.event_key;
events_file.labels = excl_events.labels;
events_file.categories = excl_events.categories;

if ( ~params.preserve_pre_032821_incorrect_exclusive_event_removal )
  post_process_validate_events( events_file );
end

end

function post_process_validate_events(events_file)

f = fcat.from( events_file.labels, events_file.categories );
roi_ind = rowmask( f );
m1_ind = find( f, 'm1', roi_ind );
m2_ind = find( f, 'm2', roi_ind );
mut_ind = find( f, 'mutual', roi_ind );
m1_s = events_file.events(m1_ind, 1);
m2_s = events_file.events(m2_ind, 1);
mut_s = events_file.events(mut_ind, 1);
assert( isempty(intersect(m2_s, mut_s)), 'mutual event starts contained m2 starts' );
assert( isempty(intersect(m1_s, mut_s)), 'mutual event starts contained m1 starts' );

end

function mut_outs = handle_mutual_events_roi_method(start_stops, roi_file, pos_file, time_file, mutual_inputs)

roi_order = mutual_inputs.roi_order;
check_accept_mutual_event_func = mutual_inputs.check_accept_mutual_event_func;
allow_keep_initiating_exclusive_event = mutual_inputs.allow_keep_initiating_exclusive_event;

t = time_file.t;
duration_crit = ceil( mutual_inputs.duration / mutual_inputs.step_size );

m1_ind = mutual_inputs.mut_m1;
m2_ind = mutual_inputs.mut_m2;

m1_pos = pos_file.m1;
m2_pos = pos_file.m2;

m1_rects = cellfun( @(x) roi_file.m1.rects(x), roi_order, 'un', 0 );
m2_rects = cellfun( @(x) roi_file.m2.rects(x), roi_order, 'un', 0 );

n_m1 = numel( m1_ind );
n_m2 = numel( m2_ind );
use_n = max( n_m1, n_m2 );

if ( use_n == n_m1 )
  src_is_m1 = true;
  
  src_monk_id = 'm1';
  test_monk_id = 'm2';
  
  src_inds = m1_ind;
  test_inds = m2_ind;
  
  src_pos = m1_pos;
  test_pos = m2_pos;
  
  src_rects = m1_rects;
  test_rects = m2_rects;
  
  src_rect_map = roi_file.m1.rects;
  test_rect_map = roi_file.m2.rects;
else
  src_is_m1 = false;
  
  src_monk_id = 'm2';
  test_monk_id = 'm1';
  
  src_inds = m2_ind;
  test_inds = m1_ind;
  
  src_pos = m2_pos;
  test_pos = m1_pos;
  
  src_rects = m2_rects;
  test_rects = m1_rects;
  
  src_rect_map = roi_file.m2.rects;
  test_rect_map = roi_file.m1.rects;
end

keep_exclusive_src = true( use_n, 1 );
keep_exclusive_test = true( numel(test_inds), 1 );

mutual_event_labels = {};
mutual_event_info = [];

adjust_exclusive_end_inds = [];
adjust_exclusive_ends = [];

for i = 1:use_n
  src_ind = src_inds(i);
  src_range = start_stops(src_ind, 1):start_stops(src_ind, 2);
  
  for j = 1:numel(test_inds)    
    test_ind = test_inds(j);
    test_range = start_stops(test_ind, 1):start_stops(test_ind, 2);
    
    overlap_range = intersect( src_range, test_range );
    overlaps = numel( overlap_range ) >= duration_crit;
    
    if ( ~overlaps )
      continue;
    end
    
    src_p = nanmean( src_pos(:, src_range), 2 );
    test_p = nanmean( test_pos(:, test_range), 2 );

    ib_src = cellfun( ...
      @(x) bfw.bounds.rect(src_p(1), src_p(2), x), src_rects );
    ib_test = cellfun( ...
      @(x) bfw.bounds.rect(test_p(1), test_p(2), x), test_rects );

    % First mutual in given roi order.
    ib_both = find( ib_src & ib_test, 1 );
    
    accept = false;

    if ( ~isempty(ib_both) )
      mut_roi = roi_order{ib_both};
      src_roi_label = mut_roi;
      test_roi_label = mut_roi;
      accept = true;
      
    elseif ( any(ib_src) && any(ib_test) )
      [accept, tmp_roi_label, src_roi_label, test_roi_label] = ...
        check_accept_mutual_event_func( src_p, test_p, src_rect_map, test_rect_map );
      
      if ( accept )
        mut_roi = tmp_roi_label;
      end
    end
    
    if ( ~accept )
      continue;
    end

    min_src = min( src_range );
    min_test = min( test_range );
    max_src = max( src_range );
    max_test = max( test_range );

    mut_start = min( overlap_range );
    mut_stop = max( overlap_range );
    
    can_keep_src = false;
    can_keep_test = false;

    if ( min_src == min_test )
      initiator = 'simultaneous';
      
    elseif ( min_src < min_test )
      initiator = src_monk_id;
      
      if ( allow_keep_initiating_exclusive_event )
        % src event start preceded test event start. So truncate the src
        % exclusive event to the start of the mutual event
        [can_keep_src, adjust_exclusive_end_inds, adjust_exclusive_ends] = ...
          check_update_adjusted_exclusive_ends( adjust_exclusive_end_inds ...
          , adjust_exclusive_ends, src_ind, min_src, min_test, duration_crit );
      end
    else
      initiator = test_monk_id;
      
      if ( allow_keep_initiating_exclusive_event )
        % test event start preceded src event start. So truncate the test
        % exclusive event to the start of the mutual event
        [can_keep_test, adjust_exclusive_end_inds, adjust_exclusive_ends] = ...
          check_update_adjusted_exclusive_ends( adjust_exclusive_end_inds ...
          , adjust_exclusive_ends, test_ind, min_test, min_src, duration_crit );
      end
    end

    if ( max_src == max_test )
      terminator = 'simultaneous';
    elseif ( max_src < max_test )
      terminator = src_monk_id;
    else
      terminator = test_monk_id;
    end
    
    keep_exclusive_src(i) = can_keep_src;
    keep_exclusive_test(j) = can_keep_test;

    initiator_label = get_initiated_label( initiator );
    terminator_label = get_terminated_label( terminator );
    
    if ( ~src_is_m1 )
      % Swap
      tmp_src_label = src_roi_label;
      src_roi_label = test_roi_label;
      test_roi_label = tmp_src_label;
    end
    
    if ( src_is_m1 )
      m1_start_ind = src_range(1);
      m1_stop_ind = src_range(end);
      m2_start_ind = test_range(1);
      m2_stop_ind = test_range(end);
    else
      m1_start_ind = test_range(1);
      m1_stop_ind = test_range(end);
      m2_start_ind = src_range(1);
      m2_stop_ind = src_range(end);
    end
    
    m1_roi_label = get_monk_id_roi_label( 'm1', src_roi_label );
    m2_roi_label = get_monk_id_roi_label( 'm2', test_roi_label );
    
    mutual_event_labels(end+1, :) = {...
      'mutual', initiator_label, terminator_label, 'mutual_event', mut_roi ...
      , m1_roi_label, m2_roi_label ...
    };
  
    mutual_event_info(end+1, :) = [ make_event_info(mut_start, mut_stop, t) ...
      , m1_start_ind, m1_stop_ind, m2_start_ind, m2_stop_ind ];
  end
end

if ( ~isempty(mutual_event_info) )
  intersect_m1_starts = intersect( start_stops(m1_ind, 1), mutual_event_info(:, 1) );
  intersect_m2_starts = intersect( start_stops(m2_ind, 1), mutual_event_info(:, 1) );
  [~, m1_intersect_ind] = ismember( intersect_m1_starts, start_stops(m1_ind, 1) );
  [~, m2_intersect_ind] = ismember( intersect_m2_starts, start_stops(m2_ind, 1) );
  if ( src_is_m1 )
    assert( ~any(keep_exclusive_src(m1_intersect_ind)), 'm1 intersected' );
    assert( ~any(keep_exclusive_test(m2_intersect_ind)), 'm2 intersected' );
  else
    assert( ~any(keep_exclusive_test(m1_intersect_ind)), 'm1 intersected' );
    assert( ~any(keep_exclusive_src(m2_intersect_ind)), 'm2 intersected' );
  end
end

mut_outs = struct();
mut_outs.events = mutual_event_info;
mut_outs.labels = mutual_event_labels;
mut_outs.categories = {'looks_by', 'initiator', 'terminator', 'event_type' ...
  , 'roi', 'm1_roi', 'm2_roi'};

if ( src_is_m1 )
  mut_outs.remove_m1 = ~keep_exclusive_src;
  mut_outs.remove_m2 = ~keep_exclusive_test;
else
  mut_outs.remove_m1 = ~keep_exclusive_test;
  mut_outs.remove_m2 = ~keep_exclusive_src;
end

adjusted_exclusive_event_info = ...
  make_adjusted_exclusive_event_info( adjust_exclusive_end_inds ...
  , adjust_exclusive_ends, start_stops, t );

mut_outs.adjust_exclusive_end_inds = adjust_exclusive_end_inds;
mut_outs.adjusted_exclusive_event_info = adjusted_exclusive_event_info;

end

function event_info = make_adjusted_exclusive_event_info(end_inds, ends, start_stops, t)

assert( numel(unique(end_inds)) == numel(ends), 'Duplicate exclusive end.' );

event_info = zeros( numel(end_inds), 6 );

for i = 1:numel(end_inds)
  adjust_end_ind = end_inds(i);
  
  start = start_stops(adjust_end_ind, 1);
  stop = ends(i);
  
  event_info(i, :) = make_event_info( start, stop, t );
end

end

function [can_keep, end_inds, ends] = ...
  check_update_adjusted_exclusive_ends(end_inds, ends, excl_start_ind, excl_start, mut_start, duration_crit)

[already_marked, marked_ind] = ismember( excl_start_ind, end_inds );
new_excl_end = mut_start - 1;

if ( already_marked )
  new_excl_end = min( new_excl_end, ends(marked_ind) );
end

can_keep = new_excl_end - excl_start + 1 >= duration_crit;

if ( can_keep )
  if ( already_marked )
    ends(marked_ind) = new_excl_end;
  else
    end_inds(end+1) = excl_start_ind;
    ends(end+1) = new_excl_end;
  end
elseif ( already_marked )
  end_inds(marked_ind) = [];
  ends(marked_ind) = [];
end

end

function evt_info = make_event_info(start_ind, stop_ind, t)

evt_length = stop_ind - start_ind + 1;

start_t = t(start_ind);
stop_t = t(stop_ind);

duration = stop_t - start_t;

evt_info = [ start_ind, stop_ind, evt_length, start_t, stop_t, duration ];

end

function [roi_labels, found_roi] = ...
  check_label_exclusive_events(start_stops, roi_order, roi_file, pos_file, monk_id, mask)

if ( ~isempty(mask) )
  rects = roi_file.(monk_id).rects;
  pos = pos_file.(monk_id);
  m_start_stops = start_stops(mask, :);
  
  [roi_labels, found_roi] = label_exclusive_events( m_start_stops, roi_order, rects, pos );
else
  roi_labels = {};
  found_roi = [];
end

end

function out = linearize_exclusive_evts(events)

monk_ids = fieldnames( events );
looks_by = cell( size(monk_ids) );
initiators = cell( size(monk_ids) );
terminators = cell( size(monk_ids) );
evts = cell( size(looks_by) );

for i = 1:numel(monk_ids)
  event = events.(monk_ids{i});
  num_events = size( event.events, 1 );
  label_size = [num_events, 1];
  
  m_id = monk_ids{i};
  
  looks_by{i} = repmat( {m_id}, label_size );
  initiators{i} = repmat( {get_initiated_label(m_id)}, label_size );
  terminators{i} = repmat( {get_terminated_label(m_id)}, label_size );
  
  evts{i} = event.events;
end

looks_by = vertcat( looks_by{:} );
initiators = vertcat( initiators{:} );
terminators = vertcat( terminators{:} );
event_types = repmat( {'exclusive_event'}, size(looks_by) );

out = struct();
out.events = vertcat( evts{:} );
out.event_key = events.(monk_ids{i}).event_key;
out.labels = [ looks_by, initiators, terminators, event_types ];
out.categories = { 'looks_by', 'initiator', 'terminator', 'event_type' };

end

function roi_labels = label_rois_for_joined_events(joined, roi_file, pos_file ...
  , roi_order, check_accept_mutual_event_func)

joined_labels = fcat.from( joined );
roi_labels = cell( size(joined_labels, 1), 1 );

m1_ind = find( joined_labels, 'm1' );
m2_ind = find( joined_labels, 'm2' );
mut_ind = find( joined_labels, 'mutual' );

start_indices = joined.events(:, joined.event_key('start_index'));
stop_indices = joined.events(:, joined.event_key('stop_index'));
start_stop_indices = [ start_indices, stop_indices ];

if ( isempty(m1_ind) )
  m1_roi_labels = {};
else
  m1_roi_labels = label_exclusive_events( ...
    start_stop_indices(m1_ind, :), roi_order, roi_file.m1.rects, pos_file.m1 );
end

if ( isempty(m2_ind) )
  m2_roi_labels = {};
else
  m2_roi_labels = label_exclusive_events( ...
    start_stop_indices(m2_ind, :), roi_order, roi_file.m2.rects, pos_file.m2 );
end

if ( isempty(mut_ind) )
  mutual_roi_labels = {};
else
  mutual_roi_labels = label_mutual_events( ...
    start_stop_indices(mut_ind, :), roi_order, check_accept_mutual_event_func ...
    , roi_file.m1.rects, roi_file.m2.rects ...
    , pos_file.m1, pos_file.m2 );
end

roi_labels(m1_ind) = m1_roi_labels;
roi_labels(m2_ind) = m2_roi_labels;
roi_labels(mut_ind) = mutual_roi_labels;

end

function roi_labels = ...
  label_mutual_events(start_stop_indices, roi_order, check_accept_mutual_event_func ...
  , m1_rects, m2_rects, m1_pos, m2_pos)

num_events = size( start_stop_indices, 1 );
roi_labels = cell( num_events, 1 );

for i = 1:num_events
  start = start_stop_indices(i, 1);
  stop = start_stop_indices(i, 2);
  
  m1p = nanmean( m1_pos(:, start:stop), 2 );
  m2p = nanmean( m2_pos(:, start:stop), 2 );
  
  roi_label = 'everywhere';
  found_roi = false;
  
  for j = 1:numel(roi_order)
    roi = roi_order{j};
    ib_m1 = bfw.bounds.rect( m1p(1), m1p(2), m1_rects(roi) );
    ib_m2 = bfw.bounds.rect( m2p(1), m2p(2), m2_rects(roi) );
    
    if ( ib_m1 && ib_m2 )
      found_roi = true;
      roi_label = roi;
      break;
    end
  end
  
  if ( ~found_roi )
    [accept, tmp_label] = check_accept_mutual_event_func( m1p, m2p, m1_rects, m2_rects );
    if ( accept )
      roi_label = tmp_label;
    end
  end
  
  roi_labels{i} = roi_label;
end

end

function [roi_labels, found_roi] = ...
  label_exclusive_events(start_stop_indices, roi_order, rects, position)

num_events = size( start_stop_indices, 1 );
roi_labels = cell( num_events, 1 );
found_roi = false( size(roi_labels) );

for i = 1:num_events
  start = start_stop_indices(i, 1);
  stop = start_stop_indices(i, 2);
  
  pos = position(:, start:stop);
  mean_pos = nanmean( pos, 2 );
  curr_found_roi = false;
  
  roi_label = 'everywhere';
  
  for j = 1:numel(roi_order)
    rect = rects(roi_order{j});
    ib = bfw.bounds.rect( mean_pos(1), mean_pos(2), rect );
    
    if ( ib )
      roi_label = roi_order{j};
      curr_found_roi = true;
      break;
    end
  end
  
  roi_labels{i} = roi_label;
  found_roi(i) = curr_found_roi;
end

end

function events_file = ...
  bounds_file_roi_method(bounds_file, fix_file, time_file, params)

unified_filename = bfw.try_get_unified_filename( time_file );

t = time_file.t;
step_size = params.step_size;

monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
% Set of roi names that can be manually selected.
possible_roi_names = keys( bounds_file.(monk_ids{1}) );
% Set of roi names that *will* be used to make events.
[active_roi_names, is_all_rois] = get_active_roi_names( possible_roi_names, params.rois );

% Get the events_file struct in which data will be stored
events_file = get_base_events_file( unified_filename, active_roi_names, is_all_rois, params );

has_mutual_events = params.calculate_mutual && numel( monk_ids ) > 1;
mutual_evts = [];

for i = 1:numel(active_roi_names)
  roi_name = active_roi_names{i};

  exclusive_evts = find_exclusive_events_bounds_method( roi_name, t, step_size, bounds_file, fix_file, params );

  if ( has_mutual_events )
    mutual_evts = find_mutual_events( t, step_size, exclusive_evts, params ); 
  end

  joined = join_events( exclusive_evts, mutual_evts, params );
  repeated_roi = repmat( {roi_name}, rows(joined.events), 1 );

  events_file.events = [ events_file.events; joined.events ];
  events_file.labels = [ events_file.labels; [joined.labels, repeated_roi] ];

  if ( i == 1 )
    events_file.event_key = joined.event_key;
    events_file.categories = cshorzcat( joined.categories, 'roi' );
  end
end

end

function outs = join_events(exclusive, mutual, params)

monk_ids = intersect( {'m1', 'm2'}, fieldnames(exclusive) );

all_event_info = [];
labels = {};

if ( ~isempty(mutual) )
  %   Ensure that exclusive events are not also contained in mutual events
  %   (i.e., that exclusive events are truly exclusive)
  [mutual_labels, exclusive] = reconcile_mutual_exclusive( mutual, exclusive, monk_ids, params );
  
  all_event_info = mutual.events;
  looks_by = repmat( {'mutual'}, rows(all_event_info), 1 );
  event_type = repmat( {'mutual_event'}, size(looks_by) );
  
  progenitor_ids = mutual_labels.progenitor_ids;
  broke_ids = mutual_labels.broke_ids;
  
  labels = [ labels; [looks_by, progenitor_ids, broke_ids, event_type] ];
end

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  event_info = exclusive.(monk_id).events;
  
  looks_by = repmat( monk_ids(i), rows(event_info), 1 );
  progenitor_ids = repmat( {get_initiated_label(monk_id)}, size(looks_by) );
  broke_ids = repmat( {get_terminated_label(monk_id)}, size(looks_by) );
  event_type = repmat( {'exclusive_event'}, size(looks_by) );
  
  all_event_info = [ all_event_info; event_info ];
  labels = [ labels; [looks_by, progenitor_ids, broke_ids, event_type] ];
end

outs = struct();
outs.events = all_event_info;
outs.event_key = exclusive.(monk_ids{1}).event_key;
outs.labels = labels;
outs.categories = { 'looks_by', 'initiator', 'terminator', 'event_type' };

end

function l = get_monk_id_roi_label(m_id, roi_name)
l = sprintf( '%s_%s', m_id, roi_name );
end

function l = get_initiated_label(m_id)
l = sprintf( '%s_initiated', m_id );
end

function l = get_terminated_label(m_id)
l = sprintf( '%s_terminated', m_id );
end

function [labels, exclusive] = reconcile_mutual_exclusive(mutual, exclusive, monk_ids, params)

mut_evt_starts = mutual.events(:, mutual.event_key('start_index'));
mut_evt_stops = mutual.events(:, mutual.event_key('stop_index'));

progenitor_ids = cell( numel(mut_evt_starts), 1 );
broke_ids = cell( size(progenitor_ids) );

matches_start = false( numel(mut_evt_starts), numel(monk_ids) );
matches_stop = false( size(matches_start) );

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  excl = exclusive.(monk_id);
  start_col_idx = excl.event_key('start_index');
  stop_col_idx = excl.event_key('stop_index');
  
  start_indices = excl.events(:, start_col_idx);
  stop_indices = excl.events(:, stop_col_idx);
  
  matches_start(:, i) = arrayfun( @(x) any(x == start_indices), mut_evt_starts );
  matches_stop(:, i) = arrayfun( @(x) any(x == stop_indices), mut_evt_stops );
  
  % check whether, for each start:stop of an exclusive event, a mutual
  % event falls within that range. if so, remove it.
  needs_removal = rowzeros( numel(start_indices), 'logical' );
  
  for j = 1:numel(start_indices)
    excl_evt_range = start_indices(j):stop_indices(j);
    
    for k = 1:numel(mut_evt_starts)
      mut_evt_range = mut_evt_starts(k):mut_evt_stops(k);
      
      if ( params.is_truly_exclusive )
        needs_removal(j) = ~isempty( intersect(mut_evt_range, excl_evt_range) );
      else
        needs_removal(j) = mut_evt_starts(k) == start_indices(j); 
      end
      
      if ( needs_removal(j) ), break; end
    end
  end
  
  % remove exclusive events that overlap.
  exclusive.(monk_id).events(needs_removal, :) = [];
end

mult_starts = sum( matches_start, 2 );
mult_stops = sum( matches_stop, 2 );

is_simultaneous_start = find( mult_starts > 1 );
is_simultaneous_stop = find( mult_stops > 1 );

is_single_start = find( mult_starts == 1 );
is_single_stop = find( mult_stops == 1 );

for i = 1:numel(is_simultaneous_start)
  progenitor_ids{is_simultaneous_start(i)} = 'simultaneous_start';
end

for i = 1:numel(is_simultaneous_stop)
  broke_ids{is_simultaneous_stop(i)} = 'simultaneous_stop';
end

% assumption is that for each single start, non-started id is the
% initiator.
assert( numel(monk_ids) == 2, 'Expected 2 monk ids; got %d.', numel(monk_ids) );

% check which subject initiated.
for i = 1:numel(is_single_start)
  ind = is_single_start(i);
  
  for j = 1:numel(monk_ids)
    if ( matches_start(ind, j) )
      assert( isempty(progenitor_ids{ind}) );
      
      m_id = setdiff( monk_ids, monk_ids(j) );
      
      progenitor_ids{ind} = get_initiated_label( char(m_id) );
    end
  end
end

% check which subject terminated.
for i = 1:numel(is_single_stop)
  ind = is_single_stop(i);
  
  for j = 1:numel(monk_ids)
    if ( matches_stop(ind, j) )
      assert( isempty(broke_ids{ind}) );
      
      broke_ids{ind} = get_terminated_label( monk_ids{j} );
    end
  end
end

assigned_progenitors = all( ~cellfun(@isempty, progenitor_ids) );
assigned_broke = all( ~cellfun(@isempty, broke_ids) );

assert( all(assigned_progenitors), 'Not all progenitor ids were assigned.' );
assert( all(assigned_broke), 'Not all terminator ids were assigned.' );

labels = struct();
labels.progenitor_ids = progenitor_ids;
labels.broke_ids = broke_ids;

end

function outs = find_mutual_events(t, step_size, exclusive_outs, params)

import shared_utils.logical.find_starts;

duration = ceil( params.duration / step_size );
assert( ~isnan(duration), '"duration" cannot be nan.' );

is_valid_a = exclusive_outs.m1.is_valid;
is_valid_b = exclusive_outs.m2.is_valid;

is_valid = is_valid_a & is_valid_b;

evts = find_starts( is_valid, duration );

if ( params.fill_gaps )
  fill_gaps_duration = ceil( params.fill_gaps_duration / step_size );

  assert( ~isnan(fill_gaps_duration), '"fill_gaps_duration" cannot be nan.' );

  [is_valid, evts] = bfw.fill_gaps( is_valid, evts, fill_gaps_duration );
end

evt_info = get_event_info( t, evts, is_valid, duration );

outs.events = evt_info;
outs.event_key = get_event_key();
outs.is_valid = is_valid;

end

function exclusive_outs = find_exclusive_events_roi_method(t, step_size, fix_file, params)

import shared_utils.vector.slidebin;
import shared_utils.logical.find_starts;

duration = ceil( params.duration / step_size );
assert( ~isnan(duration), '"duration" cannot be nan.' );

monk_ids = intersect( {'m1', 'm2'}, fieldnames(fix_file) );

exclusive_outs = struct();

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i}; 
  is_fix = fix_file.(monk_id);

  evts = find_starts( is_fix, duration );

  if ( params.fill_gaps )
    fill_gaps_duration = ceil( params.fill_gaps_duration / step_size );
    assert( ~isnan(fill_gaps_duration), '"fill_gaps_duration" cannot be nan.' );
    [is_fix, evts] = bfw.fill_gaps( is_fix, evts, fill_gaps_duration );
  end

  evt_info = get_event_info( t, evts, is_fix, duration );

  outs.events = evt_info;
  outs.event_key = get_event_key();
  outs.is_valid = is_fix;
  
  exclusive_outs.(monk_id) = outs;
end


end

function exclusive_outs = find_exclusive_events_bounds_method(roi_name, t, step_size, bounds_file, fix_file, params)

import shared_utils.vector.slidebin;
import shared_utils.logical.find_starts;

duration = ceil( params.duration / step_size );
assert( ~isnan(duration), '"duration" cannot be nan.' );

monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );

exclusive_outs = struct();

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  bounds = bounds_file.(monk_id);
  is_fix = fix_file.(monk_id);

  is_valid_sample = bounds(roi_name);

  if ( params.require_fixations )
    is_valid_sample = is_valid_sample & is_fix;
  end

  evts = find_starts( is_valid_sample, duration );

  if ( params.fill_gaps )
    fill_gaps_duration = ceil( params.fill_gaps_duration / step_size );

    assert( ~isnan(fill_gaps_duration), '"fill_gaps_duration" cannot be nan.' );

    [is_valid_sample, evts] = bfw.fill_gaps( is_valid_sample, evts, fill_gaps_duration );
  end

  evt_info = get_event_info( t, evts, is_valid_sample, duration );

  outs.events = evt_info;
  outs.event_key = get_event_key();
  outs.is_valid = is_valid_sample;
  
  exclusive_outs.(monk_id) = outs;
end

end

function evt_key = get_event_key()

evt_key = containers.Map();
evt_key('start_index') = 1;
evt_key('stop_index') = 2;
evt_key('length') = 3;
evt_key('start_time') = 4;
evt_key('stop_time') = 5;
evt_key('duration') = 6;

end

function evt_info = get_event_info(t, evts, is_valid_sample, duration)

[evts, evt_stops, evt_lengths] = get_event_lengths( t, evts, is_valid_sample, duration );

evt_start_times = columnize( t(evts) );
evt_stop_times = columnize(t(evt_stops));
evt_durations = evt_stop_times - evt_start_times;

evt_info = [ evts, evt_stops, evt_lengths, evt_start_times, evt_stop_times, evt_durations ];
end

function [evts, evt_stops, evt_lengths] = get_event_lengths(t, evts, is_valid_sample, duration)

evts = columnize( evts );
evt_lengths = arrayfun( @(x) get_event_length(x, is_valid_sample), evts );   
evt_stops = evts + evt_lengths;

%   Check whether any events do not stop before the end of the time vector.
%   In this case, decide whether to exclude the event, or mark its end as
%   the last time point. The event will be included if its length is at
%   least `duration` + 1; i.e., if truncating the event stop to the end of
%   the time vector does not shorten the event to be below the given
%   duration threshold.
out_of_bounds = evt_stops > numel( t );

if ( any(out_of_bounds) )
  oob_ind = find( out_of_bounds );

  for k = 1:numel(oob_ind)
    ind = oob_ind(k);
    
    if ( evt_lengths(ind) - 1 >= duration )
      evt_lengths(ind) = evt_lengths(ind) - 1;
      evt_stops(ind) = evt_stops(ind) - 1;
      out_of_bounds(ind) = false;
    end
  end
end

evts(out_of_bounds) = [];
evt_lengths(out_of_bounds) = [];
evt_stops(out_of_bounds) = [];

end

function l = get_event_length(index, bounds)
l = 0;
while ( index+l <= numel(bounds) && bounds(index+l) ), l = l + 1; end
end

function events_file = empty_events_file(unified_filename, params)

events_file.events = [];
events_file.labels = {};
events_file.unified_filename = unified_filename;
events_file.params = params;

end

function events_file = get_base_events_file(unified_filename, active_roi_names, is_all_rois, params)

% If we request to append output to an existing file, and we're not
% updating *all* rois, then load the currently existing events file.

events_file = struct();
make_empty_arrays = true;

if ( params.append && ~is_all_rois )
  events_subdir = params.intermediate_directory_name;
  get_events_file_func = params.get_current_events_file_func;
  conf = params.config;
  
  % Get the current events file using `get_events_file_func`. This function
  % should also return a logical scalar indicating whether an existing file
  % was loaded; if not, `events_file` is just a struct with no fields.
  [events_file, did_load] = get_events_file_func( unified_filename, events_subdir, conf );
  
  if ( did_load )
    % If this *is* an existing events file, remove the events associated
    % with `active_roi_names`; only these events will be overwritten.
    events_file = remove_active_rois_from_existing_events_file( events_file, active_roi_names );
    make_empty_arrays = false;
  end
end

if ( make_empty_arrays )
  events_file.events = [];
  events_file.labels = {};
end

events_file.unified_filename = unified_filename;
events_file.params = params;

end

function events_file = remove_active_rois_from_existing_events_file(events_file, active_roi_names)

labels = events_file.labels;
categories = events_file.categories;

roi_cat = strcmp( categories, 'roi' );
assert( nnz(roi_cat) == 1, 'No roi specifier found.' );

roi_labels = labels(:, roi_cat);

is_active_roi = false( size(labels, 1), 1 );

for i = 1:numel(active_roi_names)
  is_active_roi = is_active_roi | strcmp( roi_labels, active_roi_names{i} );
end

events_file.labels(is_active_roi, :) = [];
events_file.events(is_active_roi, :) = [];

end

function [roi_names, is_all_rois] = get_active_roi_names(possible_roi_names, requested_roi_names)

requested_roi_names = cellstr( requested_roi_names );
is_all_rois = numel( requested_roi_names ) == 1 && strcmp( requested_roi_names, 'all' );

if ( is_all_rois )
  roi_names = possible_roi_names;
else
  assert( all(ismember(requested_roi_names, possible_roi_names)) ...
    , 'Some manually requested rois do not have an entry in the roi file.' );

  roi_names = unique( requested_roi_names );
end

end