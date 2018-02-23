function make_events(varargin)

import shared_utils.logical.find_starts;

defaults = bfw.get_common_make_defaults();

defaults.duration = NaN;
defaults.mutual_method = 'duration';  % 'duration' or 'plus-minus'
defaults.plus_minus_duration = 500;
defaults.fill_gaps = false;
defaults.fill_gaps_duration = 50;

params = bfw.parsestruct( defaults, varargin );

bounds_p = bfw.get_intermediate_directory( 'bounds' );
save_p = bfw.get_intermediate_directory( 'events' );

shared_utils.io.require_dir( save_p );

bound_mats = bfw.require_intermediate_mats( params.files, bounds_p, params.files_containing );

duration = params.duration;

assert( ~isnan(duration), 'Specify a valid "duration".' );

for i = 1:numel(bound_mats)
  fprintf( '\n %d of %d', i, numel(bound_mats) );
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
  unified_filename = bounds.m1.unified_filename;
  
  full_filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  m1t = bounds.m1.time;
  m2t = bounds.m2.time;
  
  roi_names = m1.keys();
  
  all_events = cell( numel(roi_names), 3 );
  all_event_lengths = cell( size(all_events) );
  all_event_durations = cell( size(all_events) );
  all_looked_first_indices = cell( numel(roi_names), 1 );
  all_looked_first_distances = cell( size(all_looked_first_indices) );
  
  event_roi_key = containers.Map();
  monk_key = containers.Map();
  
  monk_key('m1') = 1;
  monk_key('m2') = 2;
  monk_key('mutual') = 3;
  
  adjusted_duration = duration / bounds.step_size;
  adjusted_mutual_duration = params.plus_minus_duration / bounds.step_size;
  adjusted_fill_gaps_duration = params.fill_gaps_duration / bounds.step_size;
  
  for j = 1:numel(roi_names)
    
    roi_name = roi_names{j};
    
    m1_bounds = m1(roi_name);
    m2_bounds = m2(roi_name);

    m1_evts = find_starts( m1_bounds, adjusted_duration );
    m2_evts = find_starts( m2_bounds, adjusted_duration );
    
    if ( params.fill_gaps )
      [m1_bounds, m1_evts] = fill_gaps( m1_bounds, m1_evts, adjusted_fill_gaps_duration );
      [m2_bounds, m2_evts] = fill_gaps( m2_bounds, m2_evts, adjusted_fill_gaps_duration );
    end
    
    mutual_bounds = m1_bounds & m2_bounds;
    
    mut_method = params.mutual_method;
    
    if ( strcmp(mut_method, 'plus-minus') )
      mutual_bounds = m1_bounds & b_plus_minus( m1_bounds, m2_bounds, adjusted_mutual_duration );
    else
      assert( strcmp(mut_method, 'duration'), 'Unrecognized mutual method "%s".', mut_method );
    end
    
    mutual = find_starts( mutual_bounds, adjusted_duration );
    
     if ( params.fill_gaps )
        [mutual_bounds, mutual] = fill_gaps( mutual_bounds, mutual, adjusted_fill_gaps_duration );
     end 
    
    [looked_first_index, looked_first_distance] = who_looked_first( mutual, m1_bounds, m2_bounds );
    
    m1_evt_length = arrayfun( @(x) get_event_length(x, m1_bounds), m1_evts );
    m2_evt_length = arrayfun( @(x) get_event_length(x, m2_bounds), m2_evts );
    mutual_evt_length = arrayfun( @(x) get_event_length(x, mutual_bounds), mutual );
    
    m1_evts = arrayfun( @(x) m1t(x), m1_evts );
    m2_evts = arrayfun( @(x) m2t(x), m2_evts );
    mutual = arrayfun( @(x) m1t(x), mutual );
    
    all_events(j, :) = { m1_evts, m2_evts, mutual };
    all_event_lengths(j, :) = { m1_evt_length, m2_evt_length, mutual_evt_length };
    all_event_durations(j, :) = all_event_lengths(j, :);
    
    all_looked_first_indices{j, 1} = looked_first_index;
    all_looked_first_distances{j, 1} = looked_first_distance;
    
    event_roi_key(roi_name) = j;
  end
  
  events = struct();
  
  events.times = all_events;
  events.lengths = all_event_lengths;
  events.durations = cellfun( @(x) x .* bounds.step_size, all_event_durations, 'un', false );
  events.looked_first_indices = all_looked_first_indices;
  events.looked_first_distances = all_looked_first_distances;
  events.looked_first_durations = cellfun( @(x) x .* bounds.step_size, all_looked_first_distances, 'un', false );
  
  events.identifiers = bfw.get_event_identifiers( events.times, unified_filename );
  
  events.roi_key = event_roi_key;
  events.monk_key = monk_key;
  events.unified_filename = unified_filename;
  events.params = params;
  events.window_size = bounds.window_size;
  events.step_size = bounds.step_size;
  
  events.adjustments = containers.Map();
  
  if ( params.save )
    save( full_filename, 'events' );
  else
    fprintf( '\n Not saving "%s"', unified_filename );
  end
end

end

function [out, distance] = who_looked_first( mutual_evts, bounds_a, bounds_b )

starts_a = arrayfun( @(x) find_start_looking_back_from(x, bounds_a), mutual_evts );
starts_b = arrayfun( @(x) find_start_looking_back_from(x, bounds_b), mutual_evts );

out = zeros( size(mutual_evts) );
distance = zeros( size(mutual_evts) );

for i = 1:numel(out)
  a = starts_a(i);
  b = starts_b(i);
  
  if ( a == b )
    %   both initiate simultaneously
    continue;
  elseif ( a < b )
    %   m1 initiates
    out(i) = 1;
    distance(i) = mutual_evts(i) - a;
  else
    %   m2 initiates
    out(i) = 2;
    distance(i) = mutual_evts(i) - b;
  end
end

end

function [bounds, events] = fill_gaps( bounds, events, threshold )

ind = [ diff(events) <= threshold, false ];

if ( ~any(ind) ), return; end;

num_inds = find( ind );

to_keep_evts = true( size(events) );

for i = 1:numel(num_inds)
  start_ind = events(num_inds(i));
  stop_ind = events(num_inds(i)+1);
  to_keep_evts(num_inds(i)+1) = false;
  bounds(start_ind:stop_ind) = true;
end

events = events( to_keep_evts );

[bounds, events] = fill_gaps( bounds, events, threshold );

end

function evt = find_start_looking_back_from( evt, bounds )

while ( evt > 0 && bounds(evt) )
  evt = evt - 1;
end

if ( evt == 0 ), return; end

evt = evt + 1;

end

function b = b_plus_minus( a, b, duration )

N = numel( a );

for i = duration+1:N-duration
  if ( ~a(i) ), continue; end
  for j = -duration:duration
    idx = i + j;
    if ( b(idx) )
      b(i) = true;
      break;
    end
  end
end

end

function l = get_event_length( index, bounds )

l = 0;

while ( index+1 < numel(bounds) && bounds(index+l) )
  l = l + 1;
end

end