labels = spike_data.labels';
one_unit_ind = find( labels, ref(combs(labels, 'unit_uuid'), '()', 1) );
spike_ts = spike_data.spike_times{one_unit_ind};

spike_ts = spike_ts - min( spike_ts );
spike_ts = spike_ts(:)';

%%

ts = circularShuffleSpikes( spike_ts(1:10), 0.1 );

function [circ_shuff_spikes] = circularShuffleSpikes(spike_ms, shuff_ms)
%CIRCULARSHUFFLESPIKES Circular time shuffling of vector 'spikeMs' by lag
%'shuffMs'
above_ms = spike_ms(spike_ms > shuff_ms) ;
below_ms = spike_ms(spike_ms <= shuff_ms);
above_ms_offset = above_ms - shuff_ms;
below_ms_offset = below_ms + ( max(spike_ms) - shuff_ms );
circ_shuff_spikes = [above_ms_offset, below_ms_offset];

end