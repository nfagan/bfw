function outs = population_decode_gaze_from_reward(gaze_counts, reward_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.gaze_t_window = [ 0.1, 0.4];  % s
defaults.reward_t_window = [ 0.1, 0.4 ];  % s
defaults.target_t_window = [ 0.1, 0.4 ];
defaults.n_iters = 1000;
defaults.rng_seed = 1;
defaults.base_gaze_mask = rowmask( gaze_counts.labels );
defaults.base_reward_mask = rowmask( reward_counts.labels );
defaults.condition_threshold = 5;
defaults.p_train = 0.75;
defaults.train_on = 'reward';
defaults.test_on = 'gaze';
defaults.match_trials = false;
defaults.match_units = false;
defaults.require_fixation = true;
defaults.fixation_duration = 0.4;
defaults.reward_level0 = 1;
defaults.reward_level1 = 3;
defaults.is_train_x_test_x_timecourse = false;

params = bfw.parsestruct( defaults, varargin );
train_on = validatestring( params.train_on, {'reward', 'gaze'} );
test_on = validatestring( params.test_on, {'reward', 'gaze'} );

rwd_level0 = params.reward_level0;
rwd_level1 = params.reward_level1;

reward_counts.reward_levels = ...
  binarize_levels( reward_counts.reward_levels, rwd_level0, rwd_level1 );

keep_reward = reward_criterion( reward_counts, params );
keep_gaze = gaze_criterion( gaze_counts, params );

shared_ids = get_shared_unit_ids( reward_counts.labels, gaze_counts.labels ...
  , keep_reward, keep_gaze );

keep_reward = find( reward_counts.labels, shared_ids, keep_reward );
keep_gaze = find( gaze_counts.labels, shared_ids, keep_gaze );

gaze_window = params.gaze_t_window;
rwd_window = params.reward_t_window;

[gaze_window, rwd_window, t_series] = get_time_windows( gaze_window, rwd_window );

all_perf = cell( 1, numel(gaze_window) );

for i = 1:numel(gaze_window)
  shared_utils.general.progress( i, numel(gaze_window) );
  
  gaze_t = gaze_window{i};
  reward_t = rwd_window{i};
  
  gaze_labels = gaze_counts.labels';
  rwd_labels = reward_counts.labels';
  
  unify_regions( gaze_labels, rwd_labels );

  collapsed_rwd = reward_counts.psth;
  collapsed_gaze = gaze_counts.spikes;
  
  if ( ~params.is_train_x_test_x_timecourse )
    collapsed_rwd = collapse_counts( reward_counts.psth, reward_counts.t, reward_t );
    collapsed_gaze = collapse_counts( gaze_counts.spikes, gaze_counts.t, gaze_t );
  end
  
  if ( params.match_units )
    [keep_gaze, keep_reward] = match_units( gaze_labels, rwd_labels, keep_gaze, keep_reward, params );
  end

  collapsed_rwd = indexpair( collapsed_rwd, rwd_labels, keep_reward );
  collapsed_gaze = indexpair( collapsed_gaze, gaze_labels, keep_gaze );

  reward_inputs = struct();
  reward_inputs.levels = reward_counts.reward_levels(keep_reward);
  reward_inputs.labels = rwd_labels;
  reward_inputs.spikes = collapsed_rwd;
  reward_inputs.t = reward_counts.t;
  reward_inputs.test_t_window = reward_t;

  gaze_inputs = struct();
  gaze_inputs.labels = gaze_labels;
  gaze_inputs.spikes = collapsed_gaze;
  gaze_inputs.t = gaze_counts.t;
  gaze_inputs.test_t_window = gaze_t;

  if ( strcmp(train_on, 'reward') && strcmp(test_on, 'gaze') )
    [perf, labels] = run_train_reward_test_gaze( reward_inputs, gaze_inputs, params );
  elseif ( strcmp(train_on, 'gaze') && strcmp(test_on, 'reward') )
    [perf, labels] = run_train_gaze_test_reward( reward_inputs, gaze_inputs, params );
  elseif ( strcmp(train_on, 'gaze') && strcmp(test_on, 'gaze') )
    [perf, labels] = run_train_gaze_test_gaze(  gaze_inputs, params );
  elseif ( strcmp(train_on, 'reward') && strcmp(test_on, 'reward') )
    [perf, labels] = run_train_reward_test_reward( reward_inputs, params );
  else
    error( 'Unrecognized combination: train on "%s"; test on "%s".', train_on, test_on );
  end
  
  all_perf{i} = perf;
end

outs = struct();
outs.performance = horzcat( all_perf{:} );
outs.labels = labels;
outs.t = t_series;
outs.params = params;

end

function [gaze_mask, reward_mask] = match_units(gaze, reward, gaze_mask, reward_mask, params)

%%

rng( params.rng_seed );

[region_I, region_C] = findall( gaze, 'region', gaze_mask );
[region_I, region_C] = sort_combinations( region_I, region_C );

n_units = zeros( numel(region_I), 1 );
unit_ids_per_region = {};
all_unit_id_I= {};

for i = 1:numel(region_I)
  [unit_id_I, unit_id_C] = findall( gaze, {'unit_uuid', 'session'}, region_I{i} );
  [unit_id_I, unit_id_C] = sort_combinations( unit_id_I, unit_id_C );
  
  unit_ids_per_region{i} = unit_id_C;
  all_unit_id_I{i} = unit_id_I;
  n_units(i) = numel( unit_id_I );
end

min_units = min( n_units );

gaze_keep_ind = false( rows(gaze), 1 );
rwd_keep_ind = false( rows(reward), 1 );

for i = 1:numel(region_I)
  reward_region_mask = find( reward, region_C(:, i), reward_mask );
  
  [reward_unit_I, reward_unit_C] = findall( reward, {'unit_uuid', 'session'}, reward_region_mask );
  [reward_unit_I, reward_unit_C] = sort_combinations( reward_unit_I, reward_unit_C );
  
  gaze_unit_I = all_unit_id_I{i};
  
  assert( numel(reward_unit_I) == n_units(i) );
  
  if ( n_units(i) > min_units )
    samp_units = randperm( n_units(i), min_units );
    
    gaze_unit_I = gaze_unit_I(samp_units);
    reward_unit_I = reward_unit_I(samp_units);
  end
  
  for j = 1:numel(reward_unit_I)
    rwd_keep_ind(reward_unit_I{j}) = true;
    gaze_keep_ind(gaze_unit_I{j}) = true;
  end
end

gaze_mask = find( gaze_keep_ind );
reward_mask = find( rwd_keep_ind );

rng( 'shuffle' );

end

function [I, C] = sort_combinations(I, C)

c = categorical( C )';
[~, sort_ind] = sortrows( c );

I = I(sort_ind);
C = C(:, sort_ind);

end

function [gaze, reward, t_series] = get_time_windows(gaze, reward)

assert( ~(iscell(gaze) && iscell(reward)) ...
  , 'Only one time window (either gaze or reward can be cell.' );

match_cell = @(x, y) repmat({x}, numel(y), 1);
get_t_series = @(y) cellfun(@(x) min(x), y);

if ( iscell(gaze) )
  reward = match_cell( reward, gaze );
  t_series = get_t_series( gaze );
elseif ( iscell(reward) )
  gaze = match_cell( gaze, reward );
  t_series = get_t_series( reward );
else
  gaze = { gaze };
  reward = { reward };
  t_series = nan; % one time window only
end

end

function unify_regions(gaze_labels, rwd_labels)

bfw.unify_single_region_labels( gaze_labels );
bfw.unify_single_region_labels( rwd_labels );

prune( rwd_labels );
prune( gaze_labels );

end

function levels = binarize_levels(levels, lvl0, lvl1)

orig_ind = levels == lvl0 | levels == lvl1;

levels(levels == lvl0) = 0;
levels(levels == lvl1) = 1;

levels(~orig_ind) = nan;

end

function [rois, roi_pair_inds, n_pairs] = get_roi_combinations(gaze_labels)

rois = sort( combs(gaze_labels, 'roi') );
roi_pair_inds = nchoosek( 1:numel(rois), 2 );
n_pairs = size( roi_pair_inds, 1 );

end

function [perf, labels] = run_train_gaze_test_reward(rwd_inputs, gaze_inputs, params)

[rois, roi_pair_inds, n_pairs] = get_roi_combinations( gaze_inputs.labels );

perf = cell( n_pairs, 1 );
labels = cell( n_pairs, 1 );

parfor i = 1:n_pairs
  pair_ind = roi_pair_inds(i, :);
  
  roi_a = rois{pair_ind(1)};
  roi_b = rois{pair_ind(2)};
  
  [roi_a, roi_b] = roi_order( roi_a, roi_b );
  
  [one_perf, one_labels] = train_gaze_test_reward( rwd_inputs, gaze_inputs, roi_a, roi_b, params );
  
  perf{i} = one_perf;
  labels{i} = one_labels;
end

perf = vertcat( perf{:} );
labels = vertcat( fcat(), labels{:} );

end

function [perf, labels] = run_train_reward_test_gaze(rwd_inputs, gaze_inputs, params)

[rois, roi_pair_inds, n_pairs] = get_roi_combinations( gaze_inputs.labels );

perf = cell( n_pairs, 1 );
labels = cell( n_pairs, 1 );

parfor i = 1:n_pairs
  pair_ind = roi_pair_inds(i, :);
  
  roi_a = rois{pair_ind(1)};
  roi_b = rois{pair_ind(2)};
  
  [roi_a, roi_b] = roi_order( roi_a, roi_b );
  
  [one_perf, one_labels] = train_reward_test_gaze( rwd_inputs, gaze_inputs, roi_a, roi_b, params );
  
  perf{i} = one_perf;
  labels{i} = one_labels;
end

perf = vertcat( perf{:} );
labels = vertcat( fcat(), labels{:} );

end

function [performance, perf_labels] = train_reward_test_gaze(reward, gaze, roi_a, roi_b, params)

% rng( params.rng_seed );

n_iters = params.n_iters;

% High or low reward.
levels = reward.levels;
reward_ind = find( levels == 0 | levels == 1 );
reward_I = findall( reward.labels, {'region', 'event-name'}, reward_ind );

roi_ind = find( gaze.labels, {roi_a, roi_b} );

performance = nan( numel(reward_I) * n_iters, 1 );
perf_labels = fcat();
stp = 1;

for i = 1:numel(reward_I)
  rng( params.rng_seed );
  
  shared_utils.general.progress( i, numel(reward_I) );
  
  [unit_I, unit_ids] = findall( reward.labels, 'unit_uuid', reward_I{i} );
  gaze_ind = find( gaze.labels, unit_ids, roi_ind );
  
  min_zeros = min( cellfun(@(x) sum(levels(x) == 0), unit_I) );
  min_ones = min( cellfun(@(x) sum(levels(x) == 1), unit_I) );
  
  if ( params.match_trials )
    abs_min = min( min_zeros, min_ones );
    min_zeros = abs_min;
    min_ones = abs_min;
  end
  
  assert( min_zeros >= params.condition_threshold && ...
    min_ones >= params.condition_threshold, 'Too few.' );
  
  n_tot = min_zeros + min_ones;
  
  search_vec = [ zeros(min_zeros, 1); ones(min_ones, 1) ];
  search_vec = search_vec(randperm(n_tot));
  
  n_train = floor( params.p_train * n_tot );
  
  for j = 1:n_iters
    train_cond = search_vec(randperm(n_tot, n_train));
    is_train_one = train_cond == 1;
    is_train_zero = train_cond == 0;
    
    n_one = nnz( is_train_one );
    n_zero = nnz( is_train_zero );
    
    train_data = nan( n_train, numel(unit_I) );
    train_stats = nan( numel(unit_I), 2 );
    keep_units = true( numel(unit_I), 1 );
    
    for k = 1:numel(unit_I)
      unit_ind = unit_I{k};
      
      levels_this_unit = levels(unit_ind);
      ones_this_unit = find( levels_this_unit == 1 );
      zeros_this_unit = find( levels_this_unit == 0 );
      
      use_ones = ones_this_unit(randperm(numel(ones_this_unit), n_one));
      use_zeros = zeros_this_unit(randperm(numel(zeros_this_unit), n_zero));
      
      full_ind_one = unit_ind(use_ones);
      full_ind_zero = unit_ind(use_zeros);
      
      train_one = reward.spikes(full_ind_one);
      train_zero = reward.spikes(full_ind_zero);
      
      train_dat = nan( n_train, 1 );
      train_dat(is_train_one) = train_one;
      train_dat(is_train_zero) = train_zero;
      
      mean_train = nanmean( train_dat );
      dev_train = nanstd( train_dat );
      
      if ( dev_train == 0 )
        keep_units(k) = false;
        continue;
      end
      
      train_stats(k, :) = [ mean_train, dev_train ];
      train_data(:, k) = ( train_dat - mean_train ) ./ dev_train;
    end
    
    reward_model = fitcdiscr( train_data(:, keep_units), train_cond, 'discrimtype', 'pseudoLinear' );
    
    %%
    
    kept_unit_ids = unit_ids(keep_units);
    kept_stats = train_stats(keep_units, :);
    
    [gaze_x, class_label] = get_other_distribution( gaze, gaze_ind, kept_unit_ids, kept_stats, roi_a, roi_b ); 
    
    classified = predict( reward_model, gaze_x );
    performance(stp) = sum( classified == class_label ) / numel( class_label );
    
    stp = stp + 1;    
  end
  
  reward_labs = reward.labels';
  gaze_labs = one( gaze.labels(gaze_ind) );
  
  join( reward_labs, gaze_labs );
  setcat( reward_labs, 'roi', sprintf('%s/%s', roi_a, roi_b) );
  
  append1( perf_labels, reward_labs, unit_I{i}, n_iters );
end

end

function [performance, perf_labels] = train_gaze_test_reward(reward, gaze, roi_a, roi_b, params)

%%

n_iters = params.n_iters;

gaze_ind = find( gaze.labels, {roi_a, roi_b} );

region_I = findall( gaze.labels, 'region', gaze_ind );
reward_I = findall( reward.labels, {'event-name'} );

reward_labs = reward.labels';
addsetcat( reward_labs, 'tmp-reward-level', 'tmp-reward-0', find(reward.levels == 0) );
setcat( reward_labs, 'tmp-reward-level', 'tmp-reward-1', find(reward.levels == 1) );
reward.labels = reward_labs;

performance = nan( numel(reward_I) * n_iters * numel(region_I), 1 );
perf_labels = fcat();
stp = 1;

for i = 1:numel(region_I)
  rng( params.rng_seed );
  
  [unit_I, unit_C] = findall( gaze.labels, {'unit_uuid', 'session'}, region_I{i} );
  unit_ids = unit_C(1, :);
  
  min_zeros = min_combination( gaze.labels, roi_b, unit_I );
  min_ones = min_combination( gaze.labels, roi_a, unit_I );
  
  if ( params.match_trials )
    abs_min = min( min_zeros, min_ones );
    min_zeros = abs_min;
    min_ones = abs_min;
  end
  
  n_tot = min_zeros + min_ones;
  
  search_vec = [ zeros(min_zeros, 1); ones(min_ones, 1) ];
  search_vec = search_vec(randperm(n_tot));
  
  n_train = floor( params.p_train * n_tot );
  
  for j = 1:n_iters
    train_cond = search_vec(randperm(n_tot, n_train));
    is_train_one = train_cond == 1;
    is_train_zero = train_cond == 0;
    
    n_one = nnz( is_train_one );
    n_zero = nnz( is_train_zero );
    
    train_data = nan( n_train, numel(unit_I) );
    train_stats = nan( numel(unit_I), 2 );
    keep_units = true( numel(unit_I), 1 );
    
    for k = 1:numel(unit_I)
      unit_ind = unit_I{k};
      
      ones_this_unit = find( gaze.labels, roi_a, unit_ind );
      zeros_this_unit = find( gaze.labels, roi_b, unit_ind );
      
      use_ones = ones_this_unit(randperm(numel(ones_this_unit), n_one));
      use_zeros = zeros_this_unit(randperm(numel(zeros_this_unit), n_zero));
      
      train_one = gaze.spikes(use_ones);
      train_zero = gaze.spikes(use_zeros);
      
      train_dat = nan( n_train, 1 );
      train_dat(is_train_one) = train_one;
      train_dat(is_train_zero) = train_zero;
      
      mean_train = nanmean( train_dat );
      dev_train = nanstd( train_dat );
      
      if ( dev_train == 0 )
        keep_units(k) = false;
        continue;
      end
      
      train_stats(k, :) = [ mean_train, dev_train ];
      train_data(:, k) = ( train_dat - mean_train ) ./ dev_train;
    end
    
    gaze_model = fitcdiscr( train_data(:, keep_units), train_cond, 'discrimtype', 'pseudoLinear' );
    
    kept_unit_ids = unit_ids(keep_units);
    kept_stats = train_stats(keep_units, :);
    
    for k = 1:numel(reward_I)
      rwd_ind = reward_I{k};
      
      lvl0 = 'tmp-reward-0';
      lvl1 = 'tmp-reward-1';
      
      % Order is switched.
      [rwd_x, class_label] = get_other_distribution( reward, rwd_ind, kept_unit_ids, kept_stats, lvl1, lvl0 );
      
      classified = predict( gaze_model, rwd_x );
      performance(stp) = sum( classified == class_label ) / numel( class_label );
      
      gaze_labels = gaze.labels';
      rwd_labels = one( reward.labels(rwd_ind) );
      
      join( gaze_labels, rwd_labels );
      setcat( gaze_labels, 'roi', sprintf('%s/%s', roi_a, roi_b) );

      append1( perf_labels, gaze_labels, unit_I{i} );

      stp = stp + 1;    
    end
  end
end

end

function [perf, labels] = run_train_reward_test_reward(reward_inputs, params)

%%
reward_labels = reward_inputs.labels';
rwd_cat = 'reward-level';

collapsecat( reward_labels, rwd_cat );
setcat( reward_labels, rwd_cat, 'reward-0', find(reward_inputs.levels == 0) );
setcat( reward_labels, rwd_cat, 'reward-1', find(reward_inputs.levels == 1) );
reward_inputs.labels = reward_labels;

mask = find( reward_inputs.levels == 0 | reward_inputs.levels == 1 );

region_I = findall( reward_inputs.labels, {'region', 'event-name'}, mask );

perf = cell( numel(region_I), 1 );
labels = cell( size(perf) );

for i = 1:numel(region_I)
  rwd0 = 'reward-0';
  rwd1 = 'reward-1';
  
  [one_perf, one_labels] = train_x_test_x( reward_inputs, rwd0, rwd1, region_I{i}, params );
  setcat( one_labels, rwd_cat, sprintf('%s/%s', rwd0, rwd1) );

  perf{i} = one_perf;
  labels{i} = one_labels;
end

perf = vertcat( perf{:} );
labels = vertcat( fcat(), labels{:} );

end

function [perf, labels] = run_train_gaze_test_gaze(gaze_inputs, params)

[rois, roi_pair_inds, n_pairs] = get_roi_combinations( gaze_inputs.labels );

perf = cell( n_pairs, 1 );
labels = cell( size(perf) );

parfor i = 1:n_pairs
  shared_utils.general.progress( i, n_pairs );
  
  pair_ind = roi_pair_inds(i, :);
  
  roi_a = rois{pair_ind(1)};
  roi_b = rois{pair_ind(2)};
  
  [roi_a, roi_b] = roi_order( roi_a, roi_b );
  mask = find( gaze_inputs.labels, {roi_a, roi_b} );
  
  region_I = findall( gaze_inputs.labels, {'region'}, mask );
  
  tmp_perf = [];
  tmp_labs = fcat();
  
  for k = 1:numel(region_I)
    % Switch such that a is 1, b is 0, for consistency.
    [one_perf, one_labels] = train_x_test_x( gaze_inputs, roi_b, roi_a, region_I{k}, params );
    setcat( one_labels, 'roi', sprintf('%s/%s', roi_a, roi_b) );
    
    tmp_perf = [ tmp_perf; one_perf ];
    append( tmp_labs, one_labels );
  end
  
  perf{i} = tmp_perf;
  labels{i} = tmp_labs;
end

perf = vertcat( perf{:} );
labels = vertcat( labels{:} );

end

function [performance, perf_labels] = train_x_test_x(spike_inputs, level0, level1, mask, params)

%%

rng( params.rng_seed );

n_iters = params.n_iters;

[unit_I, unit_C] = findall( spike_inputs.labels, {'unit_uuid', 'session'}, mask );

min_zero = min_combination( spike_inputs.labels, level0, unit_I );
min_one = min_combination( spike_inputs.labels, level1, unit_I );

assert( min_zero >= params.condition_threshold && ...
  min_one >= params.condition_threshold, 'Too few.' );

if ( params.match_trials )
  abs_min = min( min_zero, min_one );
  min_zero = abs_min;
  min_one = abs_min;
end

if ( params.is_train_x_test_x_timecourse )
  target_t_ind = spike_inputs.t >= params.target_t_window(1) & ...
    spike_inputs.t <= params.target_t_window(2);
  test_t_ind = spike_inputs.t >= spike_inputs.test_t_window(1) & ...
    spike_inputs.t <= spike_inputs.test_t_window(2);
end

n_tot = min_zero + min_one;
n_train = floor( params.p_train * n_tot );
n_test = n_tot - n_train;

search_vec = [ zeros(min_zero, 1); ones(min_one, 1) ];

performance = nan( n_iters, 1 );
perf_labels = append1( fcat(), spike_inputs.labels, mask, n_iters );

train_x = nan( n_train, numel(unit_I) );
test_x = nan( n_test, numel(unit_I) );
ok_units = true( numel(unit_I), 1 );

for i = 1:n_iters
  search_vec = search_vec(randperm(n_tot));
  train_condition = search_vec(1:n_train);
  test_condition = search_vec(n_train+1:end);
  
  train0 = train_condition == 0;
  train1 = train_condition == 1;
  test0 = test_condition == 0;
  test1 = test_condition == 1;
  
  ok_units(:) = true;
  train_x(:) = nan;
  test_x(:) = nan;
  
  for k = 1:numel(unit_I)
    unit_ind = unit_I{k};
    
    [level0_ind, level1_ind] = find_levels( spike_inputs.labels, level0, level1, unit_ind );
    [train0_ind, train1_ind] = sample_levels( level0_ind, level1_ind, nnz(train0), nnz(train1) );
    
    test_ind = setdiff( unit_ind, [train0_ind; train1_ind] );
    ind0 = intersect( test_ind, level0_ind );
    ind1 = intersect( test_ind, level1_ind );
    
    [test0_ind, test1_ind] = sample_levels( ind0, ind1, nnz(test0), nnz(test1) );

    if ( params.is_train_x_test_x_timecourse )
      train_x(train0, k) = nansum( spike_inputs.spikes(train0_ind, target_t_ind), 2 );
      train_x(train1, k) = nansum( spike_inputs.spikes(train1_ind, target_t_ind), 2 );
    else
      train_x(train0, k) = spike_inputs.spikes(train0_ind);
      train_x(train1, k) = spike_inputs.spikes(train1_ind);
    end
    
    mean_train = nanmean(train_x(:, k));
    dev_train = nanstd(train_x(:, k));
    
    train_x(:, k) = zscore( train_x(:, k), mean_train, dev_train );
    
    if ( isnan(dev_train) || dev_train == 0 || isnan(mean_train) )
      ok_units(k) = false;
      continue;
    end
    
    if ( params.is_train_x_test_x_timecourse )
      tmp0 = nansum( spike_inputs.spikes(test0_ind, test_t_ind), 2 );
      tmp1 = nansum( spike_inputs.spikes(test1_ind, test_t_ind), 2 );
    else
      tmp0 = spike_inputs.spikes(test0_ind);
      tmp1 = spike_inputs.spikes(test1_ind);
    end

    test_x(test0, k) = zscore( tmp0, mean_train, dev_train );
    test_x(test1, k) = zscore( tmp1, mean_train, dev_train );
  end
  
  mdl = fitcdiscr( train_x(:, ok_units), train_condition, 'discrimtype', 'pseudoLinear' );
  predicted = predict( mdl, test_x(:, ok_units) );
  
  performance(i) = sum( predicted == test_condition ) / numel( test_condition );
end

end

function d = zscore(d, m, s)

d = (d - m) ./ s;

end

function [ind0, ind1] = find_levels(labels, level0, level1, mask)

ind0 = find( labels, level0, mask );
ind1 = find( labels, level1, mask );

end

function [samp_ind0, samp_ind1] = sample_levels(ind0, ind1, n0, n1)

samp_ind0 = ind0(randperm(numel(ind0), n0));
samp_ind1 = ind1(randperm(numel(ind1), n1));

end

function [X, Y] = get_other_distribution(gaze, gaze_ind, unit_ids, stats, roi_a, roi_b)

%%

gaze_ind = find( gaze.labels, unit_ids, gaze_ind );

gaze_unit_I = findall( gaze.labels, 'unit_uuid', gaze_ind );
n_one = min_combination( gaze.labels, roi_a, gaze_unit_I );
n_zero = min_combination( gaze.labels, roi_b, gaze_unit_I );
n_tot = n_one + n_zero;

X = nan( n_tot, numel(unit_ids) );
Y = [ ones(n_one, 1); zeros(n_zero, 1) ];

for i = 1:numel(gaze_unit_I)
  roi_a_ind = find( gaze.labels, roi_a, gaze_unit_I{i} );  
  roi_b_ind = find( gaze.labels, roi_b, gaze_unit_I{i} );  
  
  use_roi_a = roi_a_ind(randperm(numel(roi_a_ind), n_one));
  use_roi_b = roi_b_ind(randperm(numel(roi_b_ind), n_zero));
  
  mean_i = stats(i, 1);
  dev_i = stats(i, 2);
  
  spike_a = gaze.spikes(use_roi_a);
  spike_b = gaze.spikes(use_roi_b);
  
  % Z-score from reward distribution.
  spike_a = (spike_a - mean_i) ./ dev_i;
  spike_b = (spike_b - mean_i) ./ dev_i;
  
  X(:, i) = [ spike_a(:); spike_b(:) ];
end

end

function n = min_combination(labels, lab, I)

n = min( cellfun(@(x) numel(find(labels, lab, x)), I) );

end

function meets_criterion = gaze_criterion(gaze, params)

meets_criterion = fcat.mask( gaze.labels, params.base_gaze_mask ...
  , @findnone, nan_unit_id() ...
);

start_ts = gaze.events(:, gaze.event_key('start_time'));
stop_ts = gaze.events(:, gaze.event_key('stop_time'));

expect_stop = start_ts + params.fixation_duration;

if ( params.require_fixation )
  is_fix = find( expect_stop <= stop_ts );
  meets_criterion = intersect( meets_criterion, is_fix );
end

% Require at least N trials of each 'roi'.
condition_combs = combs( gaze.labels, 'roi', meets_criterion );
condition_threshold = params.condition_threshold;

unit_I = findall( gaze.labels, {'unit_uuid', 'session', 'region'}, meets_criterion );

too_few_conditions = false( rows(gaze.labels), 1 );

for i = 1:numel(unit_I)
  for j = 1:size(condition_combs, 2)
    cond_ind = find( gaze.labels, condition_combs(:, j), unit_I{i} );
    n_cond = numel( cond_ind );
    
    if ( n_cond < condition_threshold )
      too_few_conditions(unit_I{i}) = true;
      break;
    end
  end
end

meets_criterion = setdiff( meets_criterion, find(too_few_conditions) );

end

function meets_criterion = reward_criterion(reward, params)

levels = reward.reward_levels;

% meets_criterion = true( rows(reward.labels), 1 );
meets_criterion = false( rows(reward.labels), 1 );

% Remove unit_uuid_NaN, error trials, and baseline.
base_mask = fcat.mask( reward.labels, find(levels == 0 | levels == 1) ...
  , @findnone, nan_unit_id() ...
  , @find, 'no-error' ...
  , @findnone, 'iti' ...
);
base_mask = intersect( base_mask, params.base_reward_mask );

meets_criterion(base_mask) = true;

unit_I = findall( reward.labels, {'unit_uuid', 'session', 'region', 'event-name'}, base_mask );

% Require at least N trials of each 'reward-level'.
condition_combs = combs( reward.labels, 'reward-level', base_mask );
condition_threshold = params.condition_threshold;

for i = 1:numel(unit_I)
  for j = 1:size(condition_combs, 2)
    cond_ind = find( reward.labels, condition_combs(:, j), unit_I{i} );
    n_cond = numel( cond_ind );
    
    if ( n_cond < condition_threshold )
      meets_criterion(unit_I{i}) = false;
      break;
    end
  end
end

meets_criterion = find( meets_criterion );

end

function counts = collapse_counts(counts, t, t_window)

t_ind = t >= t_window(1) & t <= t_window(2);
counts = nansum( counts(:, t_ind), 2 );

end

function id = nan_unit_id()

id = 'unit_uuid__NaN';

end

function shared_ids = get_shared_unit_ids(a, b, mask_a, mask_b)

ids_a = combs( a, 'unit_uuid', mask_a );
ids_b = combs( b, 'unit_uuid', mask_b );
shared_ids = intersect( ids_a, ids_b );

end

function [roi_a, roi_b] = roi_order(roi1, roi2)

order = { 'eyes_nf', 'face', 'outside1' };
tf = ismember( order, {roi1, roi2} );
rois = order(tf);
roi_a = rois{1};
roi_b = rois{2};

end
