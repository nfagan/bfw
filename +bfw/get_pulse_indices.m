function pulses = get_pulse_indices(samples)

pulses = shared_utils.logical.find_starts( samples > 4.9, 50 );

end