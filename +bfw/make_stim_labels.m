function labs = make_stim_labels(n_stim, n_sham)

stim = fcat.create( 'stim_type', 'stim' );
repmat( stim, n_stim );
sham = fcat.create( 'stim_type', 'sham' );
repmat( sham, n_sham );

labs = append( stim', sham );

end