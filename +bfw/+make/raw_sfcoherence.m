function coh_file = raw_sfcoherence(files, varargin)

defaults = bfw.make.defaults.raw_sfcoherence();
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, {'lfp', 'cc_spikes', params.events_subdir} );
files = shared_utils.general.copy( files );
files('spikes') = files('cc_spikes');

lfp_file = files('lfp');
spike_file = files('cc_spikes');
meta_file = files('meta');
events_file = files(params.events_subdir);

if ( spike_file.is_link )
  files('cc_spikes') = load_linked_file( spike_file, 'spike_subdir', 'cc_spikes', params );
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
meta_labels = bfw.struct2fcat( meta_file );

lfp_data = aligned_lfp.data;
spike_data = aligned_spikes.spikes;
t_series = aligned_spikes.t;
lfp_event_indices = aligned_lfp.event_indices;

if ( nargin(keep_func) == 2 )
  [keep_lfp_ind, keep_spike_ind] = keep_func( lfp_labels', spike_labels' );
else
  [keep_lfp_ind, keep_spike_ind] = keep_func( lfp_data, lfp_labels', spike_data, spike_labels' );
end

lfp_data = indexpair( lfp_data, lfp_labels, keep_lfp_ind );
spike_data = indexpair( spike_data, spike_labels, keep_spike_ind );
lfp_event_indices = lfp_event_indices(keep_lfp_ind);

[lfp_data, non_ref_inds] = handle_referencing( lfp_data, lfp_labels, params );
lfp_data = handle_filtering( lfp_data, params );
lfp_event_indices = lfp_event_indices(non_ref_inds);

[lfp_I, lfp_C] = findall( lfp_labels, {'region', 'channel'} );
[spike_I, spike_C] = findall( spike_labels, {'unit_index', 'region'} );

validate_lfp_spike_indices( lfp_I, spike_I, n_events );

index_combinations = dsp3.numel_combvec( lfp_I, spike_I );
n_combs = size( index_combinations, 2 );

all_coherence = cell( n_combs, 1 );
all_labels = cell( n_combs, 1 );
freqs = [];
keep_comb = true( n_combs, 1 );

for i = 1:n_combs  
  if ( params.verbose )
    fprintf( '\n %d of %d', i, n_combs );
  end
  
  lfp_index = lfp_I{index_combinations(1, i)};
  spike_index = spike_I{index_combinations(2, i)};
  
  lfp_region = lfp_C{1, index_combinations(1, i)};
  spike_region = spike_C{2, index_combinations(2, i)};
  
  if ( params.skip_matching_spike_lfp_regions && regions_match(lfp_region, spike_region) )
    keep_comb(i) = false;
    continue;
  end
  
  subset_lfp = lfp_data(lfp_index, :);
  subset_spikes = spike_data(spike_index, :);
  
  [coh, freqs, ok_trials] = calculate_sfcoherence( subset_lfp, subset_spikes, params );
  
  ok_lfp_labs = lfp_labels(lfp_index(ok_trials));
  ok_spike_labs = spike_labels(spike_index(ok_trials));
  
  merged_labels = merge_lfp_spike_labels( ok_lfp_labs, ok_spike_labs );
  join( merged_labels, meta_labels );
  
  if ( params.event_window_average )
    subset_event_indices = lfp_event_indices(lfp_index(ok_trials));
    
    coh = event_window_average( coh, t_series/1e3, subset_event_indices, events_file );
  end
  
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

data = vertcat( all_coherence{keep_comb} );
labels = vertcat( fcat(), all_labels{keep_comb} );

assert_ispair( data, labels );

if ( params.event_window_average && ~isempty(data) )
  % Averaged over time dimension.
  t_series = 0;
end

if ( ~isempty(data) )
  assert( numel(t_series) == size(data, 3), 'Time does not match data.' );
  assert( numel(freqs) == size(data, 2), 'Freqs do no match data.' );
else
  assert( numel(t_series) == 0, 'Time does not match data for empty data.' );
  assert( numel(freqs) == 0, 'Freqs do not match data for empty data.' );
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

function meaned_coh = event_window_average(coh, t, event_indices, events_file)

assert( size(coh, 1) == numel(event_indices), 'Event indices mismatch.' );
assert( size(coh, 3) == numel(t), 'T series mismatch.' );

events = events_file.events;
start_times = events(event_indices, events_file.event_key('start_time'));
stop_times = events(event_indices, events_file.event_key('stop_time'));

meaned_coh = nan( notsize(coh, 3) );

for i = 1:numel(start_times)
  start = start_times(i);
  stop = stop_times(i);
  
  adjusted_t = t + start;
  
  if ( isnan(start) || isnan(stop) )
    continue;
  end
  
  in_bounds = adjusted_t >= start & adjusted_t <= stop;
  
  meaned_coh(i, :) = squeeze( nanmean(coh(i, :, in_bounds), 3) );
end

end

function tf = regions_match(reg_a, reg_b)

tf = ~isempty( strfind(reg_a, reg_b) ) || ~isempty( strfind(reg_b, reg_a) );

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

function [lfp_data, not_ref_ind] = handle_referencing(lfp_data, lfp_labels, params)

if ( ~params.reference_subtract )
  % keep all trials
  not_ref_ind = reshape( 1:size(lfp_data, 1), [], 1 );
  return
end

[lfp_data, was_subtracted, ref_ind] = bfw.ref_subtract_fcat( lfp_data, lfp_labels );
assert( was_subtracted, 'Failed to reference subtract.' );

not_ref_ind = find( ~trueat(lfp_labels, ref_ind) );

lfp_data = lfp_data(not_ref_ind, :);
keep( lfp_labels, not_ref_ind );

assert_ispair( lfp_data, lfp_labels );

end

function data = handle_filtering(data, params)

if ( ~params.filter )
  return
end

f1 = params.f1;
f2 = params.f2;
filt_order = params.filter_order;
fs = params.sample_rate;

data = bfw.zpfilter( data, f1, f2, fs, filt_order );

end