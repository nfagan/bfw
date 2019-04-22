function outs = bfw_determine_cs_reward_sensitivity(reward_response, varargin)

defaults = bfw.get_common_make_defaults();
defaults.each_func = @(labels, varargin) findall(labels, 'unit_uuid', varargin{:});
defaults.time_window = [0, 0.25];
defaults.make_levels_binary = false;
defaults.model_type = 'glm';

params = bfw.parsestruct( defaults, varargin );

response_labels = reward_response.labels';
psth = reward_response.psth;
reward_levels = reward_response.reward_levels;
model_type = validatestring( params.model_type, {'glm', 'lda'}, mfilename );

non_nan_level_ind = find( ~isnan(reward_levels) );

time_ind = make_time_index( reward_response.t, params.time_window );
cell_response = nanmean( psth(:, time_ind), 2 );

glm_I = feval( params.each_func, response_labels', non_nan_level_ind );

models = rowcell( numel(glm_I) );
model_stats = rowcell( numel(glm_I) );

model_labels = rowcell( numel(glm_I) );

parfor i = 1:numel(glm_I)
  mask = glm_I{i};
  
  levels = reward_levels(mask);
  response = cell_response(mask);
  
  if ( params.make_levels_binary )
    is_level1 = levels == 1;
    rest = levels > 1;
    
    assert( pnz(is_level1 | rest) == 1, 'Not all reward levels accounted for.' );
    
    levels(is_level1) = 0;
    levels(rest) = 1;
  end
  
  switch ( model_type )
    case 'glm'
      [mdl, current_model_stats] = glm_model( levels, response );
    case 'lda'
      [mdl, current_model_stats] = lda_model( levels, response );
    otherwise
      error( 'Unhandled model: "%s".', model_type );
  end
    
  models{i} = mdl;
  model_labels{i} = append1( fcat(), response_labels, mask );
  model_stats{i} = current_model_stats;
end

model_stats = vertcat( model_stats{:} );
model_labels = vertcat( fcat, model_labels{:} );

outs = struct();
outs.models = models;
outs.labels = model_labels;
outs.model_stats = model_stats;
outs.params = params;

if ( ~isempty(models) )
  outs.model_stats_key = get_model_stats_key( models, model_type );
else
  outs.model_stats_key = {};
end

outs.performance = model_stats(:, strcmp(outs.model_stats_key, 'Estimate'));
outs.significance = model_stats(:, strcmp(outs.model_stats_key, 'pValue'));

end

function key = get_model_stats_key(models, model_type)

switch ( model_type )
  case 'glm'
    key = models{1}.Coefficients.Properties.VariableNames;
  case 'lda'
    key = models{1}.stats_key;
  otherwise
    error( 'Unhandled model: "%s".', model_type )
end

end

function [mdl, model_stats] = lda_model(levels, response)

partition = cvpartition( numel(levels), 'holdout', 0.25 );

train_group = levels( partition.training );
train_data = response( partition.training );

test_data = response( partition.test );
test_group = levels( partition.test );

try
  cls = classify( test_data, train_data, train_group );
  p = sum( cls(:) == test_group(:) ) / numel( test_group );
catch err
  warning( err.message );
  p = nan;
end

mdl = struct();
mdl.stats_key = { 'Estimate', 'pValue' };

% No p value calculated yet.
model_stats = [ p, nan ];

end

function [mdl, model_stats] = glm_model(levels, response)

mdl = fitglm( levels, response );
model_stats = get_single_term_glm_model_stats( mdl );

end

function stats = get_single_term_glm_model_stats(mdl)

stats = mdl.Coefficients{2, :};

end

function ind = make_time_index(t, time_window)

ind = t >= time_window(1) & t <= time_window(2);

end