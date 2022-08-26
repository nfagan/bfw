function coh_labels = clean_sfcoherence_labels(coh_labels)

do_sort = false;
src_reg_pairs = combs( coh_labels, 'region' );
src_regs = cellfun( @(x) strsplit(x, '_'), src_reg_pairs, 'un', 0 );
dst_regs = clean_region_pairs( src_regs, do_sort );

for i = 1:numel(src_reg_pairs)
  replace( coh_labels, src_reg_pairs{i}, dst_regs{i} );
end

[I, regs] = findall( coh_labels, 'region' );
split_regs = split_regions( regs );
set_spike_field_regions( coh_labels, split_regs, I );

sorted_regs = eachcell( @(x) sort(x), split_regs );
joined_regs = eachcell( @(x) sprintf('pair-%s', strjoin(x, '_')), sorted_regs );
for i = 1:numel(I)
  addsetcat( coh_labels, 'region-pair', joined_regs{i}, I{i} );
end

end

function labels = set_spike_field_regions(labels, regions, I)

for i = 1:numel(regions)
  addsetcat( labels, 'spk-region', sprintf('spk-%s', regions{i}{1}), I{i} );
  addsetcat( labels, 'lfp-region', sprintf('lfp-%s', regions{i}{2}), I{i} );
end

prune( labels );

end

function pairs = split_regions(src_regs)
pairs = cellfun( @(x) strsplit(x, '_'), src_regs, 'un', 0 );
end

function dst_regs = clean_region_pairs(src_regs, do_sort)

regs = src_regs;
dst_regs = cell( size(src_regs) );
for i = 1:numel(regs)
  regs{i} = cellfun( @(x) strrep(x, 'accg', 'acc'), regs{i}, 'un', 0 );
  if ( do_sort )
    regs{i} = sort( regs{i} );
  end
  dst_regs{i} = strjoin( regs{i}, '_' );
end

end