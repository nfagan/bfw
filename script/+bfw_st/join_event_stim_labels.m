function subset_labs = join_event_stim_labels(event_labels, stim_labels, event_inds, stim_ind, stim_ids)

subset_labs = event_labels(event_inds);
join( subset_labs, prune(stim_labels(stim_ind)) );

if ( ~isempty(subset_labs) )
  setcat( subset_labs, 'stim_id', stim_ids{stim_ind} );
end

end