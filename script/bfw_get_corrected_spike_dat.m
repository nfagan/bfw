function [spikedat, spikelabs] = bfw_get_corrected_spike_dat(varargin)

defaults = bfw.get_common_make_defaults();
defaults.spike_p = '/Users/Nick/Downloads/spike_data_label_corrected';

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

spike_p = params.spike_p;
meta_p = bfw.gid( 'meta', conf );

spike_files = shared_utils.io.find( spike_p, '.mat' );
spike_unified_filenames = shared_utils.io.filenames( spike_files, true );

spikedat = {};
spikelabs = fcat();

for i = 1:numel(spike_files)
  shared_utils.general.progress( i, numel(spike_files) );
  
  spike_file = shared_utils.io.fload( spike_files{i} );
  unified_filename = spike_unified_filenames{i};
  
  try
    meta_file = bfw.load_intermediate( meta_p, unified_filename );
    meta_labs = bfw.struct2fcat( meta_file );
    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  n_units = numel( spike_file );
  
  for j = 1:n_units
    unit = spike_file(j);
    
    labs = fcat.from( bfw.get_unit_labels(unit) );
    join( labs, meta_labs );
    
    append( spikelabs, labs );
    spikedat = [ spikedat; {unit.times} ];
  end
end

assert_ispair( spikedat, spikelabs );
end