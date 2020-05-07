% @T import bfw.types.types
% @T import bfw.types.fcat
% @T import mt.base
% @T :: [uint64] = (bfw.fcat, bfw.mask_t, {list<bfw.MaskFunction>})
function o = apply_mask_funcs(l, m, funcs)

% @T cast uint64
o = m;

for i = 1:numel(funcs)
  f = funcs{i};
  o = f(l, o);
end

end