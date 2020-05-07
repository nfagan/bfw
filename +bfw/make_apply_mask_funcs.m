% @T import bfw.types.types
% @T :: [bfw.MaskFunction] = ({list<bfw.MaskFunction>})
function mask_func = make_apply_mask_funcs(funcs)

mask_func = @(l, m) bfw.apply_mask_funcs( l, m, funcs );

end