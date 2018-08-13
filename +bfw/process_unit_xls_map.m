function output = process_unit_xls_map( ms_channel_map )

import shared_utils.assertions.*;
import shared_utils.char.containsi;

assert__isa( ms_channel_map, 'cell' );
  
header = ms_channel_map(1, :);

channel_ind = cellfun( @(x) containsi(x, 'channel'), header );
unit_n_ind = cellfun( @(x) containsi(x, 'unit') && ~containsi(x, 'exclude'), header );
rating_ind = cellfun( @(x) containsi(x, 'rating'), header );
day_ind = cellfun( @(x) containsi(x, 'day'), header );
unit_id_ind = cellfun( @(x) containsi(x, 'id'), header );
exclude_unit_ind = cellfun( @(x) containsi(x, 'exclude') && containsi(x, 'unit'), header );

assert__one_header_index( channel_ind, unit_n_ind, unit_id_ind ...
  , rating_ind, day_ind, exclude_unit_ind );

%   get rid of header
ms_channel_map_ids = cellfun( @(x) x, ms_channel_map(2:end, channel_ind) );

ms_day_ids = cell( size(ms_channel_map_ids) );
for j = 1:numel(ms_day_ids)
  day_id = ms_channel_map{j+1, day_ind};
  if ( ~ischar(day_id) )
    day_id = num2str( day_id );
  end
  %   excel truncates leading zeros; add them back in if necessary.
  if ( numel(day_id) ~= 8 )
    assert( numel(day_id) == 7, ['Expected a date format like this:' ...
      , ' 01042018, or this: 1042018, but got this: %s'], day_id );
    day_id = [ '0', day_id ];
  end
  ms_day_ids{j} = day_id;
end

ms_unit_numbers = cellfun( @(x) x, ms_channel_map(2:end, unit_n_ind) );
ms_unit_ids = cellfun( @(x) x, ms_channel_map(2:end, unit_id_ind), 'un', false );
ms_unit_ratings = cellfun( @(x) x, ms_channel_map(2:end, rating_ind) );
ms_exclude_units = cellfun( @(x) ~any(isnan(x)) && (any(strcmp(x, 'x')) || isequal(x, 1)) ...
  , ms_channel_map(2:end, exclude_unit_ind) );
ms_channel_strs = arrayfun( @(x) bfw.channel_n_to_str('SPK', x), ms_channel_map_ids, 'un', false );

output = containers.Map();

output('unit_number') = ms_unit_numbers;
output('unit_uuid') = ms_unit_ids;
output('session_name') = ms_day_ids;
output('unit_rating') = ms_unit_ratings;
output('exclude_unit') = ms_exclude_units;
output('channel_number') = ms_channel_map_ids;
output('channel_str') = ms_channel_strs;

end

function assert__one_header_index( varargin )

for i = 1:numel(varargin)
  if ( sum(varargin{i}) ~= 1 )
    error( 'Excel channel map file is missing a required header column.' );
  end
end

end