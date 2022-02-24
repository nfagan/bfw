function out = gaze_following_positions(m1_target_evts, m1_all_evts, m1_pos, m2_pos, num_evts_look_ahead)

assert( size(m1_target_evts, 2) == 2 && size(m1_all_evts, 2) == 2 );
assert( size(m1_pos, 1) == 2 && size(m2_pos, 1) == 2 );

next_m1_pos = nan( rows(m1_target_evts), 2, num_evts_look_ahead );
next_m1_evt_inds = nan( rows(m1_target_evts), num_evts_look_ahead );
m1_iei = nan( rows(m1_target_evts), num_evts_look_ahead );
m2_pos_evt = nan( rows(m1_target_evts), 2 );

for i = 1:rows(m1_target_evts)
  m1_evt = m1_target_evts(i, :);
  m1s = m1_evt(1);
  m1e = m1_evt(2);
  
  m2_pos_evt(i, :) = nanmean( m2_pos(:, m1s:m1e), 2 );
  
  evt_diffs = m1_all_evts(:, 1) - m1s;
  m1_next_evt_ind = find( evt_diffs > 0 );  
  [~, si] = sort( evt_diffs(m1_next_evt_ind) );
  
  for j = 1:min(numel(si), num_evts_look_ahead)
    src_ind = m1_next_evt_ind(si(j));
    iei = evt_diffs(src_ind);
    m1_next_evt = m1_all_evts(src_ind, :);
    
    next_m1_pos(i, :, j) = nanmean( m1_pos(:, m1_next_evt(1):m1_next_evt(2)), 2 );
    next_m1_evt_inds(i, j) = src_ind;
    m1_iei(i, j) = iei;
  end
  
%   [min_diff, mi] = min( evt_diffs(m1_next_evt_ind) );
%   m1_next_evt_ind = m1_next_evt_ind(mi);
%   m1_next_evt = m1_all_evts(m1_next_evt_ind, :);
%   
%   if ( ~isempty(m1_next_evt_ind) )
%     next_m1_pos(i, :) = nanmean( m1_pos(:, m1_next_evt(1):m1_next_evt(2)), 2 );
%     next_m1_evt_inds(i) = m1_next_evt_ind;
%     m1_iei(i) = min_diff;
%   end
end

out = struct();
out.next_m1_pos = next_m1_pos;
out.next_m1_evt_ind = next_m1_evt_inds;
out.m1_evt_iei = m1_iei;
out.m2_pos = m2_pos_evt;

end