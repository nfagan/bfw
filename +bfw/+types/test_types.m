% @T import bfw.types.types
function [f, m] = test_types()

f = fcat;

m = fcat.mask( f, uint64(1) ...
  , @find, {'a'} ...
  , @find, {'b'} ...
);

end