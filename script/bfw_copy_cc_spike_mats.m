function bfw_copy_cc_spike_mats(varargin)

dest_dir = bfw.get_intermediate_directory( 'cc_spikes', varargin{:} );
mats = shared_utils.io.findmat( dest_dir );
names = shared_utils.io.filenames( mats );
is_invalid = cellfun( @(x) x(1) == '.', names );
names = names(~is_invalid);
sessions = eachcell( @(x) x(1:8), names );

source_dir = bfw.get_intermediate_directory( 'spikes', varargin{:} );
source_mats = shared_utils.io.findmat( source_dir );
source_names = shared_utils.io.filenames( source_mats );
source_sessions = eachcell( @(x) x(1:8), source_names );

for i = 1:numel(sessions)
  shared_utils.general.progress( i, numel(sessions) );
  
  should_copy = find( strcmp(source_sessions, sessions{i} ) & ~strcmp(source_names, names{i}) );
  
  for j = 1:numel(should_copy)
    dest_file = fullfile( dest_dir, source_names{should_copy(j)} );
    
    if ( ~endsWith(dest_file, '.mat') )
      dest_file = sprintf( '%s.mat', dest_file );
    end
    
    copyfile( source_mats{should_copy(j)}, dest_file );
  end
end

end