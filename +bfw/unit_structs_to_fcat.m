function labs = unit_structs_to_fcat(unit, varargin)

labs = fcat();
for i = 1:numel(unit)
  append( labs, bfw.unit_struct_to_fcat(unit(i), varargin{:}) );
end

end