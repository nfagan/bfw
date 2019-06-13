function bfw_plot_image_task_fix_info(fix_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

labs = fix_outs.labels';
fix_info = fix_outs.fix_info;

assert_ispair( fix_info, labs );

handle_labels( labs );
mask = get_base_mask( labs );

plot_total_duration( fix_info(:, 2), labs', mask, params );
plot_n_fix( fix_info(:, 1), labs', mask, params );
plot_fix_dur( fix_info(:, 2), labs', mask, params );

end

function plot_n_fix(nfix, labs, mask, params)
%%
pl = plotlabeled.make_common();

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = nfix(mask);
pltlabs = prune( labs(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  save_p = get_plot_p( params, 'n_fix' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end

end

function plot_total_duration(fixdur, labs, mask, params)

%%
pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;

sum_spec = { 'unified_filename', 'stim_frequency', 'stim_type', 'stim_id' };

[dur_labs, I] = keepeach( labs', sum_spec, mask );

total_dur = bfw.row_sum( fixdur, I );

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = total_dur;
pltlabs = dur_labs;

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  save_p = get_plot_p( params, 'total_dur' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end


end

function plot_fix_dur(fixdur, labs, mask, params)

%%
pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;

xcats = { 'stim_frequency' };
gcats = { 'stim_type' };
% pcats = { 'image_monkey' };
pcats = {};

pltdat = fixdur(mask);
pltlabs = prune( labs(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  save_p = get_plot_p( params, 'fix_dur' );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end

end

function p = get_plot_p(params, varargin)

p = fullfile( bfw.dataroot(params.config), 'plots', 'stim', 'image_task' ...
  , 'behavior', dsp3.datedir, params.base_subdir, varargin{:} );

end

function handle_labels(labs)

bfw_it.add_stim_frequency_labels( labs );
bfw_it.decompose_image_id_labels( labs );

end

function mask = get_base_mask(labels)

mask = bfw_it.find_non_error_runs( labels );

end