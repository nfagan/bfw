function unit_info = make_cc_unit_info(labels, mask)

if ( nargin < 2 )
  mask = rowmask( labels );
end

labels = copy( labels );
replace( labels, 'acc', 'accg' );

unit_combs = combs( labels, {'unit_uuid', 'region', 'session'}, mask )';
unit_id_numbers = fcat.parse( unit_combs(:, 1), 'unit_uuid__' );

unit_info = arrayfun( @(u, r, s) struct('unit', {u}, 'region', {r}, 'session', {s}) ...
  , unit_id_numbers, unit_combs(:, 2), unit_combs(:, 3) );

end