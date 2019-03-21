%% Load in & sort all events in ascending order by event time.

linearized_events = bfw_linearize_events();

base_plot_p = fullfile( bfw.dataroot, 'plots', 'behavior', dsp3.datedir );
base_subdir = '';

%%  Ensure events are non-overlapping

event_labels = linearized_events.labels';
events = linearized_events.events;
event_key = linearized_events.event_key;

start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));
start_times = events(:, event_key('start_time'));
stop_times = events(:, event_key('stop_time'));

I = findall( event_labels, 'unified_filename' );

pairs = bfw_get_non_overlapping_pairs();

non_overlapping = bfw_exclusive_events( start_indices, stop_indices, event_labels, pairs, I );
non_nan = find( ~isnan(start_times) & ~isnan(stop_times) );

base_mask = intersect( non_overlapping, non_nan );

%%  label previous event

rois = { 'eyes_nf', 'face', 'mouth' };

I = findall( event_labels, 'unified_filename', base_mask );

[prev_labs, prev_event_intervals] = bfw_label_n_minus_n_events( start_times, event_labels', I ...
  , 'previous_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

[next_labs, next_event_intervals] = bfw_label_n_plus_n_events( start_times, event_labels', I ...
  , 'next_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

prune( prev_labs );
prune( next_labs );

%%  N events

do_save = true;
prefix = '';
subdir = '';

uselabs = event_labels';

mask = fcat.mask( uselabs, base_mask ...
  , @find, {'no-stimulation', 'free_viewing'} ...
  , @find, {'eyes_nf', 'mouth', 'face'} ...
);

count_each = { 'session', 'roi', 'looks_by' };
[fix_labels, fix_I] = keepeach( uselabs', count_each, mask );

n_fix = cellfun( @numel, fix_I );

pl = plotlabeled.make_common();
pl.x_order = { 'eyes_nf', 'mouth' };

xcats = { 'roi' };
gcats = { 'looks_by' };
pcats = { 'id_m1' };

axs = pl.bar( n_fix, fix_labels, xcats, gcats, pcats );

if ( do_save )
  plot_p = fullfile( base_plot_p, base_subdir, 'n_events', subdir );
  plot_cats = cshorzcat( gcats, pcats );
  
  dsp3.req_savefig( gcf, plot_p, fix_labels, plot_cats, prefix );
end

%%  Event duration

do_save = true;
prefix = '';
subdir = '';

pltlabs = event_labels';
pltdat = (stop_times - start_times) * 1e3;  % s -> ms

mask = fcat.mask( pltlabs, base_mask ...
  , @find, {'no-stimulation', 'free_viewing'} ...
  , @find, {'eyes_nf', 'mouth', 'face'} ...
);

pl = plotlabeled.make_common();
pl.group_order = { 'mutual', 'm1' };
pl.x_order = { 'eyes_nf', 'mouth' };

xcats = { 'roi' };
gcats = { 'looks_by' };
pcats = { 'id_m1' };

axs = pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );

if ( do_save )
  plot_p = fullfile( base_plot_p, base_subdir, 'event_duration', subdir );
  plot_cats = cshorzcat( gcats, pcats );
  
  dsp3.req_savefig( gcf, plot_p, prune(pltlabs(mask)), plot_cats, prefix );
end

%%  Mutual initiator / terminator

do_save = true;
prefix = '';
subdir = '';

uselabs = event_labels';
is_initiator = true;

mask = fcat.mask( uselabs, base_mask ...
  , @find, 'mutual' ...
  , @find, {'eyes_nf', 'mouth', 'face'} ...
  , @find, {'no-stimulation', 'free_viewing'} ...
);

props_each = { 'session', 'roi', 'looks_by' };

[prop_initiator, init_labels] = proportions_of( uselabs', props_each, 'initiator', mask );
[prop_terminator, term_labels] = proportions_of( uselabs', props_each, 'terminator', mask );

if ( is_initiator )
  pltlabels = init_labels';
  pltdat = prop_initiator;
  
  props_of_category = 'initiator';
else
  pltlabels = term_labels';
  pltdat = prop_terminator;
  
  props_of_category = 'terminator';
end

pl = plotlabeled.make_common();
pl.x_order = { 'eyes_nf', 'mouth' };

xcats = { 'roi' };
gcats = { props_of_category };
pcats = { 'id_m1' };

axs = pl.bar( pltdat, pltlabels, xcats, gcats, pcats );

if ( do_save )
  plot_p = fullfile( base_plot_p, base_subdir, 'event_initiator_terminator', subdir );
  plot_cats = cshorzcat( gcats, pcats );
  
  dsp3.req_savefig( gcf, plot_p, pltlabels, plot_cats, prefix );
end

%% Cound proportions of each event type

is_previous = true;
is_stim = true;

if ( is_previous )
  labs = prev_labs';
  event_intervals = prev_event_intervals;
  missing_lab = '<previous_roi>';
  proportion_cats = { 'previous_roi', 'previous_looks_by' };
  
else
  labs = next_labs';
  event_intervals = next_event_intervals;
  missing_lab = '<next_roi>';
  proportion_cats = { 'next_roi', 'next_looks_by' };
end

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
  , @find, 'free_viewing' ...
  , @findnone, missing_lab ...
  , @findnone, {'mutual', 'previous_mutual', 'next_mutual'} ...
  , @find, 'm1' ...
);

if ( is_stim )
  mask = find( labs, 'm1_exclusive_event', mask );
else
  mask = find( labs, 'no-stimulation', mask );
end

props_each = { 'unified_filename', 'looks_by', 'roi' };
props_of = proportion_cats;

[counts, pltlabs] = proportions_of( labs, props_each, props_of, mask );

%%  plot

do_save = true;
prefix = '';
subdir = '';

pl = plotlabeled.make_common();
% pl.y_lims = [0, 0.5];
pl.x_tick_rotation = 0;
pl.fig = figure(2);

xcats = { 'roi' };
gcats = proportion_cats;
pcats = { 'looks_by', 'id_m1' };

axs = pl.bar( counts, pltlabs, xcats, gcats, pcats );

if ( do_save )
  plot_p = fullfile( base_plot_p, base_subdir, 'conditional_events', subdir );
  plot_cats = cshorzcat( gcats, pcats );
  
  dsp3.req_savefig( gcf, plot_p, pltlabs, plot_cats, prefix );
end


