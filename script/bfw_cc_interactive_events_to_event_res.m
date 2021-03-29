function event_res = bfw_cc_interactive_events_to_event_res(indices, times, labels, time_files)

assert_ispair( indices, labels );
assert_ispair( times, labels );

[sesh_I, sesh_C] = findall( labels, 'session' );
new_event_inds = nan( size(labels, 1), 1 );
addcat( labels, 'unified_filename' );

for i = 1:numel(sesh_I)
  shared_utils.general.progress( i, numel(sesh_I) );
  
  time_inds = find( time_files.labels, sesh_C(:, i) );
  assert( ~isempty(time_inds) );
  poss_time = time_files.time(time_inds, 2);
  poss_files = time_files.time(time_inds, 1);
  mins = cellfun( @min, poss_time );
  maxs = cellfun( @max, poss_time );
  
  match_ts = times(sesh_I{i});
  match_inds = nan( size(match_ts) );
  match_files = cell( size(match_inds) );
  
  for j = 1:numel(match_ts)
    match_t = match_ts(j);
    if ( ~isnan(match_t) )
      tf = arrayfun( @(min, max) match_t >= min && match_t <= max, mins, maxs );
      assert( sum(tf) == 1 );
      curr_time = poss_time{tf};
      match_files{j} = poss_files{tf};
      
      non_nan = find( ~isnan(curr_time) );
      match_inds(j) = non_nan(bfw.find_nearest(curr_time(non_nan), match_t));
      
%       if ( match_inds(j) ~= indices(sesh_I{i}(j)) )
%         day_ind = strcmp( outs.cc_events_file.nday, sesh_C{i} );
%         assert( sum(day_ind) == 1 );
%         curr_t = outs.cc_time_file.days_bt{day_ind}(indices(sesh_I{i}(j)));
%         assert( curr_t == match_t );
%       end
      
    else
      match_files{j} = '<unified_filename>';
    end
  end
  
  new_event_inds(sesh_I{i}) = match_inds;
  setcat( labels, 'unified_filename', match_files, sesh_I{i} );
end

keep = find( ~isnan(new_event_inds) );
new_event_inds = new_event_inds(keep);
new_labels = prune( labels(keep) );
new_event_portions = cell( numel(new_event_inds), 3 );

assert_ispair( new_event_inds, new_labels );
assert_ispair( new_event_portions, new_labels );
assert( count(new_labels, '<unified_filename>') == 0 );

new_labels = match_cc_event_labels( new_labels );

event_res = struct();
event_res.event_starts = new_event_inds;
event_res.event_portions = new_event_portions;
event_res.labels = new_labels;

end

function l = match_cc_event_labels(labels)

l = labels';
renamecat( l, 'followed-by', 'follower' );
renamecat( l, 'initiated-by', 'initiator' );
renamecat( l, 'joint-event-type', 'interactive_event_type' );

replace( l, 'm1-init', 'm1_initiated' );
replace( l, 'm2-init', 'm2_initiated' );
replace( l, 'm1-follow', 'm1_followed' );
replace( l, 'm2-follow', 'm2_followed' );
replace( l, 'solo', 'solo-type' );
replace( l, 'join', 'joint-type' );
replace( l, 'follow', 'follow-type' );

m1_init_ind = find( l, {'m1_initiated', 'solo-type'} );
m2_init_ind = find( l, {'m2_initiated', 'solo-type'} );
setcat( l, 'follower', 'm2_followed', m1_init_ind );
setcat( l, 'follower', 'm1_followed', m2_init_ind );

assert( count(l, '<follow>') == 0 );

end