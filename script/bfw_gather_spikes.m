function outs = bfw_gather_spikes(varargin)

defaults = bfw.get_common_make_defaults();
defaults.spike_subdir = 'spikes';
defaults.include_unit_index = false;

params = bfw.parsestruct( defaults, varargin );

inputs = { params.spike_subdir, 'meta' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.func_name = mfilename;

results = runner.run( @main, params.spike_subdir, params.include_unit_index );
outputs = [ results([results.success]).output ];

outs = struct();

if ( isempty(outputs) )
  outs.spike_times = {};
  outs.labels = fcat();
  outs.units = struct( [] );
else
  outs = shared_utils.struct.soa( outputs );
end

end

function out = main(files, spike_subdir, include_unit_index)

spike_file = shared_utils.general.get( files, spike_subdir );
meta_file = shared_utils.general.get( files, 'meta' );

if ( spike_file.is_link )
  units = bfw.empty_unit_struct();
else
  units = spike_file.data;
end

spike_times = columnize( arrayfun(@(x) x.times(:), units, 'un', 0) );
spike_labels = cat_expanded( 1, arrayfun(@bfw.unit_struct_to_fcat, units, 'un', 0) );

if ( include_unit_index )
  unit_indices = arrayfun( @(x) sprintf('unit_index__%d', x), 1:numel(units), 'un', 0 );
  addsetcat( spike_labels, 'unit_index', unit_indices );
end

assert_ispair( spike_times, spike_labels );

join( spike_labels, bfw.struct2fcat(meta_file) );
bfw.unify_single_region_labels( spike_labels );

out.spike_times = spike_times;
out.labels = spike_labels;
out.units = units;

end