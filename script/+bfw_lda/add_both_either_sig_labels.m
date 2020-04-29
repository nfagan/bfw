function labels = add_both_either_sig_labels(labels)

gaze_sig = find( labels, 'gaze-sig-true' );
rwd_sig = find( labels, 'rwd-sig-true' );

both_sig = intersect( gaze_sig, rwd_sig );
either_sig = union( gaze_sig, rwd_sig );

addsetcat( labels, 'both-sig', 'both-sig-false' );
setcat( labels, 'both-sig', 'both-sig-true', both_sig );

addsetcat( labels, 'either-sig', 'either-sig-false' );
setcat( labels, 'either-sig', 'either-sig-true', either_sig );

end