%%

conf = bfw.set_dataroot( '~/Desktop/bfw' );

%%  50ms win, 50ms step

gaze_counts = ...
  shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda/reward_gaze_spikes/for_anova_class/gaze_counts.mat') );

%%  50ms win, 10ms step

gaze_counts = ...
  shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_latency/counts/gaze_counts_01.mat') );

%%  50ms win, 10ms step, right nonsocial object

gaze_counts = ...
  shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_latency/counts/gaze_counts_right_object_face_size.mat') );

%%  reload

psth_p = 'C:\data\bfw\psth\fig1_psths';
gaze_counts = bfw.load_gaze_count_files( shared_utils.io.findmat(psth_p) );

%%

sig_anova_ids = shared_utils.io.fload( '/Users/Nick/Desktop/sig_anova_ids.mat' );

%%

exclude_last_time_bin = false;
subset_t_lims = [-0.5, 0.5];
% subset_t_lims = [-0.25, 0.25];

smooth_factor = 0;
one_event_per_time_window = true;

spikes = gaze_counts.spikes;
labels = gaze_counts.labels';
start_ts = bfw.event_column( gaze_counts, 'start_time' );

event_cat = 'one-event-per-window';
addsetcat( labels, event_cat, 'mult-events-per-window' );

if ( one_event_per_time_window )
  t_min = subset_t_lims(1);
  t_max = subset_t_lims(2);
  
  evt_mask = findor( labels, {'m1', 'mutual'} );
  evt_each = { 'unified_filename', 'region', 'session', 'unit_uuid' };
  
  I = findall( labels, evt_each, evt_mask );
  evt_inds = ...
    bfw.find_non_overlapping_events_within_interval( start_ts, t_min, t_max, I );
  kept_inds = vertcat( evt_inds{:} );
  assert( numel(unique(kept_inds)) == sum(cellfun(@numel, evt_inds)) );
  
  setcat( labels, event_cat, event_cat, kept_inds );
end

[~, transform_ind] = bfw.make_whole_face_roi( labels );
spikes = spikes(transform_ind, :);
start_ts = start_ts(transform_ind);

[~, transform_ind] = bfw.make_whole_object_roi( labels );
spikes = spikes(transform_ind, :);
start_ts = start_ts(transform_ind);

time = gaze_counts.t;

subset_t = time >= subset_t_lims(1) & time <= subset_t_lims(2);
spikes = spikes(:, subset_t);
time = time(subset_t);

if ( exclude_last_time_bin )
  spikes = spikes(:, 1:end-1);
  time = time(1:end-1);
end

if ( smooth_factor > 0 )
  parfor i = 1:size(spikes, 1)
    spikes(i, :) = ...
      smoothdata( spikes(i, :), 'smoothingfactor', smooth_factor );
  end
end

%%  new

% rois = { 'whole_face', 'eyes_nf', 'face', 'nonsocial_object_eyes_nf_matched' };
% rois = { 'whole_face', 'eyes_nf' };
rois = { 'whole_face', 'eyes_nf', 'nonsocial_object_whole_face_matched', 'face', 'nonsocial_object_eyes_nf_matched' };
% rois = { {'whole_face', 'nonsocial_object_whole_face_matched'} };
% rois = { {'eyes_nf', 'face'} };
% rois = { {'eyes_nf', 'nonsocial_object_eyes_nf_matched'} };

rois = { {'whole_face', 'nonsocial_object_whole_face_matched'}, {'face', 'eyes_nf'}, {'eyes_nf', 'nonsocial_object_eyes_nf_matched'} };

soc_anova_labels = bfw_ct.load_significant_social_cell_labels_from_anova( [], true );
roi_anova_labels = bfw_ct.load_significant_roi_cell_labels_from_anova( [], true );

soc_anova_ids = soc_anova_labels(find(soc_anova_labels, 'significant'), {'unit_uuid'});
roi_anova_ids = roi_anova_labels(find(roi_anova_labels, 'significant'), {'unit_uuid'});

% plot_types = { 'hist', 'spectra', 'lines' };
plot_types = { 'hist', 'spectra' };
only_significant_cells = false;
one_event_per_time_windows = true;

use_roi_anova_labels = true;

cs = dsp3.numel_combvec( rois, plot_types, only_significant_cells ...
  , one_event_per_time_windows );

% y_lims = [ 0, 0.04 ];
y_lims = [ -0.12, 0.03 ];
% y_lims = [ -1, 1 ];
% c_lims = [ 0, 0.2 ];
c_lims = [ 0, 0.1 ];

for i = 1:size(cs, 2)
  shared_utils.general.progress( i, size(cs, 2) );
  
  c = cs(:, i);
  roi = rois{c(1)};
  plot_type = plot_types{c(2)};
  is_only_significant_cells = only_significant_cells(c(3));
  one_event_per_time_window = one_event_per_time_windows(c(4));
  
  smooth_dir = ternary( smooth_factor == 0 ...
    , 'non-smoothed', sprintf('smoothed-%0.2f', smooth_factor) );
  evt_dir = ternary( one_event_per_time_window ...
    , 'one-event-per-trial', 'no-event-restriction' );
  
  base_subdir = sprintf( '%0.2f, %0.2f', subset_t_lims(1), subset_t_lims(2) );
  base_subdir = fullfile( smooth_dir, base_subdir );
  base_subdir = fullfile( evt_dir, base_subdir );
  
  if ( use_roi_anova_labels )
    sig_anova_ids = roi_anova_ids;
  else
    sig_anova_ids = soc_anova_ids;
  end

  mask_func = @(l, m) pipe(m ...
    , @(m) fcat.mask(l, m ...
      , @findnone, bfw.nan_unit_uuid ...
      , @findor, {'m1', 'mutual'} ...
      , @find, roi ...
    ) ...
    , @(m) prune_ns_object(l, m) ...
  );

  if ( is_only_significant_cells )
    mask_func = @(l, m) fcat.mask(l, mask_func(l, m) ...
      , @findor, sig_anova_ids ...
    );

    base_subdir = fullfile( base_subdir, 'sig_only' );
  else
    base_subdir = fullfile( base_subdir, 'all_cells' );
  end
  
  if ( one_event_per_time_window )
    mask_func = @(l, m) fcat.mask(l, mask_func(l, m) ...
      , @find, 'one-event-per-window' ...
    );
  end

  bfw_plot_spike_latencies( spikes, labels', time ...
    , 'mask_func', mask_func ...
    , 'config', conf ...
    , 'base_subdir', base_subdir ...
    , 'do_save', true ...
    , 'plot_type', plot_type ...
    , 'y_lims', y_lims ...
    , 'c_lims', c_lims ...
    , 'imgauss_filter_spectra', false ...
    , 'first_trial_average', true ...
    , 'exclude_all_zero_trials', false ...
    , 'ordered_points_for_cell', false ...
    , 'n_sem_threshold', 1 ...
    , 'hist_smooth_func', @(x) smoothdata(x, 'smoothingfactor', 0.05) ...
    , 'hist_smooth_func', @identity ...
    , 'hist_gcats', {'roi'} ...
    , 'hist_pcats', {'region'} ...
  );
end

function rois = ns_obj_rois()
rois = { 'nonsocial_object', 'nonsocial_object_whole_face_matched', 'nonsocial_object_eyes_nf_matched' };
end

function m = prune_ns_object(l, m)

base_mask = bfw.find_sessions_before_nonsocial_object_was_added( ...
  l, find(l, ns_obj_rois()) );

m = setdiff( m, base_mask );

end