function outs = bfw_determine_cs_reward_sensitivity_glm(reward_response, varargin)

defaults = bfw.get_common_make_defaults();
defaults.each_func = @(labels, varargin) findall(labels, 'unit_uuid', varargin{:});
defaults.time_window = [0, 0.25];
defaults.make_levels_binary = false;

params = bfw.parsestruct( defaults, varargin );

response_labels = reward_response.labels';
psth = reward_response.psth;
reward_levels = reward_response.reward_levels;

non_nan_level_ind = find( ~isnan(reward_levels) );

time_ind = make_time_index( reward_response.t, params.time_window );
cell_response = nanmean( psth(:, time_ind), 2 );

glm_I = feval( params.each_func, response_labels', non_nan_level_ind );

models = rowcell( numel(glm_I) );
model_stats = nan( numel(glm_I), 4 );

glm_labels = fcat();

for i = 1:numel(glm_I)
  mask = glm_I{i};
  
  levels = reward_levels(mask);
  response = cell_response(mask);
  
  if ( params.make_levels_binary )
    is_level1 = levels == 1;
    rest = levels > 1;
    
    assert( pnz(is_level1 | rest) == 1, 'Not all numbers accounted for.' );
    
    levels(is_level1) = 0;
    levels(rest) = 1;
  end
  
  mdl = fitglm( levels, response );
  model_stats(i, :) = get_single_term_model_stats( mdl );
    
  models{i} = mdl;
	append1( glm_labels, response_labels, mask );
end

outs = struct();
outs.models = models;
outs.labels = glm_labels;
outs.model_stats = model_stats;

if ( ~isempty(models) )
  outs.model_stats_key = models{1}.Coefficients.Properties.VariableNames;
else
  outs.model_stats_key = {};
end

end

function stats = get_single_term_model_stats(mdl)

stats = mdl.Coefficients{2, :};

end

function ind = make_time_index(t, time_window)

ind = t >= time_window(1) & t <= time_window(2);

end