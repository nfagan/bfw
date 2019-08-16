function meta_file = meta(files)

%   META -- Create meta file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'unified'
%     OUT:
%       - `meta_file` (struct)

bfw.validatefiles( files, 'unified' );

un_file = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( un_file );

run_number = un_file.m1.plex_sync_index;

meta_file = struct();
meta_file.unified_filename = unified_filename;
meta_file.date = un_file.m1.date;
meta_file.session = datestr( un_file.m1.date, 'mmddyyyy' );
meta_file.mat_filename = un_file.m1.mat_filename;
meta_file.task_type = bfw.field_or( un_file.m1, 'task_type', 'free_viewing' );
meta_file.run_number_str = sprintf( 'run_number_%d', run_number );

end