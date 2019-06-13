function labels = make_stim_labels(files, image_indices)

meta_file = shared_utils.general.get( files, 'meta' );
stim_meta_file = shared_utils.general.get( files, 'stim_meta' );
stim_file = shared_utils.general.get( files, 'stim' );
un_file = shared_utils.general.get( files, 'unified' );

trial_data = un_file.m1.trial_data;

n_stim_times = numel( stim_file.stimulation_times ) + numel( stim_file.sham_times );

labels = repmat( bfw.struct2fcat(meta_file), n_stim_times );
stim_meta_labels = bfw.stim_meta_to_fcat( stim_meta_file );
join( labels, stim_meta_labels );

add_stim_type_labels( labels, stim_file );

image_ids = { trial_data(image_indices).image_identifier };

addcat( labels, 'image_id' );
setcat( labels, 'image_id', image_ids );

stim_ids = arrayfun( @(x) sprintf('stim_id_%d', x), 1:n_stim_times, 'un', 0 );

addcat( labels, 'stim_id' );
setcat( labels, 'stim_id', stim_ids );

prune( labels );

end

function add_stim_type_labels(labels, stim_file)

n_stim = numel( stim_file.stimulation_times );
n_sham = numel( stim_file.sham_times );
assert( rows(labels) == n_stim + n_sham );

addcat( labels, 'stim_type' );
setcat( labels, 'stim_type', 'stim', 1:n_stim );
setcat( labels, 'stim_type', 'sham', n_stim+1:rows(labels) );

end