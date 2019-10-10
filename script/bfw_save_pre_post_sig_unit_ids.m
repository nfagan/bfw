base_p = fullfile( bfw.dataroot(), 'analyses', 'cell_type_classification', '100319', 'main_effect_significant' );

pre_p = fullfile( base_p, '-250_0' );
post_p = fullfile( base_p, '0_250' );

filename = 'all_social_cell_ids.mat';

pre_labels = shared_utils.io.fload( fullfile(pre_p, filename) );
post_labels = shared_utils.io.fload( fullfile(post_p, filename) );

pre_sig = [ pre_labels.is_significant ];
post_sig = [ post_labels.is_significant ];

both_sig = pre_sig & post_sig;
neither_sig = ~pre_sig & ~post_sig;

neither_ids = post_labels(neither_sig);
both_ids = post_labels(both_sig);

save( fullfile(base_p, 'neither_pre_post_sig_ids.mat'), 'neither_ids' );
save( fullfile(base_p, 'both_pre_post_sig_ids.mat'), 'both_ids' );