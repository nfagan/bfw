function make_events(varargin)

import shared_utils.logical.find_starts;

defaults = struct();
defaults.duration = NaN;
defaults.mutual_method = 'duration';  % 'duration' or 'plus-minus'
defaults.plus_minus_duration = 500;
defaults.files = [];

params = bfw.parsestruct( defaults, varargin );

bounds_p = bfw.get_intermediate_directory( 'bounds' );
save_p = bfw.get_intermediate_directory( 'events' );

shared_utils.io.require_dir( save_p );

if ( isempty(params.files) )
  bound_mats = shared_utils.io.find( bounds_p, '.mat' );
else
  bound_files = shared_utils.cell.ensure_cell( params.files );
  bound_mats = cellfun( @(x) fullfile(bounds_p, x), bound_files, 'un', false );
end

duration = params.duration;

assert( ~isnan(duration), 'Specify a valid "duration".' );

for i = 1:numel(bound_mats)
  fprintf( '\n %d of %d', i, numel(bound_mats) );
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
  unified_filename = bounds.m1.unified_filename;
  
  m1t = bounds.m1.time;
  m2t = bounds.m2.time;
  
  roi_names = m1.keys();
  
  all_events = cell( numel(roi_names), 3 );
  all_event_lengths = cell( size(all_events) );
  all_event_durations = cell( size(all_events) );
  
  event_roi_key = containers.Map();
  monk_key = containers.Map();
  
  monk_key('m1') = 1;
  monk_key('m2') = 2;
  monk_key('mutual') = 3;
  
  adjusted_duration = duration / bounds.step_size;
  adjusted_mutual_duration = params.plus_minus_duration / bounds.step_size;
  
  for j = 1:numel(roi_names)
    
    roi_name = roi_names{j};
    
    m1_bounds = m1(roi_name);
    m2_bounds = m2(roi_name);
    mutual_bounds = m1_bounds & m2_bounds;

    m1_evts = find_starts( m1_bounds, adjusted_duration );
    m2_evts = find_starts( m2_bounds, adjusted_duration );
    
    mut_method = params.mutual_method;
    
    if ( strcmp(mut_method, 'plus-minus') )
      mutual_bounds = m1_bounds & b_plus_minus( m1_bounds, m2_bounds, adjusted_mutual_duration );
    else
      assert( strcmp(mut_method, 'duration'), 'Unrecognized mutual method "%s".', mut_method );
    end
    
    mutual = find_starts( mutual_bounds, adjusted_duration );
    
%     switch ( params.mutual_method )
%       case 'duration'
%         mutual = find_starts( mutual_bounds, duration );
%       case 'plus-minus'
%         m2_bounds2 = b_plus_minus( m1_bounds, m2_bounds, adjusted_mutual_duration );
%         mutual = mutual_plus_minus( m1_evts, m2_evts, adjusted_mutual_duration );
%       otherwise
%         error( 'Unrecognized mutual method "%s".', params.mutual_method );
%     end
    
    m1_evt_length = arrayfun( @(x) get_event_length(x, m1_bounds), m1_evts );
    m2_evt_length = arrayfun( @(x) get_event_length(x, m2_bounds), m2_evts );
    mutual_evt_length = arrayfun( @(x) get_event_length(x, mutual_bounds), mutual );
    
    m1_evts = arrayfun( @(x) m1t(x), m1_evts );
    m2_evts = arrayfun( @(x) m2t(x), m2_evts );
    mutual = arrayfun( @(x) m1t(x), mutual );
    
    all_events(j, :) = { m1_evts, m2_evts, mutual };
    all_event_lengths(j, :) = { m1_evt_length, m2_evt_length, mutual_evt_length };
    all_event_durations(j, :) = all_event_lengths(j, :);
    
    event_roi_key(roi_name) = j;
  end
  
  events = struct();
  
  events.times = all_events;
  events.lengths = all_event_lengths;
  events.durations = cellfun( @(x) x .* bounds.step_size, all_event_durations, 'un', false );
  events.roi_key = event_roi_key;
  events.monk_key = monk_key;
  events.unified_filename = unified_filename;
  events.params = params;
  
  save( fullfile(save_p, unified_filename), 'events' );
end

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

function mut = mutual_plus_minus( a, b, duration )

mut = [];

for i = 1:numel(a)
  evt = a(i);
  less = b < evt & abs(b-evt) <= duration;
  more = b >= evt & abs(b-evt) <= duration;
  mut(end+1:end+sum(less | more)) = b(less | more);
end

mut = unique( mut );

end

function l = get_event_length( index, bounds )

l = 0;

while ( index+1 < numel(bounds) && bounds(index+l) )
  l = l + 1;
end

end