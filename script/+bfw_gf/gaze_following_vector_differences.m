%{

m1 looking at eyes, get gaze angle of m2
m1 looks somewhere else, look at vector difference

center reference

%}

function out = gaze_following_vector_differences(m1_target_evts, m1_all_evts, m1_pos, m2_pos)

assert( size(m1_target_evts, 2) == 2 && size(m1_all_evts, 2) == 2 );
assert( size(m1_pos, 1) == 2 && size(m2_pos, 1) == 2 );

next_m1_pos = nan( rows(m1_target_evts), 2 );
next_m1_evt_inds = nan( rows(m1_target_evts), 1 );
m2_pos_evt = nan( rows(m1_target_evts), 2 );

for i = 1:rows(m1_target_evts)
  m1_evt = m1_target_evts(i, :);
  m1s = m1_evt(1);
  m1e = m1_evt(2);
  
  m2_pos_evt(i, :) = nanmean( m2_pos(:, m1s:m1e), 2 );
  
  evt_diffs = m1_all_evts(:, 1) - m1s;
  m1_next_evt_ind = find( evt_diffs > 0 );
  [~, mi] = min( evt_diffs(m1_next_evt_ind) );
  m1_next_evt_ind = m1_next_evt_ind(mi);
  m1_next_evt = m1_all_evts(m1_next_evt_ind, :);
  
  next_m1_pos(i, :) = nanmean( m1_pos(:, m1_next_evt(1):m1_next_evt(2)), 2 );
  next_m1_evt_inds(i) = m1_next_evt_ind;
end

out = struct();
out.next_m1_pos = next_m1_pos;
out.next_m1_evt_ind = next_m1_evt_inds;
out.m2_pos = m2_pos_evt;

end