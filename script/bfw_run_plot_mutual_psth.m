conf = bfw.config.load();

psth_outs = bfw_mutual_psth( ...
    'mask_func', @(labels) find(labels, {'eyes_nf', 'face'}) ...
  , 'config', conf ...
  , 'is_parallel', false ...
  , 'files_containing', '01092019' ...
);

%%

bfw_plot_mutual_psth( psth_outs ...
  , 'do_save', true ...
  , 'base_subdir', 'per_unit' ...
);