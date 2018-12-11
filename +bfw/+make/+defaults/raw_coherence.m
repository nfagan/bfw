function defaults = raw_coherence(varargin)

defaults = bfw.get_common_make_defaults( varargin{:} );
defaults = bfw.get_common_lfp_defaults( defaults );
defaults.step_size = 50;
defaults.chronux_params = struct( ...
  'tapers', [1.5, 2] ...
);

end