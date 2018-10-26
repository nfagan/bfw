function f = load_intermediate(p, un)

%   LOAD_INTERMEDIATE -- Load intermediate file in directory.
%
%     f = ... load_intermediate( P, UNIFIED_FILENAME ) loads the file given 
%     by `UNIFIED_FILENAME` in the directory given by the absolute path `P`.
%
%     IN:
%       - `p` (char)
%       - `un` (char)
%     OUT:
%       - `f` (struct)

f = shared_utils.io.fload( fullfile(p, un) );
end