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
  out(i).channels = bfw.parse_json_channel_numbers( channels );
end

end