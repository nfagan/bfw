function defaults = raw_fixations(varargin)

%   RAW_FIXATIONS -- Get default parameter values for ... 
%     make.raw_fixations function.

defaults = bfw.get_common_make_defaults( varargin{:} );

% eye mmv defaults

% 'min_duration' gives the minimum amount of seconds required to be
% considered a fixation. 
defaults.min_duration = 0.01;
defaults.t1 = 30;
defaults.t2 = 15;

% arduio defaults

% 'threshold' gives the number of *pixels* of dispersion for which the eye
% is no longer considered to be fixating.
defaults.threshold = 20;

% 'n_samples' gives the number of samples over which to calculate
% dispersion. 
defaults.n_samples = 4;

% 'update_interval' gives the sampling interval of the is_fixation vector.
% If the value is 1, then every sampled is processed; for values larger
% than 1, only every N-th sample is processed, where N is the update
% interval.
defaults.update_interval = 1;

end