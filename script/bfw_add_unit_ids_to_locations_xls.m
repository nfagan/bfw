function bfw_add_unit_ids_to_locations_xls(coord_sheet_path, unit_sheet_path, out_path)

[~, ~, loc_raw] = xlsread( coord_sheet_path );
unit_raw = get_unit_raw( unit_sheet_path );

[unit_days, unit_channels, unit_regions, unit_ids] = get_unit_info( unit_raw );
[loc_days, loc_channels, loc_regions] = get_location_info( loc_raw );

cats = { 'day', 'channel', 'region' };

unit_labels = fcat.from( [unit_days, unit_channels, unit_regions, unit_ids] ...
  , cshorzcat(cats, 'id') );

loc_labels = fcat.from( [loc_days, loc_channels, loc_regions], cats );

[I, C] = findall( unit_labels, cats );

loc_cols = size( loc_raw, 2 );
max_n = 0;

for i = 1:numel(I)  
  loc_ind = find( loc_labels, C(:, i) );
  
  if ( isempty(loc_ind) )
    warning( 'No match for combination: %s".', strjoin(C(:, i), ', ') );
    continue;
  end
  
  assert( numel(loc_ind) == 1, 'Multiple matches for combination.' );
  
  [unit_I, unit_C] = findall( unit_labels, 'id', I{i} );
  
  for j = 1:numel(unit_I)
    loc_raw{loc_ind+1, loc_cols+j} = unit_C{j};
  end
  
  max_n = max( max_n, numel(unit_I) );
end

% Add to header
for j = 1:max_n
  loc_raw{1, loc_cols + j} = sprintf( 'Unit %d', j );
end

xlswrite( out_path, loc_raw );

end

function unit_raw = get_unit_raw(unit_sheet_path)

[~, ~, acc_raw] = xlsread( unit_sheet_path, 'ACCg' );
[~, ~, bla_raw] = xlsread( unit_sheet_path, 'BLA' );

nan_acc_header = cellfun( @(x) isnumeric(x) && isnan(x), acc_raw(1, :) );
nan_bla_header = cellfun( @(x) isnumeric(x) && isnan(x), bla_raw(1, :) );

acc_raw(:, nan_acc_header) = [];
bla_raw(:, nan_bla_header) = [];

unit_raw = [ acc_raw; bla_raw(2:end, :) ];


end

function [days, channels, regions, ids] = get_unit_info(unit_raw)

unit_header = require_string_vector( unit_raw(1, :) );

unit_day_col_ind = assert_find_in_header( unit_header, 'day' );
unit_channel_ind = assert_find_in_header( unit_header, 'channel' );
unit_region_ind = assert_find_in_header( unit_header, 'region' );
unit_id_ind = assert_find_in_header( unit_header, 'id' );

days = numeric_days_to_string( unit_raw(2:end, unit_day_col_ind) );
channels = numeric_to_string_vector( unit_raw(2:end, unit_channel_ind) );
regions = require_string_vector( unit_raw(2:end, unit_region_ind) );
ids = numeric_to_string_vector( unit_raw(2:end, unit_id_ind) );

days(strcmp(days, '')) = {'<day>'};
channels(strcmp(channels, '')) = {'<channel>'};
regions(strcmp(regions, '')) = {'<region>'};
ids(strcmp(ids, '')) = {'<id>'};

end

function [days, channels, regions] = get_location_info(coord_raw)

coord_header = require_string_vector( coord_raw(1, :) );

loc_day_col_ind = assert_find_in_header( coord_header, 'date' );
loc_channel_ind = assert_find_in_header( coord_header, 'channel' );
loc_region_ind = assert_find_in_header( coord_header, 'region' );

days = format_location_days_as_unit_days( coord_raw(2:end, loc_day_col_ind) );
channels = numeric_to_string_vector( coord_raw(2:end, loc_channel_ind) );
regions = lower( coord_raw(2:end, loc_region_ind) );

end

function out = numeric_to_string_vector(vec, min_length, pad_with)

out = cell( size(vec) );

for i = 1:numel(out)
  current = vec{i};
  
  if ( isnan(current) )
    out{i} = '';
  else
    str = num2str( current );
    
    if ( nargin > 1 && numel(str) ~= min_length )
      % if 4052016 rather than 04052016
      str = sprintf( '%s%s', pad_with, str );
    end
    
    out{i} = str;
  end
  
end

end

function out_days = numeric_days_to_string(days)

out_days = numeric_to_string_vector( days, 8, '0' );

end

function header = require_string_vector(header)

header(~cellfun(@ischar, header)) = {''};

end

function days = format_location_days_as_unit_days(loc_days)

days = cell( size(loc_days) );

n_prefix = numel( 'day__' );

for i = 1:numel(days)
  day_strs = strsplit( loc_days{i}, ' ' );
  day_ind = assert_find_in_header( day_strs, 'day__' );
  day_str = day_strs{day_ind};
  
  day_str(day_str == 39 | day_str == 160) = []; % remove spaces and apostrophes
  
  assert( numel(day_str) == 13, 'Failed to generate valid day__.* str for "%s".', day_str );
  
  days{i} = day_str(n_prefix+1:end);
end

end

function ind = assert_find_in_header(header, substr)

ind = find_in_header( header, substr );
assert( nnz(ind) == 1, 'Expected one match for "%s" in "%s"; instead there were' ...
  , ' %d.', substr, strjoin(header, ', '), nnz(ind) );

end

function ind = find_in_header(header, substr)

ind = cellfun( @(x) ~isempty(strfind(lower(x), substr)), header );

end