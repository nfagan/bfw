function [cont, I, C] = add_unit_id(cont, within, unit_id_category_name)

%   ADD_UNIT_ID -- Add a unit-id that uniquely identifies a single cell.
%
%     IN:
%       - `cont` (Container)
%       - `within` (cell array of strings, char) |OPTIONAL|
%       - `unit_id_category_name` (char) -- What to call the `unit_id`
%     OUT:
%       - `cont` (Container)

if ( nargin < 3 ), unit_id_category_name = 'unit_id'; end
if ( nargin < 2 ), within = { 'channel', 'region', 'unit_name', 'session_name' }; end

shared_utils.assertions.assert__isa( cont, 'Container' );

cont = cont.require_fields( unit_id_category_name );

[I, C] = cont.get_indices( within );

for i = 1:numel(I)
  cont('unit_id', I{i}) = sprintf( 'unit__%d', i );
end

end