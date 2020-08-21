function [starts, all_types, labels] = linearize_joint_event_info(evts, roi_name)

days = evts.nday;
labels = fcat();

starts = [];
all_types = [];

joint_event_types = { 'joint', 'follow', 'no-joint' };

for i = 1:numel(days)
  start_stops = evts.start_end_idex{i};
  types = evts.event_type{i};
  
  combined_types = [ types.m1; types.m2 ];
  combined_types(combined_types == 0) = 3;
  
  starts = [ starts; start_stops.m1; start_stops.m2 ];
  all_types = [ all_types; combined_types ];
  
  mk_labels = @(v, l) repmat( {l}, rows(v), 1 );
  m1_labels = mk_labels( start_stops.m1, 'm1' );
  m2_labels = mk_labels( start_stops.m2, 'm2' );
  
  looks_by = [ m1_labels; m2_labels ];
  
  tmp_joint_event_types = joint_event_types(combined_types);
  
  f = fcat.create( ...
      'session', days{i} ...
    , 'looks_by', looks_by ...
    , 'joint_event_type', tmp_joint_event_types ...
    , 'roi', roi_name ...
  );
  
  append( labels, f );
end

assert_ispair( starts, labels );
assert_ispair( all_types, labels );

end