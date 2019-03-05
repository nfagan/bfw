function coh_file = raw_sfcoherence(files, varargin)

defaults = bfw.make.defaults.raw_sfcoherence;
params = bfw.parsestruct( defaults, varargin );

bfw.validatefiles( files, {'lfp', 'spikes', params.events_subdir} );

lfp_file = shared_utils.general.get( files, 'lfp' );
spike_file = shared_utils.general.get( files, 'spikes' );

if ( spike_file.is_link )
  files('spikes') = load_linked_file( spike_file, 'spike_subdir', 'spikes', params );
end

if ( lfp_file.is_link )
  files('lfp') = load_linked_file( lfp_file, 'lfp_subdir', 'lfp', params );
end

pruned_params = prune_fields( bfw.make.defaults.raw_aligned_lfp(), params );
aligned_lfp = bfw.make.raw_aligned_lfp( files, pruned_params );

end

function b = prune_fields(a, b)

non_shared_fields = setdiff( fieldnames(b), fieldnames(a) );
b = rmfield( b, non_shared_fields );

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