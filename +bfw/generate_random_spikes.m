function out = generate_random_spikes( N, sample_rate, min_t, max_t )

%   GENERATE_RANDOM_SPIKES -- Generate random spike times.
%
%     IN:
%       - `N` (double) -- Number of spike times to generate.
%       - `sample_rate` (double)
%       - `min_t` (double) -- Minimum spike time.
%       - `max_t` (double) -- Maximum spike time.
%     OUT:
%       - `out` (double) -- Nx1 array of random spike times.

assert( min_t < max_t, 'Min time must be less than max time.' );

out = zeros( N, 1 );

for i = 1:N
  out(i) = generate_one( sample_rate, min_t, max_t );
end

end

function x = generate_one( sample_rate, min_t, max_t )

fs = 1 / sample_rate;
n_samples = floor( (max_t - min_t) / fs );
chosen_sample = randi( n_samples, 1 );
x = chosen_sample * fs + min_t;

end