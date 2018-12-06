function results = make_stim_meta(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'stim_meta';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

loop_runner.func_name = mfilename;

results = loop_runner.run( @stim_meta_main, params );

end

function stim_meta_file = stim_meta_main(files, unified_filename, params)

un_file = shared_utils.general.get( files, 'unified' );

stim_meta_file = struct();
stim_meta_file.unified_filename = unified_filename;
stim_meta_file.used_stimulation = false;

% preceded introduction of stimulation
if ( ~isfield(un_file.m1, 'stimulation_params') )
  return; 
end

stim_params = un_file.m1.stimulation_params;

% run on which stimulation was not used
if ( ~stim_params.use_stim_comm )
  return; 
end

stim_meta_file.used_stimulation = true;

fs = fieldnames( stim_params );

for i = 1:numel(fs)
  stim_meta_file.(fs{i}) = stim_params.(fs{i});  
end

stim_meta_file.protocol_name = bfw.get_stim_protocol_name( stim_params.protocol );

end