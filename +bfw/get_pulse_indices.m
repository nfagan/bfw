function pulses = get_pulse_indices(samples, duration)

if ( nargin < 2 )
  duration = 50;
end

pulses = shared_utils.logical.find_starts( samples > 4.9, duration );

end