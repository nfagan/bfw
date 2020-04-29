function labels = recode_sig_labels(labels, expect_num_perms)

[each_I, each_C] = findall( labels ...
  , {'unit_uuid', 'region', 'session', 'unit_rating', 'channel'} );

for i = 1:numel(each_I)
  real_ind = find( labels, 'real', each_I{i} );
  null_ind = find( labels, 'null', each_I{i} );
  
  assert( numel(real_ind) == 1 && numel(null_ind) == expect_num_perms ...
    , 'Expected 1 real element and %d null elements to match.' ...
    , expect_num_perms );
  
  rwd_sig_label = combs( labels, 'rwd-sig', null_ind );
  gaze_sig_label = combs( labels, 'gaze-sig', null_ind );
  
  assert( numel(rwd_sig_label) == 1 && numel(gaze_sig_label) == 1 );
  
  setcat( labels, 'rwd-sig', rwd_sig_label, real_ind );
  setcat( labels, 'gaze-sig', gaze_sig_label, real_ind );
end

end