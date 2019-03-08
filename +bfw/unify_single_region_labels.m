function labs = unify_single_region_labels(labs, check_replace)

if ( nargin < 2 )
  region_labels = combs( labs, 'region' );
  spike_region_labels = combs( labs, 'spike_region' );
  
  check_replace = union( region_labels, spike_region_labels );
else
  check_replace = cellstr( check_replace );
end

regions = bfw.region_names();

for i = 1:numel(regions)
  reg = regions{i};
  
  unify_region_set( labs, check_replace, reg );
end

end

function unify_region_set(labs, region_labels, region)

inds = cellfun( @(x) strfind(x, region), region_labels, 'un', 0 );

non_empties = find( cellfun(@(x) ~isempty(x), inds) );

for i = 1:numel(non_empties)
  matching_region_label = region_labels{non_empties(i)};
  
  region_substr = matching_region_label(inds{non_empties(i)}:end);
  
  if ( strcmp(region_substr, region) )
    continue;
  end
  
  replace_with = strrep( matching_region_label, region_substr, region );
  replace( labs, matching_region_label, replace_with );
end

prune( labs );

end