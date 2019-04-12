function bfw_plot_cs_reward_sensitivity(sensitivity_outs)

model_data = sensitivity_outs.model_stats;
model_labels = sensitivity_outs.labels';

model_ps = model_data(:, strcmp(sensitivity_outs.model_stats_key, 'pValue'));
model_betas = model_data(:, strcmp(sensitivity_outs.model_stats_key, 'Estimate'));

plot_p_modulated( model_betas, model_ps, model_labels' );
plot_tuning_directions( model_betas, model_ps, model_labels' );

end

function plot_tuning_directions(model_betas, model_ps, model_labels)

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

end

function plot_p_modulated(model_betas, model_ps, model_labels)

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

end