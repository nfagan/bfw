event_outs = bfw_linearize_events();

%%

non_nan = bfw_non_nan_linearized_event_times( event_outs );
non_overlapping_inds = bfw_exclusive_events_from_linearized_events( event_outs );
use_inds = intersect( non_nan, non_overlapping_inds );

%%

event_labs = keep( event_outs.labels', use_inds );

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;

mask = fcat.mask( event_labs ...
  , @find, {'eyes_nf', 'mouth', 'left_nonsocial_object', 'right_nonsocial_object'} ...
);

replace( event_labs, {'left_nonsocial_object', 'right_nonsocial_object'}, 'nonsocial_object' );

use_counts = ones( rows(event_labs), 1 );
[count_labs, count_I] = keepeach( event_labs', {'unified_filename', 'roi', 'looks_by'}, mask );
use_counts = bfw.row_sum( use_counts, count_I );

axs = pl.hist( use_counts, count_labs, {'roi', 'looks_by'} );

%%

pl.summary_func = @nanmedian;

meds = pl.bar( use_counts, count_labs, 'roi', 'looks_by', {} );
