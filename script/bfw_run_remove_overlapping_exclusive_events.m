function e_keep_inds = bfw_run_remove_overlapping_exclusive_events(i_start_stop, i_labels, e_start_stop, e_labels, i_mask, e_mask)

if ( nargin < 5 )
  i_mask = find( i_labels, 'join' );
end
if ( nargin < 6 )
  e_mask = find( e_labels, {'m1', 'm2', 'eyes_nf'} );
end

each = { 'session' };

e_keep_inds = bfw_remove_overlapping_exclusive_events( ...
    i_start_stop, i_labels, i_mask ...
  , e_start_stop, e_labels, e_mask, each ...
);

end