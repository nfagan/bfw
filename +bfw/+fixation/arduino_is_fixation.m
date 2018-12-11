function is_fix = arduino_is_fixation(x, y, time, params)

ui = params.update_interval;
thresh = params.threshold;
nsamp = params.n_samples;

dispersion = bfw.fixation.Dispersion( thresh, nsamp, ui );

is_fix = dispersion.detect( x, y );

end