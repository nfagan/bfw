function labels = significant_unit_info_to_fcat(unit_info)

uuids = cellfun( @(x) sprintf('unit_uuid__%d', x), {unit_info.unit}, 'un', 0 );
regions = [ unit_info.region ];
sessions = [ unit_info.session ];
regions(strcmp(regions, 'accg')) = { 'acc' };

categories = { 'unit_uuid', 'region', 'session' };
labels = fcat.from( [uuids(:), regions(:), sessions(:)], categories );

end