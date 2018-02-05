function [null_data, bin_t] = generate_null_psth(spikes, events, pre_t, post_t, bin_size, N_iterations, sample_rate)

N = numel( spikes );
min_spike = min( spikes );
max_spike = max( spikes );

for i = 1:N_iterations
  
  permed_spikes = bfw.generate_random_spikes( N, sample_rate, min_spike, max_spike );
  permed_spikes = sort( permed_spikes );
  
  if ( i == 1 )
    [psth, bin_t] = looplessPSTH( permed_spikes, events, pre_t, post_t, bin_size );
    null_data = zeros( N_iterations, numel(bin_t) );
  else
    psth = looplessPSTH( permed_spikes, events, pre_t, post_t, bin_size );
  end
  
  null_data(i, :) = psth;
end

end