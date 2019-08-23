function [durations, labels] = get_preceding_stim_durations(starts, durs, event_labels, stim_ts, stim_labels, stim_ids)

event_mask = find( event_labels, {'eyes_nf', 'm1'} );

durations = [];
labels = fcat();

for i = 1:numel(stim_ts)
  nearest_start = find( starts(event_mask) < stim_ts(i), 2, 'last' );
  
  if ( numel(nearest_start) == 2 )    
    durations(end+1, 1) = durs(nearest_start(1)); 
    labs = bfw_st.join_event_stim_labels( event_labels, stim_labels, nearest_start(1), i, stim_ids );
    append( labels, labs );    
  end
end

end