function bfw_determine_cs_reward_sensitivity(reward_response, varargin)

defaults = bfw.get_common_make_defaults();
defaults.each_func = @(labels) findall(labels, 'unit_uuid');
defaults.time_window = [0, 0.25];

params = bfw.parsestruct( defaults, varargin );

response_labels = reward_response.labels';

glm_I = feval( params.each_func, response_labels' );

for i = 1:numel(glm_I)
  mask = glm_I{i};
  
  
end


end