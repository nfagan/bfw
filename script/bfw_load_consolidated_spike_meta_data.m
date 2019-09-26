function meta_data = bfw_load_consolidated_spike_meta_data(varargin)

file_path = fullfile( bfw.dataroot(varargin{:}), 'consolidated', 'spike_meta_data.mat' );
meta_data = shared_utils.io.fload( file_path );

end