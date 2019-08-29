function plot_cs_psth(reward_counts, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

psth_fig = figure(1);
raster_fig = figure(2);

pl = plotlabeled.make_common();
pl.x = reward_counts.t;
pl.add_smoothing = true;
pl.smooth_func = @(x) smooth(x, 10);

set( psth_fig, 'visible', 'off' );
set( raster_fig, 'visible', 'off' );

mask = fcat.mask( reward_counts.labels ...
  , @findnone, {'reward-NaN', bfw.nan_unit_uuid} ...
);

rasters = reward_counts.rasters;

post_plot_func = @(varargin) post_plot(rasters, raster_fig, params, varargin);

dsp3.multi_plot( @lines, reward_counts.psth, reward_counts.labels' ...
  , 'unit_uuid', 'reward-level', {'unit_uuid', 'region'} ...
  , 'mask', mask ...
  , 'pl', pl ...
  , 'configure_pl_func', @(pl) configure_pl(pl, psth_fig) ...
  , 'multiple_figures', false ...
  , 'post_plot_func', post_plot_func ...
  , 'num_outputs_from_plot_func', 'all' ...
);

end

function configure_pl(pl, fig)

set( 0, 'currentfigure', fig );
set( fig, 'visible', 'off' );
pl.fig = fig;

end

function post_plot(rasters, raster_fig, params, post_plot_inputs)

dsp3.util.post_plot.plot_rasters( rasters, raster_fig, post_plot_inputs );
save_func( raster_fig, post_plot_inputs, params );

end

function save_func(raster_fig, post_plot_inputs, params)

if ( ~params.do_save )
  return;
end

[psth_fig, labs, spec] = dsp3.util.post_plot.fig_labels_specificity( post_plot_inputs{:} );
region_subdir = char( combs(labs, 'region') );

conf = params.config;
save_p = fullfile( bfw.dataroot(conf), 'plots', 'cs_psth', dsp3.datedir, region_subdir );

psth_p = fullfile( save_p, 'psth' );
raster_p = fullfile( save_p, 'raster' );

shared_utils.plot.fullscreen( psth_fig );
shared_utils.plot.fullscreen( raster_fig );

dsp3.req_savefig( psth_fig, psth_p, labs, spec );
dsp3.req_savefig( raster_fig, raster_p, labs, spec );

end