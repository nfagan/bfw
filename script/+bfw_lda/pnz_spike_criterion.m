function mask = pnz_spike_criterion(spikes, labels, mask, thresh)

assert_ispair( spikes, labels );

if ( pnz(spikes(mask)) < thresh )
  mask = [];
end

end