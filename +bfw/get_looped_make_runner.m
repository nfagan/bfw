function obj = get_looped_make_runner(params, varargin)

%   GET_LOOPED_MAKE_RUNNER -- Get pre-configured LoopedMakeRunner instance.
%
%     obj = bfw.get_looped_make_runner(); returns a valid LoopedMakeRunner
%     instance, configured in a manner expected by bfw.make_* functions. 
%
%     Relevant property values are defined by bfw.get_common_make_defaults.
%
%     obj = bfw.get_looped_make_runner( PARAMS ) uses struct `PARAMS` to 
%     configure the object, instead of the default values returned by
%     bfw.get_common_make_defaults.
%
%     obj = bfw.get_looped_make_runner( PARAMS, 'name1', value1, ... )
%     assigns value1 to field 'name1' of `PARAMS`, and so on, and then uses
%     the assigned values to configure `obj`. If `PARAMS` is an empty array
%     ([]), values are assigned to the defaults returned by
%     bfw.get_common_make_defaults.
%
%     See also shared_utils.pipeline.LoopedMakeRunner,
%       bfw.get_common_make_defaults
%
%     IN:
%       - `params` (struct)
%     OUT:
%       - `obj` (shared_utils.pipeline.LoopedMakeRunner)

if ( nargin < 1 || isempty(params) )
  params = bfw.get_common_make_defaults();
end

if ( nargin > 1 )
  params = bfw.parsestruct( params, varargin );
end

obj = shared_utils.pipeline.LoopedMakeRunner;

fc = params.files_containing;
nc = params.files_not_containing;

obj.save =                  params.save;
obj.is_parallel =           params.is_parallel;
obj.overwrite =             params.overwrite;
obj.keep_output =           params.keep_output;
obj.filter_files_func =     @(x) bfw.filter_files( x, fc, nc );
obj.get_identifier_func =   @(x, y) bfw.try_get_unified_filename( x );
obj.log_level =             params.log_level;
obj.files_aggregate_type =  'containers.Map';

if ( params.skip_existing )
  obj.set_skip_existing_files();
end

end