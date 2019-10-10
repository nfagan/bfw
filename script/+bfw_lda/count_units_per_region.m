function [counts, labs] = count_units_per_region(labels, mask, unit_spec)

if ( nargin < 2 )
  mask = rowmask( labels );
end

if ( nargin < 3 )
  unit_spec = { 'unit_uuid', 'session' };
end

[labs, I] = keepeach( labels', 'region', mask );
counts = zeros( size(I) );

for i = 1:numel(I)
  counts(i) = numel( findall(labels, unit_spec, I{i}) );
end

end