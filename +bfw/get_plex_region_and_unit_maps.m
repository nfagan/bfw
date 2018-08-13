function out = get_plex_region_and_unit_maps( region_file, unit_file )

plex_region_map = bfw.unify_plex_region_map( bfw.jsondecode(region_file) );
plex_unit_map = unify_plex_unit_map( bfw.jsondecode(unit_file) );

out.regions = plex_region_map;
out.units = plex_unit_map;

end

function out = unify_plex_unit_map( plex_units )

out = [];

for i = 1:numel(plex_units)
  current = plex_units(i);
  if ( isa(current, 'cell') )
    current = current{1};
  end
  current.channels = bfw.parse_json_channel_numbers( current.channels );
  if ( i == 1 )
    out = current;
  else
    out(i) = current;
  end
end

end