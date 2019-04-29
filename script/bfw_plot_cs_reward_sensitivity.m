function bfw_plot_cs_reward_sensitivity(sensitivity_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

model_data = sensitivity_outs.model_stats;
model_labels = sensitivity_outs.labels';

model_ps = model_data(:, strcmp(sensitivity_outs.model_stats_key, 'pValue'));
model_betas = model_data(:, strcmp(sensitivity_outs.model_stats_key, 'Estimate'));

plot_p_modulated( model_betas, model_ps, model_labels', params );
plot_tuning_directions( model_betas, model_ps, model_labels', params );

end

function save_p = get_base_save_p(params)

data_root = bfw.dataroot( params.config );

save_p = fullfile( data_root, 'plots', 'cs_reward_sensitivity', dsp3.datedir ...
  , params.base_subdir );

end

function plot_tuning_directions(model_betas, model_ps, model_labels, params)

is_pos_estimate = model_betas >= 0;
is_sig = double( model_ps < 0.05 );

addsetcat( model_labels, 'tuning-direction', 'negative' );
setcat( model_labels, 'tuning-direction', 'positive', find(is_pos_estimate) );

addsetcat( model_labels, 'is-significant', 'not-significant' );
setcat( model_labels, 'is-significant', 'significant', find(is_sig) );

props_each = { 'event-name', 'region', 'is-significant' };
props_of = 'tuning-direction';

mask = fcat.mask( model_labels ...
  , @findnone, 'unit_uuid__NaN' ...
  , @find, 'significant' ...
);

[props, prop_labels] = proportions_of( model_labels', props_each, props_of, mask );

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;
pl.fig = figure(2);

xcats = { 'event-name' };
gcats = { 'tuning-direction' };
pcats = { 'region' };

axs = pl.bar( props, prop_labels, xcats, gcats, pcats );

if ( params.do_save )
  save_p = fullfile( get_base_save_p(params), 'tuning_direction' );
  dsp3.req_savefig( gcf, save_p, prop_labels, [pcats, gcats] );
end

end

function plot_p_modulated(model_betas, model_ps, model_labels, params)

is_sig = double( model_ps < 0.05 );

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;

mask = fcat.mask( model_labels ...
  , @findnone, 'unit_uuid__NaN' ...
);

xcats = { 'event-name' };
gcats = { 'region' };
pcats = { };

axs = pl.bar( is_sig(mask), model_labels(mask), xcats, gcats, pcats );

arrayfun( @(x) ylabel(x, 'Prop. Significant Units'), axs );

if ( params.do_save )
  save_p = fullfile( get_base_save_p(params), 'p_modulated' );
  dsp3.req_savefig( gcf, save_p, model_labels(mask), [pcats, gcats] );
end

end