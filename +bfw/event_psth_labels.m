function psth_labels = event_psth_labels(evt_labels, spike_labels, evt_I, spk_I)

assert( numel(evt_I) == numel(spk_I) );
psth_labels = cell( size(evt_I) );

parfor i = 1:numel(evt_I)  
  si = spk_I{i};
  ei = evt_I{i};
  evt_labs = append( fcat(), evt_labels, ei );
  
  sub_labels = fcat();  
  for j = 1:numel(si)
    labs = join( evt_labs', prune(spike_labels(si(j))) );
    append( sub_labels, labs );
  end
  
  psth_labels{i} = sub_labels;
end

end