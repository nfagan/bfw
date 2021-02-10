function counts = load_only_gaze_spikes(conf)

if ( nargin < 1 )
  conf = bfw.config.load();
end

counts = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda/only_gaze_spikes/gaze_counts.mat') );

replace( counts.labels, 'right_nonsocial_object', 'nonsocial_object' );

[~, ind] = bfw.make_whole_face_roi( counts.labels );
counts.spikes = counts.spikes(ind, :);

end