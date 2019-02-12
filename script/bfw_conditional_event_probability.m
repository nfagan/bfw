function out = bfw_conditional_event_probability(varargin)

defaults = bfw.get_common_make_defaults();
defaults.bin_width_s = 10;

inputs = { 'raw_events', 'meta', 'stim_meta', 'aligned_binned_raw_samples/time' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @conditional_event_probability, params );
outputs = [ results([results.success]).output ];

out = struct();
out.frequencies = vertcat( outputs.frequencies );
out.bin_indices = vertcat( outputs.bin_indices );
out.labels = vertcat( fcat, outputs.labels );

end

function out = conditional_event_probability(files, params)

meta_file =       shared_utils.general.get( files, 'meta' );
stim_meta_file =  shared_utils.general.get( files, 'stim_meta' );
events_file =     shared_utils.general.get( files, 'raw_events' );
time_file =       shared_utils.general.get( files, 'time' );

meta_labs = bfw.struct2fcat( meta_file );
stim_meta_labs = bfw.stim_meta_to_fcat( stim_meta_file );
event_labs = fcat.from( events_file.labels, events_file.categories );

join( event_labs, meta_labs, stim_meta_labs );

event_times = events_file.events(:, events_file.event_key('start_time'));

t = time_file.t;

t0 = t(find(~isnan(t), 1, 'first'));
t1 = t(find(~isnan(t), 1, 'last'));

edges = floor(t0):params.bin_width_s:ceil(t1);

[kept_labs, I] = keepeach( event_labs', {'roi', 'looks_by'} );

freqs = rownan( numel(edges) * numel(I) );
bin_indices = nan( size(freqs) );

labs = fcat();

for i = 1:numel(I)
  f = histc( event_times(I{i}), edges );
  
  assign_indices = (1:numel(edges)) + (i-1) * numel(edges);
  
  freqs(assign_indices) = f;
  bin_indices(assign_indices) = 1:numel( edges );
  append1( labs, kept_labs, i, numel(f) );
end

out = struct();
out.labels = labs;
out.frequencies = freqs;
out.bin_indices = bin_indices;

end