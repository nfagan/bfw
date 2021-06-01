function [indices, times, labels, stop_indices, outs] = ...
  bfw_extract_cc_interactive_event_info(cc_event_file, cc_time_file, roi)

day_labels = cc_event_file.nday;

indices = [];
stop_indices = [];
times = [];
labels = fcat();

event_portions = zeros( 0, 4 );
event_portion_ts = zeros( 0, 4 );
to_time_file = [];

for i = 1:numel(day_labels)
  ts = cc_time_file.days_bt{i};
  mut_events = cc_event_file.mutual_join_evt{i};
  abs_event_inds = cc_event_file.m1m2_evts{i};
  
  [m2_m1_init, m2_m1_join, m2_m1_event_portions, m2_m1_mut_labels] = ...
    get_event_info( mut_events, abs_event_inds, 'm2', 'm1' );
  
  [m1_m2_init, m1_m2_join, m1_m2_event_portions, m1_m2_mut_labels] = ...
    get_event_info( mut_events, abs_event_inds, 'm1', 'm2' );
  
  addsetcat( m2_m1_mut_labels, 'session', day_labels{i} );
  addsetcat( m1_m2_mut_labels, 'session', day_labels{i} );
  
  m2_m1_starts = m2_m1_join(:, 1);
  m1_m2_starts = m1_m2_join(:, 1);
  curr_starts = [ m2_m1_starts; m1_m2_starts ];
  
  m2_m1_stops = m2_m1_join(:, 2);
  m1_m2_stops = m1_m2_join(:, 2);
  curr_stops = [ m2_m1_stops; m1_m2_stops ];
  
  curr_event_portions = [ m2_m1_event_portions; m1_m2_event_portions ];
  
  curr_event_portion_ts = nan( size(curr_event_portions) );
  valid_ind = find( ~isnan(curr_event_portions) );
  portion_inds = curr_event_portions(valid_ind);
  portion_inds = min( portion_inds, numel(ts) );
  curr_event_portion_ts(valid_ind) = ts(portion_inds);
  
  event_portions = [ event_portions; curr_event_portions ];
  event_portion_ts = [ event_portion_ts; curr_event_portion_ts ];
  to_time_file = [ to_time_file; repmat(i, size(curr_event_portions, 1), 1) ];
  
  curr_times = nan( size(curr_starts) );
  is_in_bounds_index = curr_starts <= numel( ts );
  curr_times(is_in_bounds_index) = ts(curr_starts(is_in_bounds_index));
  
  times = [ times; columnize(curr_times) ];
  indices = [ indices; columnize(curr_starts) ];
  stop_indices = [ stop_indices; columnize(curr_stops) ];
  
  append( labels, m2_m1_mut_labels );
  append( labels, m1_m2_mut_labels );
end

assert_ispair( indices, labels );
assert_ispair( times, labels );
assert_ispair( event_portions, labels );
assert_ispair( event_portion_ts, labels );

if ( ~isempty(labels) )
  addsetcat( labels, 'roi', roi );
end

outs.event_portions = event_portions;
outs.event_portion_ts = event_portion_ts;
outs.to_time_file = to_time_file;

end

function [initiated_at, joined_at, join_portions, labels] = ... 
  get_event_info(mut_events, abs_event_inds, init_by, followed_by)

joint_event_types = { 'solo', 'join', 'follow' };

event_starts = abs_event_inds.(followed_by);
event_type = mut_events.(followed_by) + 1;
event_type_strs = joint_event_types(event_type);

initiated_by = repmat( {sprintf('%s-init', init_by)}, numel(event_type_strs), 1 );
follow_by = repmat( {sprintf('%s-follow', followed_by)}, numel(event_type_strs), 1 );

is_solo_event_type = event_type == 1;
initiated_by(is_solo_event_type) = {sprintf('%s-init', followed_by)};
follow_by(is_solo_event_type) = {'<follow>'};

if ( strcmp(init_by, 'm2') )
  joined_at = mut_events.m2m1;
  initiated_at = mut_events.m2se;
else
  assert( strcmp(init_by, 'm1') )
  joined_at = mut_events.m1m2;
  initiated_at = mut_events.m1se;
end

require_entry = @(x) ternary(isempty(x), nan(1, 2), x);

joined_at = cellfun( require_entry, joined_at, 'un', 0 );
initiated_at = cellfun( require_entry, initiated_at, 'un', 0 );

joined_at = vertcat( joined_at{:} );
initiated_at = vertcat( initiated_at{:} );

joined_at = joined_at + event_starts;
initiated_at = initiated_at + event_starts;

% terminator
join_ends = joined_at(:, 2);
init_ends = initiated_at(:, 2);
term_by = cell( size(join_ends) );

join_portions = nan( numel(join_ends), 4 );

for i = 1:numel(join_ends)
  if ( init_ends(i) > join_ends(i) )
    % initiator looked longer, so follower terminated.
    term_label = followed_by;
  else
    % follower looked longer, so initiator terminated.
    term_label = init_by;
  end
  term_by{i} = sprintf( '%s-term', term_label );
  
  if ( event_type(i) == 2 )
    % join event
    join_end = min( init_ends(i), join_ends(i) );
    term_end = max( init_ends(i), join_ends(i) );
    
    join_portions(i, 1) = initiated_at(i, 1);
    join_portions(i, 2) = joined_at(i, 1);    
    join_portions(i, 3) = join_end;
    join_portions(i, 4) = term_end;
  end
end

labels = fcat.create( ...
    'joint-event-type', event_type_strs ...
  , 'initiated-by', initiated_by ...
  , 'followed-by', follow_by ...
  , 'terminated-by', term_by ...
);

end