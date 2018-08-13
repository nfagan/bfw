function out = allcombn( values )

%   ALLCOMBN -- All combinations of values, converting non-cell data to
%     cell data first.
%
%     IN:
%       - `values` (cell array)
%     OUT:
%       - `out` (cell array)

shared_utils.assertions.assert__isa( values, 'cell' );

for i = 1:numel(values)
  if ( iscell(values{i}) ), continue; end
  values{i} = arrayfun( @(x) x, values{i}, 'un', false );
end

out = bfw.allcomb( values );

end