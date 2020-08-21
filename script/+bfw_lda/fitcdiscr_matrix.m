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
defaults.resample_to_larger_n = false;
defaults.model_type = 'lda';
defaults.bag_size = 200;

params = bfw.parsestruct( defaults, varargin );
model_type = validatestring( params.model_type, {'lda', 'bagged_trees'} ...
  , mfilename, 'model_type' );
mask = params.mask_func( labels, rowmask(labels) );

col_I = findall( labels, col_cats, mask );
cond_combs = combs( labels, condition_cat, mask );
num_cols = numel( col_I );

samplings = ...
  eachcell( @(x) eachcell(@(y) find(labels, y, x), cond_combs), col_I );
trial_counts = ...
  cat_expanded( 1, eachcell(@(x) cellfun(@numel, x), samplings) );
min_counts = min( trial_counts, [], 1 );

if ( params.resample_to_larger_n )
  mm_counts = max( min_counts );
  num_trains = repmat( floor(mm_counts * params.p_train), size(min_counts) );
  num_tests = mm_counts - num_trains;
else
  num_trains = floor( min_counts * params.p_train );
  num_tests = min_counts - num_trains;
end

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
    is_ok = true;
    
    if ( params.shuffle )
      sample_set = shuffle_redistribute( sample_set );
    end
    
    for k = 1:numel(sample_set)
      train_n = num_trains(k);
      test_n = num_tests(k);
      full_set = sample_set{k};
      
      if ( params.resample_to_larger_n )
        % Divide `full_set` into separate training and test sets according
        % to `p_train`. Resample each set to contain `train_n` and `test_n`
        % members, respectively.
        num_holdout = ceil( (1-params.p_train) * numel(full_set) );
        can_test = sort( full_set(randperm(numel(full_set), num_holdout)) );
        can_train = setdiff( full_set, can_test );
        
        try
          to_train_ind = randi( numel(can_train), train_n, 1 );
          to_test_ind = randi( numel(can_test), test_n, 1 );
        catch err
          is_ok = false;
          warning( err.message );
          break;
        end
        
        train_ind = sort( can_train(to_train_ind) );
        test_ind = sort( can_test(to_test_ind) );
      else
        train_ind = sort( full_set(randperm(numel(full_set), train_n)) );
        remain_ind = setdiff( full_set, train_ind );
        test_ind = sort( remain_ind(randperm(numel(remain_ind), test_n)) );
      end
      
      sub_samplings{k} = train_ind;
      test_samplings{k} = test_ind;
    end
    
    if ( ~is_ok )
      keep_cols(j) = false;
      continue;
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
  
  if ( ~isempty(train_mat) && ~isempty(test_mat) )
    if ( strcmp(model_type, 'lda') )
      model = fitcdiscr( train_mat, train_condition ...
      , 'discrimtype', params.discrim_type );
    
    elseif ( strcmp(model_type, 'bagged_trees') )
      model = fitensemble( train_mat, train_condition ...
        , 'Bag', params.bag_size, 'Tree' ...
        , 'Type', 'Classification' ...
      );
    
    else
      error( 'Unrecognized model type "%s".', model_type );
    end

    predicted = predict( model, test_mat );
    perf(i) = pnz( strcmp(predicted, test_condition) );
  end
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