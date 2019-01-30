function make_binned_aligned_samples(varargin)

defaults = bfw.make.defaults.binned_aligned_samples();
params = bfw.parsestruct( defaults, varargin );

bfw.make_binned_aligned_time( params);
bfw.make_binned_aligned_position( params );
bfw.make_binned_aligned_bounds( params );
bfw.make_binned_aligned_fixations( params, 'fixations_subdir', 'raw_eye_mmv_fixations' );
bfw.make_binned_aligned_fixations( params, 'fixations_subdir', 'raw_arduino_fixations' );

end