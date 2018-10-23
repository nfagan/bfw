function mask = catfind_substr(labs, category, substr, mask)

%   CATFIND_SUBSTR -- Get indices of labels in category containing
%     substring.
%
%     M = ... catfind_substr(labs, category, substr) returns a uint64 index
%     vector `M` identifying rows of `labs` for which `substr` is a
%     substring of a label in `category`.
%
%     EX //
%
%     M = ... catfind_substr(labs, 'region', 'acc') identifies rows of 
%     `labs` for which a label in category 'region' contains, but does not
%     necessarily exactly match, 'acc'.
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
tf = cellfun( @(x) ~isempty(strfind(x, substr)), l );

if ( nargin < 4 )
  mask = find( labs, l(tf) );
else
  mask = find( labs, l(tf), mask );
end

end