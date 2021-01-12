conf = bfw.config.load();

sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/events/sorted_events.mat') );

[~, transform_ind] = bfw.make_whole_face_roi( sorted_events.labels );
sorted_events.events = sorted_events.events(transform_ind, :);
labs = sorted_events.labels';

%%

base_mask_func = @(l, m) fcat.mask( l, m ...
  , @findnot, {'mutual', 'm2'} ...
);

nonsocial_obj_rois = {'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched'};

find_ns_objs = @(labels) findor(labels, nonsocial_obj_rois);

% Remove samples of the "nonsocial object roi" prior to the actual
% introduction of the object.
base_mask_func = @(l, m) setdiff(...
    base_mask_func(l, m) ...
  , bfw.find_sessions_before_nonsocial_object_was_added(l, find_ns_objs(l)) ...
);

%%

roi_pairs = { {'eyes_nf', 'face'}, {'whole_face', 'right_nonsocial_object'} ...
  , {'eyes_nf', 'right_nonsocial_object_eyes_nf_matched'} };

roi_pair_labels = cellfun( @(x) sprintf('%s-%s', x{1}, x{2}), roi_pairs, 'un', 0 );

mod_index_each = { 'unified_filename' };
base_labels = sorted_events.labels';
mask = base_mask_func( base_labels, rowmask(base_labels) );

[run_labels, run_I] = keepeach( base_labels', mod_index_each, mask );

mod_indices = nan( numel(run_I) * numel(roi_pairs), 1 );
mod_index_labels = fcat();
index_stp = 1;

for i = 1:numel(run_I)
  run_ind = run_I{i};
  
  for j = 1:numel(roi_pairs)
    a = roi_pairs{j}{1};
    b = roi_pairs{j}{2};

    ind_a = find( base_labels, a, run_ind );
    ind_b = find( base_labels, b, run_ind );
    
    cts_a = numel( ind_a );
    cts_b = numel( ind_b );
    
    ind = (cts_a - cts_b) / (cts_a + cts_b);
    
    mod_indices(index_stp) = ind;
    index_stp = index_stp + 1;
  end
  
  f = run_labels(i);
  repset( addcat(f, 'roi-pair'), 'roi-pair', roi_pair_labels );
  append( mod_index_labels, f );
end

%%

pl = plotlabeled.make_common();
axs = pl.bar( mod_indices, mod_index_labels, {}, {'roi-pair'}, {} );

%%

save_p = fullfile( bfw.dataroot(conf), 'analyses', 'modulation_indices', dsp3.datedir );
shared_utils.io.require_dir( save_p );
file_path = fullfile( save_p, 'modulation_index.mat' );

save( file_path, 'mod_indices', 'mod_index_labels' );