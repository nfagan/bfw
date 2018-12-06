function results = make_edfs(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'edf';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @make_edfs_main, loop_runner.output_directory, params );

end

function edf_file = make_edfs_main(files, unified_filename, output_directory, params)

unified_file = shared_utils.general.get( files, 'unified' );
fields = fieldnames( unified_file );
first = unified_file.(fields{1});

if ( isempty(first.edf_filename) )
  error( 'No edf filename given for: "%s".', unified_filename );
end

data_root = bfw.dataroot( params.config );

copy_fields = { 'unified_filename', 'unified_directory' };

edf_file = struct();

for j = 1:numel(fields)
  monk = fields{j};
  
  m_dir = unified_file.(monk).mat_directory;
  edf_filename = unified_file.(monk).edf_filename;
  
  edf_obj = Edf2Mat( fullfile(data_root, m_dir{:}, edf_filename) );
  
  edf_file.(monk).edf = edf_obj;
  edf_file.(monk).medf_filename = unified_filename;
  edf_file.(monk).medf_directory = output_directory;
end

for j = 1:numel(copy_fields)
  cf = copy_fields{j};
  
  for k = 1:numel(fields)
    monk = fields{k};
    
    edf_file.(monk).(cf) = unified_file.(monk).(cf);
  end
end

end