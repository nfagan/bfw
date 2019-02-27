function defaults = raw_sfcoherence(varargin)

lfp_defaults = bfw.get_common_lfp_defaults( varargin{:} );
defaults = bfw.get_common_make_defaults( lfp_defaults );

defaults.lfp_subdir = 'lfp';
defaults.spike_subdir = 'spikes';

end