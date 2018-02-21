mats_per_day = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('events_per_day'), [] );

all_evts = Container();

for i = 1:numel(mats_per_day)
  fprintf( '\n %d of %d', i, numel(mats_per_day) );
  
  evts = shared_utils.io.fload( mats_per_day{i} );
  
  if ( evts.is_link ), continue; end;
  
  event_info_key = evts.event_info_key;
  
  all_evts = all_evts.append( evts.event_info );
end

%%

subset_evts = all_evts.rm({'m1_leads_m2', 'm2_leads_m1'});

[I, C] = subset_evts.get_indices( {'unified_filename', 'session_name', 'looks_to', 'looks_by'} );

time_col = event_info_key('times');

new_ind = subset_evts.logic( false );

dists = Container();

for i = 1:numel(I)
  
  ind = I{i};
  inds = find( ind );
  
  new_ind(:) = false;
  
  if ( sum(ind) == 1 ), continue; end
  
  evt_times = subset_evts.data(ind, time_col);
  
  distances = diff( evt_times ) * 1e3;
  
  thresh_ind = distances > 150;
  
  new_labs = get_labels( one(subset_evts(ind)) );
  
  if ( all(thresh_ind) )
    new_ind(inds(1:end-1)) = true;
    dists = append( dists, Container(distances, new_labs) );
  elseif ( sum(thresh_ind) == 1 )
    continue;
  else
    distances = diff( evt_times([true; thresh_ind(:)]) ) * 1e3;
    dists = append( dists, Container(distances, new_labs) );
  end
end

%%

pl = ContainerPlotter();

figure(1); clf();

pl.hist( dists, 100, [], {'looks_to', 'looks_by'} );
