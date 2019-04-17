function outs = bfw_roi_pair_spike_lda(varargin)

defaults = bfw.get_common_make_defaults();
defaults.window_size = 50;
defaults.step_size = 50;
defaults.min_t = 0;
defaults.max_t = 400;
defaults.p_train = 0.75;
defaults.null_iters = 1e3;
defaults.reduce_shuffled_data = true;
defaults.reduce_shuffled_func = @default_reduce_shuffled_func;
defaults.rois = {'eyes_nf', 'mouth', 'face'};

inputs = { 'raw_events', 'spikes', 'meta', 'rng' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @gather_spikes, params );

outputs = [ results([results.success]).output ];

if ( ~isempty(outputs) )
  non_empties = arrayfun( @(x) ~isempty(x.spike_rate), outputs );
  outputs = outputs(non_empties);  
end

if ( isempty(outputs) )
  outs = lda_main( [], fcat(), {}, {}, params );
  
else
  spike_labels = vertcat( fcat(), outputs.labels );
  spike_rate = vertcat( outputs.spike_rate );
  sessions = vertcat( outputs.session );
  rng_state = { outputs.rng_state };
  
  assert( numel(sessions) == numel(rng_state), 'Sessions must match rng state.' );
  
  outs = lda_main( spike_rate, spike_labels, sessions(:), rng_state(:), params );
end

end

function outs = gather_spikes(files, params)

[files, was_link] = require_spike_file( bfw.gid('spikes', params.config), files );

aligned_spike_file = bfw.make.raw_aligned_spikes( files ...
  , 'window_size', params.window_size ...
  , 'step_size', params.step_size ...
  , 'rois', params.rois ...
);

meta_file = shared_utils.general.get( files, 'meta' );
rng_file = shared_utils.general.get( files, 'rng' );
events_file = shared_utils.general.get( files, 'raw_events' );

if ( isempty(aligned_spike_file.spikes) )
  spike_rate = [];
else
  spike_rate = get_spike_rate( aligned_spike_file.spikes, aligned_spike_file.t, params );
end

spike_labels = fcat.from( aligned_spike_file );

% Subset of rows of spike_labels that contain events that are
% non-overlapping
non_overlapping = get_non_overlapping_event_indices( events_file );
ok_event_inds = find( ismember(aligned_spike_file.event_indices, non_overlapping) );

join( spike_labels, bfw.struct2fcat(meta_file) );

prune( keep(spike_labels, ok_event_inds) );
spike_rate = spike_rate(ok_event_inds);

outs = struct();
outs.labels = spike_labels;
outs.spike_rate = spike_rate;
outs.session = combs( spike_labels, 'session' );
outs.has_rng_state = ~was_link;

if ( ~was_link )
  outs.rng_state = rng_file.state;
else
  outs.rng_state = [];
end

end

function outs = lda_main(spike_rate, spike_labels, sessions, rng_state, params)

% Subset of rows of spike_labels that refer to m1-exclusive events.
base_mask = fcat.mask( spike_labels ... 
  , @find, 'm1' ...
);

lda_each = { 'session', 'unit_uuid' };
lda_I = findall( spike_labels, lda_each, base_mask );

is_non_empty_rng_state = ~cellfun( @isempty, rng_state );

all_outs = cell( numel(lda_I), 1 );
success = true( numel(lda_I), 1 );

parfor i = 1:numel(lda_I)
  session = char( cellstr(spike_labels, 'session', lda_I{i}(1)) );
  session = session(:)';
  
  is_rng_state = strcmp( sessions, session ) & is_non_empty_rng_state;
  
  if ( nnz(is_rng_state) ~= 1 )
    warning( 'Failed to find rng state for: "%s".', session );
    success(i) = false;
    continue;
  end
  
  use_rng_state = rng_state{is_rng_state};
  rng( use_rng_state );
  
  all_outs{i} = masked_lda( spike_rate, spike_labels, lda_I{i}, params );
end

success_outs = [ all_outs{success} ];

outs = struct();
outs.params = params;

if ( isempty(success_outs) )
  outs.performance = [];
  outs.labels = fcat();
else
  outs.performance = vertcat( success_outs.performance );
  outs.labels = vertcat( fcat, success_outs.labels );
end

end

function outs = masked_lda(spike_rate, spike_labels, mask, params)

null_iters = params.null_iters;

rois = sort( combs(spike_labels, 'roi', mask) );
roi_pair_indices = nchoosek( 1:numel(rois), 2 );

unit_I = findall( spike_labels, 'unit_uuid', mask );

real_labels = fcat();
shuff_labels = fcat();

real_data = nan( numel(unit_I) * size(roi_pair_indices, 1), 3 );
shuff_data = nan( numel(unit_I) * size(roi_pair_indices, 1) * null_iters, 3 );

real_stp = 1;
shuff_stp = 1;

