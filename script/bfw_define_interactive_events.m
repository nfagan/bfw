function out = bfw_define_interactive_events(events, look_vec, varargin)

defaults = struct();
defaults.max_follow_duration = 1e3; % ms
defaults.include_mutual = false;
defaults.mask_func = @bfw.default_mask_func;
defaults.use_gaze_control_for_solo = true;
defaults.prune = true;

params = shared_utils.general.parsestruct( defaults, varargin );

import BFWInteractiveEventClassification.m2_initiator_m1_follower;
import BFWInteractiveEventClassification.m1_initiator_m2_follower;

event_start_stops = [ bfw.event_column(events, 'start_index') ...
                    , bfw.event_column(events, 'stop_index') ];

event_mask = params.mask_func( events.labels, rowmask(events.labels) );
[each_I, each_C] = findall( events.labels, {'unified_filename', 'roi'}, event_mask );
                  
follow_range = params.max_follow_duration;
include_mutual = params.include_mutual;
use_gaze_ctrl = params.use_gaze_control_for_solo;

interactive_labels = events.labels';
addsetcat( interactive_labels, event_category(), 'unclassified-type' );
addcat( interactive_labels, 'follower' );

event_portions = cell( rows(interactive_labels), 3 );
interactive_event_starts = nan( rows(interactive_labels), 1 );
actually_processed = false( size(interactive_event_starts) );

for i = 1:numel(each_I)
  shared_utils.general.progress( i, numel(each_I) );
  
  m1_gaze_ind = find( look_vec.labels, [each_C(:, i); {'m1'}] );
  m2_gaze_ind = find( look_vec.labels, [each_C(:, i); {'m2'}] );
  
  if ( numel(m1_gaze_ind) ~= 1 || numel(m2_gaze_ind) ~= 1 )
    continue;
  end
  
  m1_event_ind = find( events.labels, 'm1', each_I{i} );
  m2_event_ind = find( events.labels, 'm2', each_I{i} );
  mut_event_ind = find( events.labels, 'mutual', each_I{i} );
  
  m1_events = event_start_stops(m1_event_ind, :);
  m2_events = event_start_stops(m2_event_ind, :);
  mut_events = event_start_stops(mut_event_ind, :);
  
  m1_gaze = look_vec.look_vectors{m1_gaze_ind};
  
  [m1_event_types, m1_event_starts, m1_event_portions] = ...
    m2_initiator_m1_follower( m1_events, m2_events, m1_gaze, follow_range, use_gaze_ctrl );
  
  [m2_event_types, m2_event_starts, m2_event_portions] = ...
    m1_initiator_m2_follower( m1_events, m2_events, m1_gaze, follow_range, use_gaze_ctrl );
  
  setcat( interactive_labels, event_category(), event_type_strs(m1_event_types), m1_event_ind );
  setcat( interactive_labels, event_category(), event_type_strs(m2_event_types), m2_event_ind );
  
  setcat( interactive_labels, 'initiator', 'm1_initiated', m2_event_ind );
  setcat( interactive_labels, 'follower', 'm2_followed', m2_event_ind );
  
  setcat( interactive_labels, 'initiator', 'm2_initiated', m1_event_ind );
  setcat( interactive_labels, 'follower', 'm1_followed', m1_event_ind );
  
  if ( include_mutual )
    if ( ~use_gaze_ctrl )      
      mut_init = cellstr( interactive_labels, 'initiator', mut_event_ind );
      mut_follow = mutual_follower( mut_init );
      
      mut_event_types = repmat( BFWInteractiveEventClassification.joint_type, size(mut_follow) );
      mut_looks_by = strrep( mut_follow, '_followed', '' );
      
      setcat( interactive_labels, 'follower', mut_follow, mut_event_ind );
      setcat( interactive_labels, event_category(), event_type_strs(mut_event_types), mut_event_ind );
      setcat( interactive_labels, 'looks_by', mut_looks_by, mut_event_ind );
      
      interactive_event_starts(mut_event_ind) = mut_events(:, 1);
      
    else
      [mut_event_types, mut_looks_by, handled] = BFWInteractiveEventClassification.mutual( ...
        m1_events, m2_events, mut_events, m1_gaze, follow_range, use_gaze_ctrl );
      setcat( interactive_labels, event_category(), event_type_strs(mut_event_types), mut_event_ind );
      setcat( interactive_labels, 'looks_by', mut_looks_by, mut_event_ind );
    end
    
    actually_processed(mut_event_ind) = true;
  end
  
  interactive_event_starts(m1_event_ind) = m1_event_starts;
  interactive_event_starts(m2_event_ind) = m2_event_starts;
  
  event_portions(m1_event_ind, :) = m1_event_portions;
  event_portions(m2_event_ind, :) = m2_event_portions;
  
  actually_processed(m1_event_ind) = true;
  actually_processed(m2_event_ind) = true;
end

if ( params.prune )
  processed_inds = find( actually_processed );
  prune( keep(interactive_labels, processed_inds) );
  interactive_event_starts = interactive_event_starts(processed_inds);
  event_portions = event_portions(processed_inds, :);
end

assert_ispair( interactive_event_starts, interactive_labels );
assert_ispair( event_portions, interactive_labels );

out = struct();
out.event_starts = interactive_event_starts;
out.event_portions = event_portions;
out.labels = interactive_labels;

end

function cat = event_category()
cat = 'interactive_event_type';
end

function strs = event_type_strs(event_types)

strs = BFWInteractiveEventClassification.event_type_to_cellstr( event_types );

end

function f = mutual_follower(init)

f = cell( size(init) );

for i = 1:numel(init)
  switch ( init{i} )
    case 'm1_initiated'
      f{i} = 'm2_followed';
      
    case 'm2_initiated'
      f{i} = 'm1_followed';
      
    otherwise
      f{i} = sprintf( '%s_followed', init );
  end
end

end