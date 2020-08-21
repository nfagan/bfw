%{
@T begin

import bfw.types.types

record Out
  performance: double
end

record Defaults
  discrim_type: char
	mask_func: bfw.MaskFunction
	iters: double
  p_train: double
  shuffle: logical
end

record Partition
  training: logical
  test: logical
end

end
%}

% @T :: [Out] = (double, bfw.fcat, mt.cellstr | char, ?)
function outs = fitcdiscr(data, labels, condition_cat, varargin)

assert_ispair( data, labels );
assert_hascat( labels, condition_cat );
validateattributes( data, {'double'}, {'vector'}, mfilename, 'data' );

% @T presume bfw.MaskFunction
default_mask_func = @bfw.default_mask_func;

% @T cast Defaults
defaults = struct();
defaults.discrim_type = 'pseudoLinear';
defaults.mask_func = default_mask_func;
defaults.iters = 1;
defaults.p_train = 0.75;
defaults.shuffle = false;

params = bfw.parsestruct( defaults, varargin );
mask = params.mask_func( labels, rowmask(labels) );

subset_data = data(mask);
subset_category = categorical( labels, condition_cat, mask );

perf = nan( params.iters, 1 );

for i = 1:params.iters
  use_category = subset_category;

  if ( params.shuffle )
    use_category = use_category(randperm(size(use_category, 1)), :);
  end

  % @T presume Partition
  part = cvpartition( size(subset_category, 1), 'holdout', 1-params.p_train );

  train_y = subset_data(part.training);
  train_p = use_category(part.training, :);

  test_y = subset_data(part.test);
  test_p = use_category(part.test, :);
  
  model = fitcdiscr( train_y, train_p ...
    , 'discrimtype', params.discrim_type );
  
  predicted = predict( model, test_y );
  perf(i) = pnz( predicted == test_p );
end

outs = struct();
outs.performance = perf;

end