index_combinations = combvec( 1:numel(unit_I), 1:size(roi_pair_indices, 1) );

for i = 1:size(index_combinations, 2)
  index_comb = index_combinations(:, i);
  
  unit_ind = unit_I{index_comb(1)};
  roi_pair_index = roi_pair_indices(index_comb(2), :);
  
  roi_pair = rois(roi_pair_index);
  full_unit_ind = find( spike_labels, roi_pair, unit_ind );

  % shuffle first
  for k = 1:null_iters
    [p, had_missing] = run_lda( spike_rate, spike_labels, full_unit_ind, true, params );
    
    shuff_data(shuff_stp, 1:2) = [ p, had_missing ];
    shuff_stp = shuff_stp + 1;
  end
  
  % false -> don't shuffle
  [p, had_missing] = run_lda( spike_rate, spike_labels, full_unit_ind, false, params );
  
  % Test p vs. null
  shuff_p = shuff_data((shuff_stp-null_iters):(shuff_stp-1), 1);
  p_real_v_null = compare_real_and_null( p, shuff_p );
  
  real_data(real_stp, :) = [ p, had_missing, p_real_v_null ];
  real_stp = real_stp + 1;

  roi_lab = strjoin( roi_pair, '/' );

  append1( real_labels, spike_labels, full_unit_ind );
  setcat( real_labels, 'roi', roi_lab, length(real_labels) );

  null_assign_vec = (1:null_iters) + double( length(shuff_labels) );

  append1( shuff_labels, spike_labels, full_unit_ind, null_iters );
  setcat( shuff_labels, 'roi', roi_lab, null_assign_vec );
end

if ( params.reduce_shuffled_data )
  [shuff_data, shuff_labels] = params.reduce_shuffled_func( shuff_data, shuff_labels' );
end

all_data = [ real_data; shuff_data ];
all_labels = vertcat( fcat(), real_labels, shuff_labels );

addsetcat( all_labels, 'shuffled-type', 'shuffled' );
setcat( all_labels, 'shuffled-type', 'non-shuffled', 1:rows(real_data) );
prune( all_labels );

outs = struct();
outs.performance = all_data;
outs.labels = all_labels;

end

function p = compare_real_and_null(real_p, null_dist)

p = sum( null_dist > real_p ) / numel( null_dist );

end

function [p, had_missing] = run_lda(spike_rate, spike_labels, unit_ind, shuffle, params)

p_train = params.p_train;

roi_group = removecats( categorical(spike_labels, 'roi', unit_ind) );
n_group = numel( roi_group );

if ( shuffle )
  roi_group = roi_group(randperm(n_group));
end

n_train = floor( p_train * n_group );

train_ind = sort( randperm(n_group, n_train) );
test_ind = setdiff( 1:n_group, train_ind );

train_data = spike_rate(unit_ind(train_ind));
train_group = roi_group(train_ind);

test_data = spike_rate(unit_ind(test_ind));
test_group = roi_group(test_ind);

n_unique_train = numel( unique(train_group) );

try
  cls = classify( test_data, train_data, train_group );
  p = sum( cls(:) == test_group(:) ) / numel( test_group );

  had_missing = double( n_unique_train ~= 2 );
catch err
  warning( err.message );
  
  p = nan;
  had_missing = true;
end

end

function spike_rate = get_spike_rate(spike_ts, t, params)

window_size = params.window_size;
bins_per_sec = 1e3 / window_size;

spike_counts = cellfun( @numel, spike_ts );
spike_rate = spike_counts / window_size * bins_per_sec;

t_ind = t >= params.min_t & t <= params.max_t;

spike_rate = mean( spike_rate(:, t_ind), 2 );

end

function non_overlapping = get_non_overlapping_event_indices(events_file)

non_overlapping = bfw_exclusive_events_from_events_file( events_file );
non_nan = bfw_non_nan_linearized_event_times( events_file );

non_overlapping = intersect( non_overlapping, non_nan );

end

function [files, was_link] = require_spike_file(spike_p, files)

spike_file = shared_utils.general.get( files, 'spikes' );
was_link = spike_file.is_link;

if ( was_link )
  spike_file = shared_utils.io.fload( fullfile(spike_p, spike_file.data_file) );
  
  files = shared_utils.general.set( files, 'spikes', spike_file );
end

end

function [new_shuff_data, shuff_labels] = default_reduce_shuffled_func(shuff_data, shuff_labels)

[~, I] = keepeach( shuff_labels, {'roi', 'unit_uuid', 'session'} );

new_shuff_data = nan( numel(I), size(shuff_data, 2) );

for i = 1:numel(I)
  mean_perc = mean( shuff_data(I{i}, 1) );
  had_missing = any( shuff_data(I{i}, 2) > 0 );
  
  if ( had_missing )
    mean_perc = nan;
  end
  
  new_shuff_data(i, 1:2) = [ mean_perc, double(had_missing) ];
end

end