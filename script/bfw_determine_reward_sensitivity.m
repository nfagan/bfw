function sensitivity_outs = bfw_determine_reward_sensitivity(reward_response)

base_mask = find( reward_response.labels, 'no-error' );
sens_each = { 'unit_uuid', 'event-name', 'session' };

each_func = @(labels, mask) findall(labels, sens_each, intersect(mask, base_mask));

sensitivity_outs = bfw_determine_cs_reward_sensitivity_glm( reward_response ...
  , 'each_func', each_func ...
  , 'time_window', [0, 0.4] ...
  , 'make_levels_binary', false ...
);

end