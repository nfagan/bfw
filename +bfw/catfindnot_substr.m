function mask = catfindnot_substr(labs, category, substr, mask)

%   CATFINDNOT_SUBSTR -- Get indices of labels in category not containing
%     substring.
%
%     M = ... catfindnot_substr(labs, category, substr) returns a uint64 
%     index vector `M` identifying rows of `labs` for which `substr` is not
%     a substring of a label in `category`.
%
%     EX //
%
%     M = ... catfindnot_substr(labs, 'region', 'acc') identifies rows of 
%     `labs` for which a label in category 'region' does not contain 'acc'.
%
%     See also fcat/find, fcat/incat
%
%     IN:
%       - `labs` (fcat)
%       - `category` (cell array of strings, char)
%       - `substr` (char)
%       - `mask` (uint64) |OPTIONAL|
%     OUT:
%       - `mask` (uint64)

l = incat( labs, category );
tf = cellfun( @(x) isempty(strfind(x, substr)), l );

if ( nargin < 4 )
  mask = find( labs, l(tf) );
else
  mask = find( labs, l(tf), mask );
end

end