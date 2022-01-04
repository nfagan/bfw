function make_aligned_samples(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

bfw.make_aligned_time( params );
bfw.make_aligned_position( params );
bfw.make_aligned_bounds( params );
bfw.make_aligned_pupil_size( params );
bfw.make_aligned_fixations( params, 'fixations_subdir', 'raw_eye_mmv_fixations' );
bfw.make_aligned_fixations( params, 'fixations_subdir', 'raw_arduino_fixations' );

end