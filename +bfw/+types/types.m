%{

@T begin

begin export
  import mt.base
  import bfw.types.fcat

  namespace bfw
    let mask_t = uint64 | double
    let MaskFunction = [uint64] = (bfw.fcat, bfw.mask_t)
  end
end

end

%}