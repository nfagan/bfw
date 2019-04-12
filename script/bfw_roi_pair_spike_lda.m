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

inputs = { 'raw_events', 'spikes', 'meta', 'rng' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @per_unit_lda, params );

outputs = [ results([results.success]).output ];

outs = struct();
outs.params = params;

if ( isempty(outputs) )
  outs.labels = fcat();
  outs.percent_correct = [];
else
  outs.labels = vertcat( fcat(), outputs.labels );
  outs.percent_correct = vertcat( outputs.percent_correct );
end

end

function outs = per_unit_lda(files, params)

files = require_spike_file( bfw.gid('spikes', params.config), files );

window_size = params.window_size;
step_size = params.step_size;

null_iters = params.null_iters;

aligned_spike_file = bfw.make.raw_aligned_spikes( files ...
  , 'window_size', window_size ...
  , 'step_size', step_size ...
  , 'rois', {'eyes_nf', 'mouth', 'face'} ...
);

events_file = shared_utils.general.get( files, 'raw_events' );
meta_file = shared_utils.general.get( files, 'meta' );
rng_file = shared_utils.general.get( files, 'rng' );

% For reproducibility.
rng( rng_file.state );

spike_rate = get_spike_rate( aligned_spike_file.spikes, aligned_spike_file.t, params );
spike_labels = fcat.from( aligned_spike_file );

non_overlapping = get_non_overlapping_event_indices( events_file );

% Subset of rows of spike_labels that contain events that are
% non-overlapping
ok_event_inds = find( ismember(aligned_spike_file.event_indices, non_overlapping) );

% Subset of rows of spike_labels that refer to m1-exclusive events.
mask = fcat.mask( spike_labels, ok_event_inds ... 
  , @find, 'm1' ...
);

rois = combs( spike_labels, 'roi' );
roi_pair_indices = nchoosek( 1:numel(rois), 2 );

unit_I = findall( spike_labels, 'unit_uuid', mask );

real_labels = fcat();
shuff_labels = fcat();

real_data = nan( numel(unit_I) * size(roi_pair_indices, 1), 2 );
shuff_data = nan( numel(unit_I) * size(roi_pair_indices, 1) * null_iters, 2 );

real_stp = 1;
shuff_stp = 1;

index_combinations = combvec( 1:numel(unit_I), 1:size(roi_pair_indices, 1) );

for i = 1:size(index_combinations, 2)
  index_comb = index_combinations(:, i);
  
  unit_ind = unit_I{index_comb(1)};
  roi_pair_index = roi_pair_indices(index_comb(2), :);
  
  roi_pair = rois(roi_pair_index);
  full_unit_ind = find( spike_labels, roi_pair, unit_ind );

  % false -> don't shuffle
  [p, had_missing] = run_lda( spike_rate, spike_labels, full_unit_ind, false, params );
  
  real_data(real_stp, :) = [p, had_missing];
  real_stp = real_stp + 1;

  for k = 1:null_iters
    [p, had_missing] = run_lda( spike_rate, spike_labels, full_unit_ind, true, params );
    
    shuff_data(shuff_stp, :) = [ p, had_missing ];
    shuff_stp = shuff_stp + 1;
  end

  roi_lab = strjoin( roi_pair, '_' );

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

join( all_labels, bfw.struct2fcat(meta_file) );
prune( all_labels );

outs = struct();
outs.percent_correct = all_data;
outs.labels = all_labels;

end

function [new_shuff_data, shuff_labels] = default_reduce_shuffled_func(shuff_data, shuff_labels)

[~, I] = keepeach( shuff_labels, {'roi', 'unit_uuid'} );

new_shuff_data = nan( numel(I), 2 );

for i = 1:numel(I)
  mean_perc = mean( shuff_data(I{i}, 1) );
  had_missing = any( shuff_data(I{i}, 2) > 0 );
  
  if ( had_missing )
    mean_perc = nan;
  end
  
  new_shuff_data(i, :) = [ mean_perc, double(had_missing) ];
end

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
  p = sum( cls == test_group ) / numel( test_group );

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

function files = require_spike_file(spike_p, files)

spike_file = shared_utils.general.get( files, 'spikes' );

if ( spike_file.is_link )
  spike_file = shared_utils.io.fload( fullfile(spike_p, spike_file.data_file) );
  
  files = shared_utils.general.set( files, 'spikes', spike_file );
end

end