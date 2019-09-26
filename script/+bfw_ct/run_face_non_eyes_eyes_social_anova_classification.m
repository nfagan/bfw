gaze_counts = bfw_ct.load_eye_non_eye_face_nonsocial_object_gaze_counts();

%%

spike_meta_data = bfw_load_consolidated_spike_meta_data();

%%

mask_func = @(labels) fcat.mask(labels ...
  , @bfw_ct.mask_cc_unit_meta_data, spike_meta_data ...
  , @findnone, 'face' ...
);

t_windows = { [-0.1, 0], [-0.25, 0], [0, 0.25] };
% t_windows = { [-0.1, 0] };
base_prefix = 'main_effect_significant/';

for i = 1:numel(t_windows)
  counts = gaze_counts;
  t_window = t_windows{i};
  base_subdir = sprintf( '%s%d_%d', base_prefix, t_window*1e3 );

  t_ind = counts.t >= t_window(1) & counts.t <= t_window(2);
  counts.spikes = nanmean( counts.spikes(:, t_ind), 2 );

  anova_outs = bfw_ct.anova_classification( counts ...
    , 'do_save', true ...
    , 'base_subdir', base_subdir ...
    , 'post_hoc_denominator_significant_cells', false ...
    , 'post_hoc_require_main_effect_significant', true ...
    , 'mask_func', mask_func ...
  );
end