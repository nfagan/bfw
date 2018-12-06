function obj = get_looped_make_runner(params)

if ( nargin < 1 || isempty(params) )
  params = bfw.get_common_make_defaults();
end

obj = shared_utils.pipeline.LoopedMakeRunner;

obj.save =                  params.save;
obj.call_with_identifier =  true;
obj.is_parallel =           params.is_parallel;
obj.overwrite =             params.overwrite;
obj.filter_files_func =     @(x) bfw.files_containing( x, params.files_containing );
obj.get_identifier_func =   @(x, y) bfw.try_get_unified_filename( x );
obj.log_level =             params.log_level;
obj.files_aggregate_type =  'containers.Map';

end