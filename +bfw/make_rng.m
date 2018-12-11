function results = make_rng(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'rng';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

if ( params.is_parallel )
  warning( ['Not running "%s" in parallel, because randomization behavior' ...
    , ' is undefined.'], mfilename );
end

loop_runner.func_name = mfilename;
loop_runner.is_parallel = false;

results = loop_runner.run( @bfw.make.rng );

end