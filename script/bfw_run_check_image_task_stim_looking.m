conf = bfw.config.load();
conf.PATHS.data_root = fullfile( '/mnt/dunham', bfw_image_task_data_root() );

look_outs = bfw_check_image_task_stim_looking( ...
    'is_parallel', true ...
  , 'files_containing', {'04202019', '04222019', '04262019', '04282019', '04302019'} ...
  , 'config', conf ...
  , 'rect_padding', 0.05 ...
  , 'look_ahead', 5e3 ...
  , 'bin_size', 100 ...
);

%%

% 0420 -> 100 hz
% 0422, 0426 -> 200 hz
% 0428, 0430 -> 300 hz

labels = look_outs.labels';

ind_100 = find( labels, '04202019' );
ind_200 = find( labels, {'04222019', '04262019'} );
ind_300 = find( labels, {'04282019', '04302019'} );

make_unfilename = @(day, num) sprintf('%s_image_control_%d.mat', day, num);
make_unfilenames = @(day, nums) arrayfun( @(x) make_unfilename(day, x), nums, 'un', 0 );

mask = fcat.mask( labels ...
  , @findnone, make_unfilename('04202019', 1) ...
  , @findnone, make_unfilenames('04222019', [1, 2]) ...
  , @findnone, make_unfilenames('04282019', [1:3, 8]) ...
);

freq_cat = 'stim_frequency';
addcat( labels, freq_cat );
setcat( labels, freq_cat, '100hz', ind_100 );
setcat( labels, freq_cat, '200hz', ind_200 );
setcat( labels, freq_cat, '300hz', ind_300 );

image_types = labels(:, 'image_id');
monkeys = cellfun( @(x) strsplit(x, '/'), image_types, 'un', 0 );
monkey = cellfun( @(x) sprintf('monkey-%s', x{1}), monkeys, 'un', 0 );

addsetcat( labels, 'image_monkey', monkey );

%%

do_save = true;

pl = plotlabeled.make_common();
pl.x = look_outs.t;
pl.smooth_func = @(x) smooth( x, 5 );
pl.add_smoothing = false;
pl.add_errors = true;

plt_dat = double( look_outs.bounds(mask, :) );
plt_labels = prune( labels(mask) );

gcats = { 'stim_type' };
pcats = { 'stim_frequency', 'image_monkey' };
fcats = { 'image_monkey' };

[figs, axs, I] = pl.figures( @lines, plt_dat, plt_labels, fcats, gcats, pcats );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots', 'stim_parameter_tuning', dsp3.datedir );
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labels(I{i})), [pcats, fcats] );
  end
end