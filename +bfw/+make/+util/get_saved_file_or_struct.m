function [file, did_load_file] = get_saved_file_or_struct(unified_filename, intermediate_dir, conf)

%   GET_SAVED_FILE_OR_STRUCT -- Load file if it exists, else return struct.
%
%     file = get_saved_file_or_struct( unified_filename ...
%           , intermediate_directory_name )
%
%     Checks whether the file given by `unified_filename` exists in the
%     intermediate directory given by `intermediate_directory_name`. If it
%     exists, the file is loaded and returned. Otherwise, `file` is a
%     struct with no fields.
%
%     The default config file is used to generate a full path to the
%     intermediate directory.
%
%     file = get_saved_file_or_struct( ..., conf ) uses `conf` to generate
%     the full path to the intermediate directory, instead of the default
%     config file.
%
%     [..., did_load_file] = ... also returns a logical scalar indicating
%     whether `file` was loaded or simply created as a struct with no fields.
%
%     See also bfw.make.help

if ( nargin < 3 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

intermediate_p = bfw.get_intermediate_directory( intermediate_dir, conf );
full_filename = fullfile( intermediate_p, unified_filename );

file = struct();
did_load_file = false;

if ( shared_utils.io.fexists(full_filename) )
  file = shared_utils.io.fload( full_filename );
  did_load_file = true;
end

end