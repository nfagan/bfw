function m = get_plex_meta_channel_map(varargin)

%   GET_PLEX_META_CHANNEL_MAP -- Get a map containing meta-data about each
%   	plexon recording session -- region, channel numbers, etc.
%
%     IN:
%       - `varargin`
%     OUT:
%       - `m` (containers.Map)

persistent raw;
persistent plex_filename;

if ( isempty(raw) )
  [raw, plex_filename] = bfw.get_plex_meta_file( varargin{:} );
end

try
  m = main( raw );
catch err
  error( get_fail_msg(plex_filename, err.message) );
end

end

function m = get_fail_msg(filename, msg)
m = sprintf('Failed to parse "%s": %s', filename, msg );
end

function out = main(raw)

assert( size(raw, 1) > 1, '"Channels" sheet is empty.' );

header = raw(1, :);
rest_raw = raw(2:end, :);

expected_col_names = { 'session', 'region', 'channels' };

header_inds = get_column_indices( header, expected_col_names );

sessions = parse_sessions( rest_raw(:, header_inds(1)) );
regions = parse_regions( rest_raw(:, header_inds(2)) );
channels = parse_channels( rest_raw(:, header_inds(3)) );

assert( numel(sessions) == numel(regions) && numel(regions) == numel(channels) ...
  , 'Number of columns do not match "%s".', strjoin(expected_col_names) );

out = containers.Map();

out('session') = sessions;
out('region') = regions;
out('channels') = channels;

end

function channels = parse_channels(raw_channels)

channels = cell( numel(raw_channels), 1 );

for i = 1:numel(raw_channels)
  raw_chan = bfw.parse_json_channel_numbers( raw_channels(i) );
  
  channels{i} = raw_chan;
end

end

function regions = parse_regions(raw_regions)

assert( all(cellfun(@ischar, raw_regions)), 'Regions must be strings.' );
regions = raw_regions(:);

end

function sessions = parse_sessions(raw_sessions)

expected_format = 'mmddyyyy';
n_expected = numel( expected_format );
invalid_format_msg = @(x) sprintf( 'Invalid date format: expected "%s"; got "%s".' ...
  , expected_format, x );

sessions = cell( numel(raw_sessions), 1 );

for i = 1:numel(raw_sessions)
  raw_sesh = raw_sessions{i};
  
  if ( ~ischar(raw_sesh) )
    raw_sesh = num2str( raw_sesh );
  end
  
  n_provided = numel( raw_sesh );
  
  if ( n_provided ~= n_expected )
    assert( n_provided + 1 == n_expected, invalid_format_msg(raw_sesh) );
    assert( n_provided > 0 && raw_sesh(1) ~= '0', invalid_format_msg(raw_sesh) );
    %   transform e.g. 8252018 -> 08252018, since excel removes leading 0s.
    raw_sesh = sprintf( '0%s', raw_sesh );
  end
  
  sessions{i} = raw_sesh;
end

end

function inds = get_column_indices(header, cols)

inds = zeros( numel(header), 1 );

for i = 1:numel(cols)
  ind = strcmpi( header, cols{i} );
  
  if ( nnz(ind) ~= 1 )
    if ( nnz(ind) == 0 )
      error( 'Missing required column name "%s".', cols{i} );
    else
      error( 'More than one column name "%s".', cols{i} );
    end
  end
  
  inds(i) = find( ind );
end

end