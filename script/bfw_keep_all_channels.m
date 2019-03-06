function [lfp_inds, spike_inds] = bfw_keep_all_channels(lfp_labels, spike_labels)

lfp_inds = rowmask( lfp_labels );
spike_inds = findnone( spike_labels, 'unit_rating__0' );

end