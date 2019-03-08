function labs = add_region_pair_labels(labs, region_cats, region_names)

if ( nargin < 2 )
  region_cats = { 'region', 'spike_region' };
end

if ( nargin < 3 )
  region_names = bfw.region_names();
end

addcat( labs, 'region_pair' );

[region_I, region_combs] = findall( labs, region_cats );

for i = 1:size(region_combs, 2)
  comb_str = make_combination_str( region_combs(:, i), region_names );
  
  setcat( labs, 'region_pair', comb_str, region_I{i} );
end

end

function str = make_combination_str(comb, region_names)

for i = 1:numel(comb)
  match_indices = cellfun( @(x) strfind(comb{i}, x), region_names, 'un', 0 );
  is_match_index = find( ~cellfun(@isempty, match_indices) );
  
  if ( numel(is_match_index) ~= 1 )
    continue;
  end
  
  matching_region = region_names{is_match_index};
  match_index = match_indices{is_match_index};
  
  if ( numel(match_index) ~= 1 )
    % More than one occurrence of region in comb{i}
    continue;
  end
  
  comb{i} = matching_region;
end

str = strjoin( sort(comb), '_' );

end