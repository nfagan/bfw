function out = get_plex_region_and_unit_maps( region_file, unit_file )

plex_region_map = unify_plex_region_map( bfw.jsondecode(region_file) );
plex_unit_map = unify_plex_unit_map( bfw.jsondecode(unit_file) );

out.regions = plex_region_map;
out.units = plex_unit_map;

end

function out = unify_plex_region_map( plex_channel_map_struct )

for i = 1:numel(plex_channel_map_struct)
  current = plex_channel_map_struct(i);
  if ( isa(current, 'cell') )
    current = current{1};
  end
  if ( i == 1 )
    out = current;
  else
    out(i) = current;
  end
  channels = current.channels;
  out(i).channels = parse_channel_numbers( channels );
end

end

function out = unify_plex_unit_map( plex_units )

out = [];

for i = 1:numel(plex_units)
  current = plex_units(i);
  if ( isa(current, 'cell') )
    current = current{1};
  end
  current.channels = parse_channel_numbers( current.channels );
  if ( i == 1 )
    out = current;
  else
    out(i) = current;
  end
end

end

function out = parse_channel_numbers( channels )

%   channels are a simple array of numbers
if ( isa(channels, 'double') )
  out = channels;
  return;
end
%   otherwise, channels are either a string like "17-32", or a mix of
%   string and number
shared_utils.assertions.assert__isa( channels, 'cell', 'channels' );
out = [];
for j = 1:numel(channels)
  chan = channels{j};    
  if ( isa(chan, 'double') )
    out(end+1) = chan;
    continue;
  end
  if ( isa(chan, 'char') )
    ind = strfind( chan, '-' );
    err_msg = sprintf( ['Wrong format for string channel interval;' ...
      , ' expected a format like this: "17-32", but got this: "%s".'] ...
      , chan );

    assert( numel(ind) == 1, err_msg );

    start = str2double( chan(1:ind-1) );
    stop = str2double( chan(ind+1:end) );

    assert( ~isnan(start) && ~isnan(stop), err_msg );

    interval = start:stop;

    out(end+1:end+numel(interval)) = interval;

    continue;
  end

  error( 'Unrecognized channel type "%s."', class(chan) );
end

end