function outs = bfw_gather_spikes(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'spikes', 'meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.func_name = mfilename;

results = runner.run( @main );
outputs = [ results([results.success]).output ];

outs = struct();

if ( isempty(outputs) )
  outs.spike_times = {};
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function out = main(files)

spike_file = shared_utils.general.get( files, 'spikes' );
meta_file = shared_utils.general.get( files, 'meta' );

if ( spike_file.is_link )
  units = bfw.empty_unit_struct();
else
  units = spike_file.data;
end

spike_times = columnize( arrayfun(@(x) x.times(:), units, 'un', 0) );
spike_labels = cat_expanded( 1, arrayfun(@bfw.unit_struct_to_fcat, units, 'un', 0) );

assert_ispair( spike_times, spike_labels );

join( spike_labels, bfw.struct2fcat(meta_file) );
bfw.unify_single_region_labels( spike_labels );

out.spike_times = spike_times;
out.labels = spike_labels;

end