function bfw_run_plot_cs_reward_response(reward_response, sensitivity_outs)

if ( nargin < 1 || isempty(reward_response) )
  reward_response = bfw_get_cs_reward_response( ...
    'event_names', {'cs_reward', 'cs_presentation'} ...
  );
end

%%  Determine per-unit reward sensitivity
if ( nargin < 2 || isempty(sensitivity_outs) )
  sensitivity_outs = bfw_determine_reward_sensitivity( reward_response );
end

%%  Plot prop. of significantly modulated units

bfw_plot_cs_reward_sensitivity( sensitivity_outs );

%%  Plot psth of significantly modulated units

plot_significantly_modulated_units( reward_response, sensitivity_outs );

end

function plot_significantly_modulated_units(reward_response, sensitivity_outs)

model_stats = sensitivity_outs.model_stats;

ps = model_stats(:, strcmp(sensitivity_outs.model_stats_key, 'pValue'));

is_sig = ps < 0.05;

% Get unit ids significant in at least one epoch.
sig_units = combs( sensitivity_outs.labels, 'unit_uuid', find(is_sig) );

bfw_plot_cs_reward_response( reward_response ...
  , 'base_subdir', 'significant_units_each_level' ...
  , 'base_mask', findor(reward_response.labels, sig_units) ...
  , 'do_save', true ...
);

end

