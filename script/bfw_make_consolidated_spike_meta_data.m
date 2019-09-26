function bfw_make_consolidated_spike_meta_data(varargin)

data_p = fullfile( bfw.dataroot(varargin{:}), 'consolidated' );
consolidated_file_path = fullfile( data_p, 'spike_data07312019.mat' );
save_file_path = fullfile( data_p, 'spike_meta_data.mat' );

consolidated = load( consolidated_file_path );
consolidated = consolidated.spike_data;

rem_fields = { 'times', 'sessions', 'blks_info' };

meta_data = rmfield( consolidated, rem_fields );
save( save_file_path, 'meta_data' );

end