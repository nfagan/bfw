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

un_file = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( un_file );

meta_file = struct();
meta_file.unified_filename = unified_filename;
meta_file.date = un_file.m1.date;
meta_file.session = datestr( un_file.m1.date, 'mmddyyyy' );
meta_file.mat_filename = un_file.m1.mat_filename;
meta_file.task_type = bfw.field_or( un_file.m1, 'task_type', 'free_viewing' );

end