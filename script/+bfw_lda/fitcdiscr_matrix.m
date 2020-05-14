function outs = fitcdiscr_matrix(data, labels, col_cats, condition_cat, varargin)

assert_ispair( data, labels );
assert_hascat( labels, condition_cat );
assert_hascat( labels, col_cats );

validateattributes( data, {'double'}, {'vector'}, mfilename, 'data' );

defaults = struct();
defaults.discrim_type = 'pseudoLinear';
defaults.mask_func = @bfw.default_mask_func;
defaults.iters = 1;
defaults.p_train = 0.75;
defaults.shuffle = false;

params = bfw.parsestruct( defaults, varargin );
mask = params.mask_func( labels, rowmask(labels) );

col_I = findall( labels, col_cats, mask );
cond_combs = combs( labels, condition_cat, mask );
num_cols = numel( col_I );

samplings = ...
  eachcell( @(x) eachcell(@(y) find(labels, y, x), cond_combs), col_I );
trial_counts = ...
  cat_expanded( 1, eachcell(@(x) cellfun(@numel, x), samplings) );
min_counts = min( trial_counts, [], 1 );

num_trains = floor( min_counts * params.p_train );
num_tests = min_counts - num_trains;

tot_trials_train = sum( num_trains );
tot_trials_test = sum( num_tests );

train_row_ranges = [1, cumsum(num_trains)+1];
test_row_ranges = [1, cumsum(num_tests)+1];

perf = nan( params.iters, 1 );
out_labels = repmat( append1(fcat, labels, mask), params.iters, 1 );

for i = 1:params.iters
  train_mat = nan( tot_trials_train, num_cols );
  test_mat = nan( tot_trials_test, num_cols );
  
  train_condition = cell( tot_trials_train, size(cond_combs, 1) );
  test_condition = cell( tot_trials_test, size(cond_combs, 1) );
  keep_cols = true( 1, num_cols );
  
  for j = 1:num_cols
    sample_set = samplings{j};
    sub_samplings = cell( numel(sample_set), 1 );
    test_samplings = cell( size(sub_samplings) );
    
    if ( params.shuffle )
      sample_set = shuffle_redistribute( sample_set );
    end
    
    for k = 1:numel(sample_set)
      select_n = num_trains(k);
      test_n = num_tests(k);
      full_set = sample_set{k};
      
      sampled_ind = sort( full_set(randperm(numel(full_set), select_n)) );
      remain_ind = setdiff( full_set, sampled_ind );
      test_ind = sort( remain_ind(randperm(numel(remain_ind), test_n)) );
      
      sub_samplings{k} = sampled_ind;
      test_samplings{k} = test_ind;
    end
    
    full_subset = vertcat( sub_samplings{:} );
    mu = nanmean( data(full_subset) );
    sigma = nanstd( data(full_subset) );
    
    % zscore
    for k = 1:numel(sample_set)
      train_row_range = train_row_ranges(k):(train_row_ranges(k+1)-1);
      test_row_range = test_row_ranges(k):(test_row_ranges(k+1)-1);
      
      zdat_train = (data(sub_samplings{k}) - mu) / sigma;
      zdat_test = (data(test_samplings{k}) - mu) / sigma;
      
      train_mat(train_row_range, j) = zdat_train;
      test_mat(test_row_range, j) = zdat_test;
      
      train_condition(train_row_range, :) = cond_combs(:, k);
      test_condition(test_row_range, :) = cond_combs(:, k);
    end
    
    keep_cols(j) = any( ~isnan(train_mat(:, j)) ) && ...
      any( ~isnan(test_mat(:, j)) );
  end
  
  train_mat = train_mat(:, keep_cols);
  test_mat = test_mat(:, keep_cols );
  
  model = fitcdiscr( train_mat, train_condition ...
    , 'discrimtype', params.discrim_type );
  
  predicted = predict( model, test_mat );
  perf(i) = pnz( strcmp(predicted, test_condition) );
end

outs = struct();
outs.performance = perf;
outs.labels = out_labels;
outs.mask = mask;

end

function inds = shuffle_redistribute(inds)

ns = cellfun( @numel, inds );
full_set = vertcat( inds{:} );
shuffled = full_set(randperm(numel(full_set)));

ranges = [1, cumsum(ns)+1];

for i = 1:numel(inds)
  sample_ind = ranges(i):(ranges(i+1)-1);
  inds{i} = shuffled(sample_ind);
end

end