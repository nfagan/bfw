function keep_events = bfw_remove_solo_within(events, range, prevent_other, mask)

if ( nargin < 4 )
  mask = rowmask( events.labels );
end

within = { 'unified_filename', 'roi' };
within_I = findall( events.labels, within, mask );
start_inds = bfw.event_column( events, 'start_index' );

keep_events = true( size(events.events, 1), 1 );

for i = 1:numel(within_I)
  m1_ind = find( events.labels, 'm1', within_I{i} );
  m2_ind = find( events.labels, 'm2', within_I{i} );
  
  m1_s = start_inds(m1_ind);
  m2_s = start_inds(m2_ind);
  
  if ( strcmp(prevent_other, 'm1') )
    targ = m2_s;
    compare = m1_s;
    targ_ind = m2_ind;
  else
    assert( strcmp(prevent_other, 'm2'), 'Expected either "m1" or "m2".' );
    targ = m1_s;
    compare = m2_s;
    targ_ind = m1_ind;
  end
  
  keep_targ = true( size(targ, 1), 1 );
  for j = 1:size(targ, 1)
    targ_start = targ(j);
    lb = targ_start + range(1);
    ub = targ_start + range(2);
    within_b = compare >= lb & compare <= ub;
    
    if ( any(within_b) )
      keep_targ(j) = false;
    end
  end
  
  keep_events(targ_ind) = keep_targ;
end

keep_events = find( keep_events );

end