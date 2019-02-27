function coh_file = raw_sfcoherence(files, varargin)

defaults = bfw.make.defaults.raw_sfcoherence;
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, {'lfp', 'spikes', 'raw_events'} );

lfp_file = shared_utils.general.get( files, 'lfp' );
spike_file = shared_utils.general.get( files, 'spikes' );
events_file = shared_utils.general.get( files, 'raw_events' );

if ( spike_file.is_link )
  spike_file = load_linked_file( spike_file, 'spike_subdir', 'spikes', params );
end

if ( lfp_file.is_link )
  lfp_file = load_linked_file( lfp_file, 'lfp_subdir', 'lfp', params );
end

d = 10;

end

function data_file = load_linked_file(link_file, subdir_fieldname, kind, params)

conf = params.config;
subdir = params.(subdir_fieldname);

data_filepath = fullfile( bfw.gid(subdir, conf), link_file.data_file );

if ( ~shared_utils.io.fexists(data_filepath) )
  error( 'Missing linked %s file: "%s".', kind, data_filepath );
end

data_file = shared_utils.io.fload( data_filepath );

end