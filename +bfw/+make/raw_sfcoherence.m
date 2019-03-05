function coh_file = raw_sfcoherence(files, varargin)

defaults = bfw.make.defaults.raw_sfcoherence();
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, {'lfp', 'spikes', params.events_subdir} );
files = shared_utils.general.copy( files );

lfp_file = files('lfp');
spike_file = files('spikes');

if ( spike_file.is_link )
  files('spikes') = load_linked_file( spike_file, 'spike_subdir', 'spikes', params );
end

if ( lfp_file.is_link )
  files('lfp') = load_linked_file( lfp_file, 'lfp_subdir', 'lfp', params );
end

lfp_pruned_params = prune_fields( bfw.make.defaults.raw_aligned_lfp(), params );
spike_pruned_params = prune_fields( bfw.make.defaults.raw_aligned_spikes(), params );

aligned_lfp = bfw.make.raw_aligned_lfp( files, lfp_pruned_params );
aligned_spikes = bfw.make.raw_aligned_spikes( files ...
  , 'use_window_start_as_0', true, spike_pruned_params );

assert( aligned_lfp.n_events_per_channel == aligned_spikes.n_events_per_unit ...
  , 'Lfp event dimension did not match spike dimension' );

keep_func = params.keep_func;

n_events = aligned_lfp.n_events_per_channel;
lfp_labels = fcat.from( aligned_lfp );
spike_labels = fcat.from( aligned_spikes );

lfp_data = aligned_lfp.data;
spike_data = aligned_spikes.spikes;
t_series = aligned_spikes.t;

if ( nargin(keep_func) == 2 )
  [keep_lfp_ind, keep_spike_ind] = keep_func( lfp_labels', spike_labels' );
else
  [keep_lfp_ind, keep_spike_ind] = keep_func( lfp_data, lfp_labels', spike_data, spike_labels' );
end

lfp_data = indexpair( lfp_data, lfp_labels, keep_lfp_ind );
spike_data = indexpair( spike_data, spike_labels, keep_spike_ind );

lfp_I = findall( lfp_labels, {'region', 'channel'} );
spike_I = findall( spike_labels, {'unit_index'} );

validate_lfp_spike_indices( lfp_I, spike_I, n_events );

index_combinations = dsp3.numel_combvec( lfp_I, spike_I );
n_combs = size( index_combinations, 2 );

all_coherence = cell( n_combs, 1 );
all_labels = cell( n_combs, 1 );
freqs = [];

for i = 1:n_combs
  lfp_index = lfp_I{index_combinations(1, i)};
  spike_index = spike_I{index_combinations(2, i)};
  
  subset_lfp = lfp_data(lfp_index, :);
  subset_spikes = spike_data(spike_index, :);
  
  [coh, freqs, ok_trials] = calculate_sfcoherence( subset_lfp, subset_spikes, params );
  
  ok_lfp_labs = lfp_labels(lfp_index(ok_trials));
  ok_spike_labs = spike_labels(spike_index(ok_trials));
  
  merged_labels = merge_lfp_spike_labels( ok_lfp_labs, ok_spike_labs );
  
  if ( params.trial_average )
    [~, mean_I] = keepeach_or_one( merged_labels, params.trial_average_specificity );
    
    coh = rowop( coh, mean_I, @(x) nanmean(x, 1) );
  end
  
  all_coherence{i} = coh;
  all_labels{i} = merged_labels;
end

if ( n_combs == 0 )
  t_series = [];
  freqs = [];
end

data = vertcat( all_coherence{:} );
labels = vertcat( fcat(), all_labels{:} );

assert_ispair( data, labels );

if ( ~isempty(data) )
  assert( numel(t_series) == size(data, 3) );
  assert( numel(freqs) == size(data, 2) );
else
  assert( numel(t_series) == 0 );
  assert( numel(freqs) == 0 );
end

[labels, categories] = categorical( labels );

coh_file = struct();
coh_file.params = params;
coh_file.data = data;
coh_file.labels = labels;
coh_file.categories = categories;
coh_file.t = t_series;
coh_file.f = freqs;

end

function lfp = merge_lfp_spike_labels(lfp, spike)

join( lfp, spike );

spike_channel = combs( spike, 'channel' );
spike_region = combs( spike, 'region' );

spike_fun = @(y) cellfun( @(x) sprintf('spike_%s', x), y, 'un', 0 );

addsetcat( lfp, 'spike_region', spike_fun(spike_region) );
addsetcat( lfp, 'spike_channel', spike_channel );

prune( lfp );

end

function [coh, freqs, is_ok] = calculate_sfcoherence(lfp, spike, params)

chronux_params = params.chronux_params;

binned_lfp = shared_utils.array.bin3d( lfp, params.window_size, params.step_size );
n_time_bins = size( binned_lfp, 3 );

assert( n_time_bins == size(spike, 2), 'spike, lfp dimension mismatch.' );

for i = 1:n_time_bins
  lfp_t = binned_lfp(:, :, i);
  spike_t = spikes_to_struct( spike(:, i) );
  
  [C,~,~,~,~,freqs] = coherencycpt( lfp_t', spike_t, chronux_params );
  
  if ( i == 1 )
    coh = nan( size(C, 2), size(C, 1), n_time_bins );
  end
  
  coh(:, :, i) = C';
end

if ( params.remove_nan_trials )
  is_ok = ~all( all(isnan(coh), 2), 3 );
else
  is_ok = true( size(coh, 1), 1 );
end

coh = coh(is_ok, :, :);

end

function s = spikes_to_struct(spikes)

s = cellfun( @(x) struct('times', x(:)), spikes );

end

function validate_lfp_spike_indices(lfp_I, spike_I, n_events)

assert( all(cellfun(@numel, lfp_I) == n_events), 'Lfp trial counts mismatch.' );
assert( all(cellfun(@numel, spike_I) == n_events), 'Spike trial counts mismatch.' );

end

function b = prune_fields(a, b)

non_shared_fields = setdiff( fieldnames(b), fieldnames(a) );
b = rmfield( b, non_shared_fields );

end

function data_file = load_linked_file(link_file, subdir_fieldname, kind, params)

conf = params.config;
subdir = params.(subdir_fieldname);

data_filepath = fullfile( bfw.gid(subdir, conf), link_file.data_file );

if ( ~shared_utils.io.fexists(data_filepath) )
  error( 'Missing linked %s file: "%s".', kind, data_filepath );
end

data_file = shared_utils.io.fload( data_filepath );

end