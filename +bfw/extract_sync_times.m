function t = extract_sync_times(sync_file, type)

validateattributes( type, {'char'}, {'scalartext'}, mfilename, 'type' );

[exists, ind] = ismember( type, sync_file.sync_key );
assert( exists, 'No such sync type: "%s".', type );

t = sync_file.plex_sync(:, ind);

end