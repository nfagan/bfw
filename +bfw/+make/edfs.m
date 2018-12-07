function edf_file = edfs(files, output_directory, conf)

%   EDFS -- Create edf file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `output_directory` (char) |OPTIONAL|
%       - `conf` (struct) |OPTIONAL|
%     FILES:
%       - 'unified'
%     OUT:
%       - `edf_file` (struct)

unified_file = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( unified_file ); 

if ( nargin < 2 ), output_directory = '';  end

if ( nargin < 3 )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

fields = fieldnames( unified_file );
first = unified_file.(fields{1});

if ( isempty(first.edf_filename) )
  error( 'No edf filename given for: "%s".', unified_filename );
end

data_root = bfw.dataroot( conf );

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