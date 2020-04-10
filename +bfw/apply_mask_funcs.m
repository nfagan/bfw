function m = apply_mask_funcs(l, m, funcs)

for i = 1:numel(funcs)
  m = funcs{i}(l, m);
end

end