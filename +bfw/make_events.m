function make_events( duration )

bounds_p = bfw.get_intermediate_directory( 'bounds' );
unified_p = bfw.get_intermediate_directory( 'unified' );

bound_mats = shared_utils.io.find( bounds_p, '.mat' );

for i = 1:numel(bound_mats)
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
  meta = shared_utils.io.fload( fullfile(unified_p, bounds.m1.unified_filename) );
  
  m1t = bounds.m1.time;
  m2t = bounds.m2.time;
  
  roi_names = m1.keys();
  
  for j = 1:numel(roi_names)
    
    roi_name = roi_names{j};
    
    m1_bounds = m1(roi_name);
    m2_bounds = m2(roi_name);
    mutual_bounds = m1_bounds & m2_bounds;

    m1_evts = shared_utils.logical.find_starts( m1_bounds, evt_length );
    m2_evts = shared_utils.logical.find_starts( m2_bounds, evt_length );
    mutual = shared_utils.logical.find_starts( mutual_bounds, evt_length );
    
    d = 10;
  end
end

end