function defaults = acorr_main_defaults()

defaults = bfw.get_common_make_defaults();
defaults.rois = { 'eyes_nf', 'mouth', 'left_nonsocial_object', 'right_nonsocial_object' };
defaults.interval_specificity = 'roi';
defaults.freq_window = [];
defaults.peak_degree_threshold = 10;

end