classdef BFWInteractiveEventClassification
  properties (Constant = true)
    solo_type = solo_event_type()
    joint_type = joint_event_type()
    follow_type = follow_event_type()
    unclassified_type = unclassified_event_type()    
  end
  
  methods (Static = true)
    function varargout = m1_initiator_m2_follower(varargin)
      [varargout{1:nargout}] = m1_initiator_m2_follower( varargin{:} );
    end
    function varargout = m2_initiator_m1_follower(varargin)
      [varargout{1:nargout}] = m2_initiator_m1_follower( varargin{:} );
    end
    function varargout = mutual(varargin)
      [varargout{1:nargout}] = classify_mutual( varargin{:} );
    end
    function strs = event_type_to_cellstr(types)
      kinds = { 'unclassified-type', 'solo-type', 'joint-type', 'follow-type' };
      strs = kinds(types + 1);
    end
  end
end

function [event_types, event_starts, event_portions] = m1_initiator_m2_follower(m1_events, m2_events, m1_gaze, follow_range, use_gaze_ctrl)

m1_event_ranges = make_ranges( m1_events );

event_types = repmat( unclassified_event_type(), size(m2_events, 1), 1 );
event_starts = nan( size(event_types) );
event_portions = cell( size(m2_events, 1), 3 );

for i = 1:size(m2_events, 1)
  m2_event = m2_events(i, :);
  m2_event_range = m2_event(1):m2_event(2);
  event_starts(i) = m2_event(1);
  
  m1_intersects = intersects_ranges( m2_event_range, m1_event_ranges );
  m1_is_pre = cellfun( @(x) x(1) < m2_event(1), m1_event_ranges );
  
  is_joint_event = m1_intersects & m1_is_pre;
  
  [m1_initiated_joint_event, m1_initiated_joint_event_ind] = ...
    find_latest_event( m1_events, is_joint_event );
  
  if ( ~isempty(m1_initiated_joint_event) )
    % Panel a). Joint event.
    event_types(i) = joint_event_type;
    
    [m1_excl_portion, m2_excl_portion, joint_portion] = ...
      event_range_subtypes( m1_event_ranges, m2_event_range, m1_initiated_joint_event_ind );
    
    event_portions(i, 1) = {m1_excl_portion};
    event_portions(i, 2) = {m2_excl_portion};
    event_portions(i, 3) = {joint_portion};
    
  else
    % Panel c). This might be a follow event, but check whether m1 was
    % within the degree criterion of m2 during the current m2 event.
    m1_precedes = ...
      ~m1_intersects & are_within_follow_range( m2_event, m1_event_ranges, follow_range );
    
    [m1_precede_event, m1_precede_event_ind] = ...
      find_latest_event( m1_events, m1_precedes );
    
    if ( ~isempty(m1_precede_event) )
      % Ostensibly a follow event.
      if ( ~use_gaze_ctrl || any(m1_gaze(m2_event_range)) )
        event_types(i) = follow_event_type;
      end
      
    elseif ( ~use_gaze_ctrl || any(m1_gaze(m2_event_range)) )
      % Solo m2 event for which m1 was within the degree criterion of m2.
      event_types(i) = solo_event_type;
      
    else
      % The event is an m2 solo event for which m1 was *not* within
      % the degree criterion of m2. So this event is "unclassified"
    end
  end
end

end

function [event_types, event_starts, event_portions] = m2_initiator_m1_follower(m1_events, m2_events, m1_gaze, follow_range, use_gaze_ctrl)

m2_event_ranges = make_ranges( m2_events );
event_types = repmat( solo_event_type, size(m1_events, 1), 1 );
event_starts = nan( size(event_types) );
event_portions = cell( size(m1_events, 1), 3 );

for i = 1:size(m1_events, 1)
  m1_event = m1_events(i, :);
  m1_event_range = m1_event(1):m1_event(2);
  event_starts(i) = m1_event(1);
  
  % For each m2 event, check whether it overlaps with (intersects)
  % the current m1 event.
  m2_intersects = intersects_ranges( m1_event_range, m2_event_ranges );
  
  % For each m2 event, mark whether it precedes the current m1 event.
  m2_is_pre = cellfun( @(x) x(1) < m1_event(1), m2_event_ranges );
  
  is_joint_event = m2_intersects & m2_is_pre;
  [m2_initiated_joint_event, m2_initiated_joint_event_ind] = ...
    find_latest_event( m2_events, is_joint_event );
  
  if ( ~isempty(m2_initiated_joint_event) )
    % Panel b). This is ostensibly a joint event, but check whether m1 was 
    % within some degree radius of m2 during the portion of the joint event
    % that m1 was not directly looking at m2.
    m2_solo_portion = m2_initiated_joint_event(1):m1_event_range(1);
    
    if ( ~use_gaze_ctrl || any(m1_gaze(m2_solo_portion)) )
      % OK - m1 was within the degree criterion of m2.
      event_types(i) = joint_event_type;
      
      [m2_excl_portion, m1_excl_portion, joint_portion] = ...
        event_range_subtypes( m2_event_ranges, m1_event_range, m2_initiated_joint_event_ind );
    
      event_portions(i, 1) = {m1_excl_portion};
      event_portions(i, 2) = {m2_excl_portion};
      event_portions(i, 3) = {joint_portion};
    end
  else
    % Panel d). This might be a follow event, but check whether m1 was 
    % within the degree criterion of m2 during the m2-solo portion of the 
    % joint event.
    m2_precedes = ...
      ~m2_intersects & are_within_follow_range( m1_event, m2_event_ranges, follow_range );
    
    [m2_precede_event, m2_precede_event_ind] = ...
      find_latest_event( m2_events, m2_precedes );
    
    if ( ~isempty(m2_precede_event) )
      m2_solo_portion = m2_precede_event(1):m1_event_range(1);
      
      if ( ~use_gaze_ctrl || any(m1_gaze(m2_solo_portion)) )
        % OK - m1 was within the degree criterion of m2.
        event_types(i) = follow_event_type;
      end
    end
    % Otherwise, it's a true m1 solo event.
  end
