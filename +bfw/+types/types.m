%{

@T begin

begin
  import bfw.types.fcat
end

begin export
  import mt.base

  namespace bfw
    let mask_t = uint64 | double
    let MaskFunction = [uint64] = (bfw.fcat, bfw.mask_t)
  end
end

end

%}