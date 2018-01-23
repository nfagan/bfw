function make_events( duration )

import shared_utils.logical.find_starts;

bounds_p = bfw.get_intermediate_directory( 'bounds' );
save_p = bfw.get_intermediate_directory( 'events' );

shared_utils.io.require_dir( save_p );

bound_mats = shared_utils.io.find( bounds_p, '.mat' );

for i = 1:numel(bound_mats)
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  m1 = bounds.m1.bounds;
  m2 = bounds.m2.bounds;
  
  unified_filename = bounds.m1.unified_filename;
  
  m1t = bounds.m1.time;
  m2t = bounds.m2.time;
  
  roi_names = m1.keys();
  
  all_events = cell( numel(roi_names), 3 );
  event_roi_key = containers.Map();
  monk_key = containers.Map();
  
  monk_key('m1') = 1;
  monk_key('m2') = 2;
  monk_key('mutual') = 3;
  
  for j = 1:numel(roi_names)
    
    roi_name = roi_names{j};
    
    m1_bounds = m1(roi_name);
    m2_bounds = m2(roi_name);
    mutual_bounds = m1_bounds & m2_bounds;

    m1_evts = find_starts( m1_bounds, duration );
    m2_evts = find_starts( m2_bounds, duration );
    mutual = find_starts( mutual_bounds, duration );
    
    m1_evts = arrayfun( @(x) m1t(x), m1_evts );
    m2_evts = arrayfun( @(x) m2t(x), m2_evts );
    mutual = arrayfun( @(x) m1t(x), mutual );
    
    all_events(j, :) = { m1_evts, m2_evts, mutual };
    
    event_roi_key(roi_name) = j;
  end
  
  events = struct();
  
  events.times = all_events;
  events.roi_key = event_roi_key;
  events.monk_key = monk_key;
  events.unified_filename = unified_filename;
  
  save( fullfile(save_p, unified_filename), 'events' );
end

end