function [lfp_inds, spike_inds] = bfw_keep_first_channel(lfp_labels, spike_labels)

region_I = findall( lfp_labels, 'region' );

lfp_inds = [];

for i = 1:numel(region_I)
  channel_I = findall( lfp_labels, 'channel', region_I{i} );
  lfp_inds = union( lfp_inds, channel_I{1} );
end

spike_inds = findnone( spike_labels, 'unit_rating__0' );

end