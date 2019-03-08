function labs = add_region_pair_labels(labs, region_cats)

if ( nargin < 2 )
  region_cats = { 'region', 'spike_region' };
end

region_combs = combs( labs, region_cats );

d = 10;

end