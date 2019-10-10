function to_keep = find_random_subset_per_region(labels, mask, counts, count_labels)

assert_ispair( counts, count_labels );
validateattributes( counts, {'double', 'uint64'}, {'vector'}, mfilename, 'counts' );

%%

[count_I, regions] = findall( count_labels, 'region' );

to_keep = cell( size(count_I) );

for i = 1:numel(count_I)
  max_counts = counts(count_I{i});
  assert( numel(max_counts) == 1, 'Expected 1 unit count per region.' );
  region_mask = find( labels, regions{i}, mask );
  
  possible_units = findall( labels, {'region', 'unit_uuid', 'session'}, region_mask );
  assert( numel(possible_units) >= max_counts, 'Fewer present unit ids than requested subset.' );
  
  sampled_unit_ind = sort( randperm(numel(possible_units), max_counts) );
  to_keep{i} = vertcat( possible_units{sampled_unit_ind} );
end

to_keep = vertcat( to_keep{:} );

end