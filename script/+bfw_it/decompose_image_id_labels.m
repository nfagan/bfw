function labels = decompose_image_id_labels(labels)

image_types = labels(:, 'image_id');
split_types = cellfun( @(x) strsplit(x, '/'), image_types, 'un', 0 );

monkeys = cellfun( @(x) sprintf('monkey-%s', x{1}), split_types, 'un', 0 );
directions = cellfun( @(x) sprintf('direction-%s', x{2}), split_types, 'un', 0 );
filenames = cellfun( @(x) sprintf('image-%s', x{3}), split_types, 'un', 0 );

addsetcat( labels, 'image_monkey', monkeys );
addsetcat( labels, 'image_direction', directions );
addsetcat( labels, 'image_filename', filenames );

end