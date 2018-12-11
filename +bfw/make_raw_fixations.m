function results = make_raw_fixations(kind, varargin)

validateattributes( kind, {'char'}, {'scalartext'}, mfilename, 'kind' );

switch ( kind )
  case 'raw_eye_mmv_fixations'
    is_fix_func = @bfw.fixation.eye_mmv_is_fixation;
  case 'raw_arduino_fixations'
    is_fix_func = @bfw.fixation.arduino_is_fixation;
  otherwise
    error( 'Unrecognized kind "%s".', kind );
end

defaults = bfw.make.defaults.raw_fixations();

inputs = 'edf_raw_samples';
output = kind;

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

params.kind = kind;

results = loop_runner.run( @bfw.make.raw_fixations, is_fix_func, params );

end