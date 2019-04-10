conf = bfw.config.load();

roi_areas = bfw_get_roi_area( 'config', conf );
lin_events = bfw_linearize_events( 'config', conf );

rois = { 'eyes_nf', 'face', 'mouth' };

non_overlapping = bfw_exclusive_events_from_linearized_events( lin_events );
non_nan = bfw_non_nan_linearized_event_times( lin_events );

base_mask = intersect( non_overlapping, non_nan );

prev_next_outs = bfw_prev_next_events( lin_events, rois, base_mask );

%%

bfw_event_summary( lin_events, prev_next_outs, roi_areas, base_mask ...
  , 'save_figs', true ...
  , 'save_stats', true ...
  , 'base_subdir', 'per_session' ...
  , 'base_specificity', 'session' ...
  , 'is_previous', true ...
  , 'is_stim', false ...
  , 'is_roi_area_normalized', true ...
  , 'rois', rois ...
);

%%

I = findall( roi_areas.labels, 'roi' );

inds = flatten_indices( rows(roi_areas.labels), I );

use_dat = repmat( roi_areas.area, 1, 1, 3, 4, 5, 5 );
use_dat(:, end+1, :, :, :) = nan;

rowop_meds = rowop( use_dat, I, @(x) nanmedian(x, 1) );
mex_meds = bfw.row_nanmedian( use_dat, I );

assert( isequaln(rowop_meds, mex_meds) )
