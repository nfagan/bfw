
conf = bfw.config.load();
conf.PATHS.data_root = fullfile( '/mnt/dunham', bfw_image_task_data_root() );

common_inputs = struct();
common_inputs.files_containing = {'04202019', '04222019', '04262019', '04282019', '04302019', '05052019'};
common_inputs.config = conf;
common_inputs.rect_padding = 0.05;
common_inputs.is_parallel = true;

%%

look_outs = bfw_check_image_task_stim_looking( ...
    'look_ahead', 5e3 ...
  , 'bin_size', 100 ...
  , common_inputs ...
);

%%

fix_outs = bfw_image_task_stim_fixations( ...
  'look_ahead', 5e3 ...
  , common_inputs ...
);

%%

bfw_plot_image_task_fix_info( fix_outs ...
  , 'do_save', false ...
);

%%

bfw_it.run_stim_minus_sham_fixation_decay( look_outs ...
  , 'plot_err', true ...
  , 'do_save', true ...
  , 'abs', false ...
  , 'plot_collapse', 'image_monkey' ...
);

%%

labels = look_outs.labels';

bfw_it.add_stim_frequency_labels( labels );
bfw_it.decompose_image_id_labels( labels );

mask = bfw_it.find_non_error_runs( labels );

%%  decay

do_save = false;

pl = plotlabeled.make_common();
pl.x = look_outs.t;
pl.smooth_func = @(x) smooth( x, 5 );
pl.add_smoothing = false;
pl.add_errors = true;

plt_dat = double( look_outs.bounds(mask, :) );
plt_labels = prune( labels(mask) );

gcats = { 'stim_type' };
% pcats = { 'stim_frequency', 'image_monkey' };
% fcats = { 'image_monkey' };

pcats = { 'stim_frequency' };
fcats = {};

[figs, axs, I] = pl.figures( @lines, plt_dat, plt_labels, fcats, gcats, pcats );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots', 'stim_parameter_tuning', dsp3.datedir );
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labels(I{i})), [pcats, fcats] );
  end
end