end

end

function [solo1, solo2, joint] = event_range_subtypes(ranges1, range2, joint_ind)

solo1 = setdiff( ranges1{joint_ind}, range2 );
solo2 = setdiff( range2, ranges1{joint_ind} );
joint = intersect( ranges1{joint_ind}, range2 );

end

function [event_types, looks_by, was_handled] = ...
  classify_mutual(m1_events, m2_events, mut_events, m1_gaze, follow_range, use_gaze_ctrl)

event_types = repmat( unclassified_event_type, size(mut_events, 1), 1 );
looks_by = repmat( {'mutual'}, size(event_types) );
was_handled = false( size(event_types) );

mut_event_types_m1 = m2_initiator_m1_follower( mut_events, m2_events, m1_gaze, follow_range, use_gaze_ctrl );
mut_event_types_m2 = m1_initiator_m2_follower( m1_events, mut_events, m1_gaze, follow_range, use_gaze_ctrl );

m1_is_solo = mut_event_types_m1 == solo_event_type;
m2_is_solo = mut_event_types_m2 == solo_event_type;

m1_is_unclass = mut_event_types_m1 == unclassified_event_type;
m2_is_unclass = mut_event_types_m2 == unclassified_event_type;

m1_is_joint = mut_event_types_m1 == joint_event_type;
m1_is_follow = mut_event_types_m1 == follow_event_type;

m2_is_joint = mut_event_types_m2 == joint_event_type;
m2_is_follow = mut_event_types_m2 == follow_event_type;

% If a mutual event was classified as solo when m1 was the follower, but
% given an interactive event type when m2 was the follower, then treat it
% as an m2 interactive event.
use_m2 = m1_is_solo & (m2_is_joint | m2_is_follow);

event_types(use_m2) = mut_event_types_m2(use_m2);
looks_by(use_m2) = { 'm2' };
was_handled(use_m2) = true;

% If events are classified as joint for one follower and follow for
% another, prefer the joint event.
use_m1_joint = m1_is_joint & m2_is_follow & ~was_handled;
use_m2_joint = m2_is_joint & m1_is_follow & ~was_handled;

event_types(use_m1_joint) = joint_event_type;
looks_by(use_m1_joint) = { 'm1' };
was_handled(use_m1_joint) = true;

event_types(use_m2_joint) = joint_event_type;
looks_by(use_m2_joint) = { 'm2' };
was_handled(use_m2_joint) = true;

% If the mutual event is classified as an interactive event when m1 is the
% follower, but a solo event when m2 is the follower, then prefer the
% interactive event.
use_m1_interactive = ~was_handled & (m1_is_joint | m1_is_follow) & m2_is_solo;

% If m2 is unclassified and m1 is not unclassified, prefer m1.
use_m1_rest = ~was_handled & m2_is_unclass & ~m1_is_unclass;
use_m1 = use_m1_interactive | use_m1_rest;

event_types(use_m1) = mut_event_types_m1(use_m1);
looks_by(use_m1) = { 'm1' };
was_handled(use_m1) = true;

% If m1 is unclassified and m2 is not unclassified, prefer m2.
use_m2_rest = ~was_handled & m1_is_unclass & ~m2_is_unclass;

event_types(use_m2_rest) = mut_event_types_m2(use_m2_rest);
looks_by(use_m2_rest) = { 'm2' };
was_handled(use_m2_rest) = true;

end

function type = unclassified_event_type()
type = 0;
end

function type = solo_event_type()
type = 1;
end

function type = joint_event_type()
type = 2;
end

function type = follow_event_type()
type = 3;
end

function tf = are_within_follow_range(query_event, ranges, follow_range)

is_within_follow_range = ...
  @(x) query_event(1) - x(2) > 0 && query_event(1) - x(2) <= follow_range;
    
tf = cellfun( is_within_follow_range, ranges );

end

function [event, event_ind] = find_latest_event(events, is_target)

event_inds = find( is_target );
target_events = events(is_target, :);

% If there is more than one event, keep the latest one.
last_event_ind = latest_event_index( target_events );
event = target_events(last_event_ind, :);
event_ind = event_inds(last_event_ind);

end

function ind = latest_event_index(events)
[~, ind] = max( events(:, 1), [], 1 );
end

function tf = intersects_ranges(query_range, ranges)
tf = cellfun( @(x) ~isempty(intersect(x, query_range)), ranges );
end

function ranges = make_ranges(events)
ranges = arrayfun( @(x) events(x, 1):events(x, 2), 1:size(events, 1), 'un', 0 );
end