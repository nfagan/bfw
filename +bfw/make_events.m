function make_events(varargin)

import shared_utils.logical.find_starts;
ff = @fullfile;

defaults = bfw.get_common_make_defaults();

defaults.duration = NaN;
defaults.mutual_method = 'duration';  % 'duration' or 'plus-minus'
defaults.plus_minus_duration = 500;
defaults.fill_gaps = false;
defaults.fill_gaps_duration = 50;
defaults.remove_overlapping_exclusive_events = false;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

bounds_p = bfw.gid( ff('bounds', isd), conf );
save_p = bfw.gid( ff('events', osd), conf );

shared_utils.io.require_dir( save_p );

bound_mats = bfw.require_intermediate_mats( params.files, bounds_p, params.files_containing );

duration = params.duration;

assert( ~isnan(duration), 'Specify a valid "duration".' );

for i = 1:numel(bound_mats)

  fprintf( '\n %d of %d', i, numel(bound_mats) );
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m_fields = intersect( {'m1', 'm2'}, fieldnames(bounds) );
  
  unified_filename = bounds.(m_fields{1}).unified_filename;
  full_filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  check_mutual = true;
  
  if ( numel(m_fields) == 1 )
    missing = char( setdiff({'m1', 'm2'}, m_fields{1}) );
    bounds.(missing) = bounds.(m_fields{1});
    bounds.(missing).bounds = missing_mutual_fill0( bounds.(missing).bounds );
    check_mutual = false;
  end
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
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
    
    if ( check_mutual )
      mutual_bounds = m1_bounds & m2_bounds;
    else
      mutual_bounds = false( size(m1_bounds) );
    end
    
    mut_method = params.mutual_method;
    
    if ( strcmp(mut_method, 'plus-minus') )
      mutual_bounds = m1_bounds & b_plus_minus( m1_bounds, m2_bounds, adjusted_mutual_duration );
    else
      assert( strcmp(mut_method, 'duration'), 'Unrecognized mutual method "%s".', mut_method );
    end
    
    mutual_indices = find_starts( mutual_bounds, adjusted_duration );
    
    if ( params.fill_gaps )
      [mutual_bounds, mutual_indices] = fill_gaps( mutual_bounds, mutual_indices, adjusted_fill_gaps_duration );
    end 
    
%     [looked_first_index, looked_first_distance] = who_looked_first( mutual, m1_bounds, m2_bounds );
    looked_first_index = who_looked_first( mutual_indices, m1_evts, m2_evts );
    looked_first_distance = nan( size(looked_first_index) );
    
    %   NEW -- ensure exclusive events are truly exclusive of mutual
    m1_evts = setdiff( m1_evts, mutual_indices );
    m2_evts = setdiff( m2_evts, mutual_indices );
    
    m1_evt_length = arrayfun( @(x) get_event_length(x, m1_bounds), m1_evts );
    m2_evt_length = arrayfun( @(x) get_event_length(x, m2_bounds), m2_evts );
    mutual_evt_length = arrayfun( @(x) get_event_length(x, mutual_bounds), mutual_indices );
    
    if ( params.remove_overlapping_exclusive_events )
      m1_keep_inds = ...
        remove_overlapping_exclusive_events( mutual_indices, mutual_evt_length, m1_evts, m1_evt_length );
      m2_keep_inds = ...
        remove_overlapping_exclusive_events( mutual_indices, mutual_evt_length, m2_evts, m2_evt_length );
      
      m1_evts = m1_evts(m1_keep_inds);
      m2_evts = m2_evts(m2_keep_inds);
      
      m1_evt_length = m1_evt_length(m1_keep_inds);
      m2_evt_length = m2_evt_length(m2_keep_inds);
    end    
    
    m1_evt_times = arrayfun( @(x) m1t(x), m1_evts );
    m2_evt_times = arrayfun( @(x) m2t(x), m2_evts );
    mutual_times = arrayfun( @(x) m1t(x), mutual_indices );
    
    all_events(j, :) = { m1_evt_times, m2_evt_times, mutual_times };
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
    do_save( full_filename, events );
  else
    fprintf( '\n Not saving "%s"', unified_filename );
  end
end

end

function keep_ind = remove_overlapping_exclusive_events(mutual, mutual_length, exclusive, exclusive_length)

keep_ind = true( size(exclusive) );

for i = 1:numel(exclusive)
  excl = exclusive(i);
  
  nearest_before_idx = shared_utils.sync.nearest_before( mutual, excl );
  
  dist_between = mutual(nearest_before_idx) - excl;
  
  keep_ind(i) = dist_between > exclusive_length(i);
  
%   mut_start = mutual( nearest_before_idx );
%   mut_stop = mut_start +  mutual_length( nearest_before_idx ) - 1;
% 
%   excl_stop = excl + exclusive_length(i) - 1;
% 
%   figure(1); clf();
% 
%   plot( mut_start:mut_stop, ones(1, numel(mut_start:mut_stop)), 'r', 'linewidth', 5 );
%   hold on;
%   
%   if ( numel(excl:excl_stop) == 1 )
%     plot( excl:excl_stop, zeros(1, numel(excl:excl_stop)), 'b*', 'markersize', 5);
%   else
%     plot( excl:excl_stop, zeros(1, numel(excl:excl_stop)), 'b', 'linewidth', 5);
%   end
end

end

function do_save( filename, events )

save( filename, 'events' );

end

function out = who_looked_first(mutual_evts, m1_evts, m2_evts)

%   mutual begins once the *other* monkey enters the roi, so these are
%   flipped.
[~, m2_began] = ismember( m1_evts, mutual_evts );
[~, m1_began] = ismember( m2_evts, mutual_evts );

common = intersect( m1_evts, m2_evts );
[~, common_ind] = ismember( common, mutual_evts );
common_ind = common_ind(common_ind > 0);

m2_began = m2_began( m2_began > 0 );
m1_began = m1_began( m1_began > 0 );

out = nan( size(mutual_evts) );

out(m1_began) = 1;
out(m2_began) = 2;
out(common_ind) = 0;

end

% function [out, distance] = who_looked_first( mutual_evts, bounds_a, bounds_b )
% 
% starts_a = arrayfun( @(x) find_start_looking_back_from(x, bounds_a), mutual_evts );
% starts_b = arrayfun( @(x) find_start_looking_back_from(x, bounds_b), mutual_evts );
% 
% out = zeros( size(mutual_evts) );
% distance = zeros( size(mutual_evts) );
% 
% for i = 1:numel(out)
%   a = starts_a(i);
%   b = starts_b(i);
%   
%   if ( a == b )
%     %   both initiate simultaneously
%     continue;
%   elseif ( a < b )
%     %   m1 initiates
%     out(i) = 1;
%     distance(i) = mutual_evts(i) - a;
%   else
%     %   m2 initiates
%     out(i) = 2;
%     distance(i) = mutual_evts(i) - b;
%   end
% end
% 
% end

function bounds_copy = missing_mutual_fill0(bounds)

bounds_copy = containers.Map();

K = keys( bounds );

for i = 1:numel(K)
  fake = bounds(K{i});
  fake(:) = false;
  bounds_copy(K{i}) = fake;
end

end

function [bounds, events] = fill_gaps( bounds, events, threshold )

ind = [ diff(events) <= threshold, false ];

if ( ~any(ind) ), return; end

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

% try
  while ( index+l <= numel(bounds) && bounds(index+l) )
   l = l + 1;
  end
% catch err
%   d = 10;
% end
  
end