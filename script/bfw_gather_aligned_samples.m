function outs = bfw_gather_aligned_samples(varargin)

defaults = bfw.get_common_make_defaults();
defaults.input_subdirs = { 'position', 'raw_eye_mmv_fixations', 'time' };
defaults.intermediate_subdir = 'aligned_raw_samples';

params = bfw.parsestruct( defaults, varargin );

intermediate_subdir = params.intermediate_subdir;
input_subdirs = shared_utils.io.fullfiles( intermediate_subdir, cellstr(params.input_subdirs) );
input_subdirs = union( input_subdirs, 'meta' );

[params, runner] = bfw.get_params_and_loop_runner( input_subdirs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );
outs = shared_utils.struct.soa( outputs );

end

function out = main(files, params)

out = struct();

if ( shared_utils.general.is_key(files, 'position') )
  out.position = extract_position( shared_utils.general.get(files, 'position'), params );
end
if ( shared_utils.general.is_key(files, 'raw_eye_mmv_fixations') )
  out.raw_eye_mmv_fixations = extract_fixations( shared_utils.general.get(files, 'raw_eye_mmv_fixations'), params );
end
if ( shared_utils.general.is_key(files, 'time') )
  out.time = extract_time( shared_utils.general.get(files, 'time'), params );
end

out.labels = bfw.struct2fcat( shared_utils.general.get(files, 'meta') );

end

function out = extract_position(pos_file, params)

m1_pos = shared_utils.struct.field_or( pos_file, 'm1', [] );
m2_pos = shared_utils.struct.field_or( pos_file, 'm2', [] );

out = { pos_file.unified_filename, m1_pos, m2_pos };

end

function out = extract_fixations(fix_file, params)

m1_fix = shared_utils.struct.field_or( fix_file, 'm1', [] );
m2_fix = shared_utils.struct.field_or( fix_file, 'm2', [] );

out = { fix_file.unified_filename, m1_fix, m2_fix };

end

function out = extract_time(t_file, params)

out = { t_file.unified_filename, t_file.t };

end