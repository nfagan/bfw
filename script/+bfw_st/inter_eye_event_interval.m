function outs = inter_eye_event_interval(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();

inputs = { 'raw_events', 'meta', 'stim_meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = [ results([results.success]).output ];

if ( isempty(outputs) )
  outs = struct();
  outs.inter_event_intervals = [];
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files, params)

event_file = shared_utils.general.get( files, 'raw_events' );
meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );

event_labs = fcat.from( event_file );
meta_labs = bfw.struct2fcat( meta_file );
stim_labs = bfw.stim_meta_to_fcat( stim_meta_file );

join( event_labs, meta_labs, stim_labs );

m1_exclusive_eyes = find( event_labs, {'m1', 'exclusive_event', 'eyes_nf'} );
starts = event_file.events(m1_exclusive_eyes, event_file.event_key('start_time'));

is_non_nan = ~isnan( starts );
non_nan_starts = sort( starts(is_non_nan) );

to_keep = find( is_non_nan );
to_keep = to_keep(2:end);

outs = struct();
outs.inter_event_intervals = diff( non_nan_starts );
outs.labels = prune( keep(event_labs, to_keep) );

assert_ispair( outs.inter_event_intervals, outs.labels );

end