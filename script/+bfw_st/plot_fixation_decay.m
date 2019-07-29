function plot_fixation_decay(decay_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.mask = rowmask( decay_outs.labels );

params = bfw.parsestruct( defaults, varargin );

bounds = decay_outs.bounds;
labels = decay_outs.labels';
t = decay_outs.t;

mask = get_base_mask( labels, params.mask );

plot_per_day( bounds, t, labels, mask, params );
plot_across_days( bounds, t, labels, mask, params );

end

function plot_per_day(bounds, t, labels, mask, params)

fig_cats = { 'task_type', 'session' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'roi', 'region', 'session' };

plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'per_day', params );

end


function plot_across_days(bounds, t, labels, mask, params)

fig_cats = { 'task_type' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'roi', 'region' };

plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'across_days', params );

end

function plot_combination(bounds, t, labels, mask, fig_cats, gcats, pcats, subdir, params)

fig_I = findall( labels, fig_cats, mask );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.x = t(1, :);
  
  pltdat = bounds(fig_I{i}, :);
  pltlabs = prune( labels(fig_I{i}) );
  
  axs = pl.lines( pltdat, pltlabs, gcats, pcats );
  
  if ( params.do_save )
    save_p = get_save_p( params, 'fix_decay', subdir );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, pltlabs, [fig_cats, pcats] );
  end
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_summary' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function mask = get_base_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @find, {'eyes_nf'} ...
);

end