function out = bfw_mutual_psth(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.psth_bin_width = 0.01;
defaults.mask_func = @(labels) rowmask( labels );

inputs = { 'raw_events', 'spikes', 'meta' };

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @main, params );
outputs = [ results([results.success]).output ];

empties = arrayfun( @(x) isempty(x.t), outputs );
outputs = outputs(~empties);

out = struct();
out.params = params;

if ( isempty(outputs) )
  out.psth = [];
  out.labels = fcat();
  out.t = [];
else
  out.psth = vertcat( outputs.psth );
  out.labels = vertcat( fcat, outputs.labels );
  out.t = outputs(1).t;
end

end

function outs = main(files, params)

event_file = shared_utils.general.get( files, 'raw_events' );
spike_file = shared_utils.general.get( files, 'spikes' ); 
meta_file =  shared_utils.general.get( files, 'meta' );

spike_file = bfw.require_spike_file( bfw.gid('spikes', params.config), spike_file );

event_labs = fcat.from( event_file );
meta_labs = bfw.struct2fcat( meta_file );
join( event_labs, meta_labs );
addcat( event_labs, 'aligned_to' );

event_mask = params.mask_func( event_labs );

event_starts = bfw.event_column( event_file, 'start_time', event_mask );
event_stops = bfw.event_column( event_file, 'stop_time', event_mask );

lb = params.look_back;
la = params.look_ahead;
bw = params.psth_bin_width;

units = spike_file.data;
spike_labs = fcat.like( event_labs );

psths = cell( numel(units), 1 );
bin_t = [];

for i = 1:numel(units)
  spike_ts = units(i).times(:);
  
  [start_aligned, bin_t] = bfw.trial_psth( spike_ts, event_starts, lb, la, bw );
  stop_aligned = bfw.trial_psth( spike_ts, event_stops, lb, la, bw );
  
  unit_labs = bfw.unit_struct_to_fcat( units(i) );
  
  merge( event_labs, unit_labs );
  setcat( event_labs, 'aligned_to', 'onset' );
  append( spike_labs, event_labs, event_mask );
  setcat( event_labs, 'aligned_to', 'offset' );
  append( spike_labs, event_labs, event_mask );
  
  psths{i} = [ start_aligned; stop_aligned ];
end

psths = vertcat( psths{:} );

outs = struct();
outs.psth = psths;
outs.t = bin_t;
outs.labels = spike_labs;

end