function defaults = binned_aligned_samples(varargin)

defaults = bfw.get_common_make_defaults( varargin{:} );

% For binned_aligned_fixations, gives the name of the subdirectory
% containing the fixation files.
defaults.fixations_subdir = 'raw_eye_mmv_fixations';

% Window size of binning function, in ms.
defaults.window_size = 10;

% Step size of binning function, in ms
defaults.step_size = 10;

% Whether to discard the final bin if it has fewer than `window_size`
% elements.
defaults.discard_uneven = true;

end