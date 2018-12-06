function tf = is_valid_loop_runner(lr)

tf = isa( lr, 'shared_utils.pipeline.LoopedMakeRunner' ) && isvalid( lr ) ...
  && ~isempty(lr);

end