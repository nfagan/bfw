function [params, loop_runner] = get_params_and_loop_runner(inputs, output, defaults, args)

%   GET_PARAMS_AND_LOOP_RUNNER -- Parse main-function inputs and obtain
%     parameters and loop runner.
%
%     IN:
%       - `inputs` (cell array of strings, char)
%       - `output` (char)
%       - `defaults` (struct)
%       - `args` (cell)
%     OUT:
%       - `params` (struct)
%       - `loop_runner` (shared_utils.pipeline.LoopedMakeRunner)

params = bfw.parsestruct( defaults, args );

if ( isfield(params, 'loop_runner') && bfw.is_valid_loop_runner(params.loop_runner) )
  loop_runner = params.loop_runner;
  return
end

conf = params.config;

loop_runner = bfw.get_looped_make_runner( params );

loop_runner.input_directories = bfw.gid( inputs, conf );
loop_runner.output_directory = bfw.gid( output, conf );

end