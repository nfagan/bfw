%   BFW.MAKE.HELP
%
%   This directory houses functions that create new intermediate files.
%   
%   Each function is designed to operate on file(s) associated with a
%   single 'unified_filename' at a time. The general form of a make.* 
%   function is as follows:
%
%   OUT_FILE = bfw.make.function_name(INPUT_FILES, ARG1, ARG2, ... ARGN)
%
%   `INPUT_FILES` is always a containers.Map or struct with an entry for 
%   each intermediate file required by the function. `ARG1` ... `ARGN` are
%   additional arguments that vary depending on the function, and may not
%   be required.
%
%   Each function's documentation contains a `FILES` list, indicating which
%   intermediate files need to be present in `INPUT_FILES`. For example,
%   bfw.make.meta requires only a 'unified' intermediate file, whereas
%   bfw.make.edf_sync_times requires 'unified' and 'edf' intermediate
%   files.
%
%   Some functions accept parameter values as a struct or series of 'name',
%   value paired inputs. For these functions, default values are always
%   provided and will be used for parameters that are not manually
%   specified. If a make.* function is formatted in this way, it will have 
%   a corresponding bfw.make.defaults.<function_name>, which returns the 
%   default values for that function.
%
%   EXAMPLE:
%
%     % Create the meta_file from a random unified_file.
%     unified_file = bfw.load1( 'unified' );
%     % Note how the unified_file is passed as a struct with a field
%     % 'unified'.
%     meta_file = bfw.make.meta( struct('unified', unified_file) );
%
%   See also shared_utils.pipeline.LoopedMakeRunner, containers.Map,
%     shared_utils.general.is_map_like