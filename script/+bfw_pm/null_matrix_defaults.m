function defaults = null_matrix_defaults()

defaults = struct();
defaults.t_window_bins = default_t_window_bins();
defaults.roi_contrasts = default_roi_contrasts();
defaults.alpha = 0.05;
defaults.n_bin_threshold = 5;
defaults.require_consecutive_bins = true;
defaults.iters = 1e3;
defaults.seed = [];

end

function contrasts = default_roi_contrasts()

contrasts = { {'m1eyes', 'm1object'}, {'m1eyes', 'm1outside1'} ...
  , {'m1eyes', 'm1noneyesface'} };

end

function bins = default_t_window_bins()

bins = { [-0.4, -0.2], [-0.2, 0], [0, 0.2], [0.2, 0.4] };

end