%% Sort all events in ascending order by event time.

linearized_events = bfw_linearize_events();

%%  Ensure events are non-overlapping

event_labels = linearized_events.labels';
events = linearized_events.events;
event_key = linearized_events.event_key;

[mat_labels, mat_categories] = categorical( event_labels );

start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));
start_times = events(:, event_key('start_time'));

rois = { 'eyes_nf', 'mouth', 'face' };

I = findall( event_labels, 'unified_filename' );

check_func = @bfw_prioritize_eyes_mouth;
% check_func = @(varargin) true;

non_overlapping = ...
  bfw_exclusiveize_events( start_indices, stop_indices, event_labels, rois, I, check_func );

%%

to_check = find( event_labels, rois, non_overlapping );
to_check = find( event_labels, {'m1'}, to_check );
overlapping_pairs = bfw_assert_non_overlapping( start_indices, stop_indices, I(1), to_check );

%%  label previous event

I = findall( event_labels, 'unified_filename', non_overlapping );

[prev_labs, event_intervals] = bfw_label_n_minus_n_events( start_times, event_labels', I ...
  , 'previous_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

prune( prev_labs );

%%

labs = prev_labs';

min_iei = -Inf;
max_iei = 5;
use_interval_thresh = true;

if ( use_interval_thresh )
  mask = find( event_intervals > min_iei & event_intervals < max_iei );
else
  mask = rowmask( labs );
end

mask = fcat.mask( labs, mask ...
  , @find, {'mouth', 'eyes_nf'} ...
  , @findnone, '<previous_roi>' ...
  , @findnone, {'mutual', 'previous_mutual'} ...
  , @find, {'free_viewing', 'no-stimulation'} ...
  , @find, 'm1' ...
);

props_each = { 'unified_filename', 'looks_by', 'roi' };
props_of = { 'previous_roi', 'previous_looks_by' };

[counts, pltlabs] = proportions_of( labs, props_each, props_of, mask );

%%

pl = plotlabeled.make_common();
% pl.y_lims = [0, 0.5];
pl.x_tick_rotation = 0;
pl.fig = figure(2);

xcats = { 'roi' };
gcats = { 'previous_roi', 'previous_looks_by' };
pcats = { 'looks_by' };

pl.bar( counts, pltlabs, xcats, gcats, pcats );

%%

use_starts = start_indices;

non_nan_starts = find( ~isnan(use_starts) );

mask = find( event_labels, rois );

for i = 1:numel(I)
  ind = intersect( I{i}, non_overlapping );
  ind = intersect( ind, non_nan_starts );
  ind = intersect( ind, mask );
  
  s = unique( use_starts(ind) );
  
  assert( numel(s) == numel(ind) );
end