%% Sort all events in ascending order by event time.

linearized_events = bfw_linearize_events();

%%  Ensure events are non-overlapping

rois = { 'eyes_nf', 'mouth', 'face' };

event_labels = linearized_events.labels';
events = linearized_events.events;
event_key = linearized_events.event_key;

[mat_labels, mat_categories] = categorical( event_labels );

start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));
start_times = events(:, event_key('start_time'));

I = findall( event_labels, 'unified_filename' );

pairs = bfw_get_non_overlapping_pairs();

non_overlapping = bfw_exclusive_events( start_indices, stop_indices, event_labels, pairs, I );

%%  label previous event

I = findall( event_labels, 'unified_filename', non_overlapping );

[prev_labs, event_intervals] = bfw_label_n_minus_n_events( start_times, event_labels', I ...
  , 'previous_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

prune( prev_labs );

%% Cound proportions of each event type

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
  , @find, rois ...
  , @findnone, '<previous_roi>' ...
  , @findnone, {'mutual', 'previous_mutual'} ...
  , @find, {'free_viewing', 'no-stimulation'} ...
  , @find, 'm1' ...
);

props_each = { 'unified_filename', 'looks_by', 'roi' };
props_of = { 'previous_roi', 'previous_looks_by' };

[counts, pltlabs] = proportions_of( labs, props_each, props_of, mask );

%%  plot

pl = plotlabeled.make_common();
% pl.y_lims = [0, 0.5];
pl.x_tick_rotation = 0;
pl.fig = figure(2);

xcats = { 'roi' };
gcats = { 'previous_roi', 'previous_looks_by' };
pcats = { 'looks_by' };

pl.bar( counts, pltlabs, xcats, gcats, pcats );

%%  Check -- make sure events are non-overlapping

% to_check = find( event_labels, {'eyes_nf', 'face', 'mouth'}, non_overlapping );
% to_check = find( event_labels, {'m1'}, to_check );
% overlapping_pairs = bfw_assert_non_overlapping( start_indices, stop_indices, I, to_check );