%{

@T begin

begin
  import bfw.types.types
  import mt.base
end

begin export
  namespace bfw
    declare classdef fcat
    end
  end

  declare function fcat :: [bfw.fcat] = ()
  declare method bfw.fcat find      :: [uint64] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)
  declare method bfw.fcat findnot   :: [uint64] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)
  declare method bfw.fcat findor    :: [uint64] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)
  declare method bfw.fcat findnone  :: [uint64] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)
  declare method bfw.fcat combs     :: [mt.cellstr] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)
  declare method bfw.fcat append    :: [bfw.fcat] = (bfw.fcat, bfw.fcat, list<bfw.mask_t>)
  declare method bfw.fcat append1   :: [bfw.fcat] = (bfw.fcat, bfw.fcat, list<bfw.mask_t>)
  declare method bfw.fcat join      :: [bfw.fcat] = (bfw.fcat, list<bfw.fcat>)
  declare method bfw.fcat categorical :: [categorical] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)

  namespace fcat
    let FindFunction = [uint64] = (bfw.fcat, mt.cellstr | char, list<bfw.mask_t>)

    declare function mask :: [bfw.mask_t] = (bfw.fcat, bfw.mask_t, list<fcat.FindFunction, mt.cellstr | char>)
    declare function strjoin :: [mt.cellstr] = (mt.cellstr, list<char>)
  end
end

end

%}