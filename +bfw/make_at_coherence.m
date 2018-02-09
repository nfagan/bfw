function make_at_coherence(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.within = { 'looks_to', 'looks_by' };
defaults.summary_function = @rowops.nanmean;

params = bfw.parsestruct( defaults, varargin );

coh_p = bfw.get_intermediate_directory( 'coherence' );
output_p = bfw.get_intermediate_directory( 'at_coherence' );

coh_mats = bfw.require_intermediate_mats( params.files, coh_p, params.files_containing );

for i = 1:numel(coh_mats)
  fprintf( '\n %d of %d', i, numel(coh_mats) );
  
  coh = fload( coh_mats{i} );
  
  un_filename = coh.unified_filename;
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  shared_utils.io.require_dir( output_p );
  
  if ( coh.is_link )
    coh_struct = struct();
    coh_struct.is_link = true;
    coh_struct.data_file = coh.data_file;
    coh_struct.unified_filename = un_filename;
    do_save( output_filename, coh_struct );
    continue;
  end
  
  output_coherence = coh.coherence;
  
  for j = 1:numel(output_coherence)
    c_coh = output_coherence{j};
    output_coherence{j} = c_coh.each1d( params.within, params.summary_function );
  end
  
  coh_struct = struct();
  coh_struct.is_link = false;
  coh_struct.coherence = Container.concat( output_coherence );
  coh_struct.frequencies = coh.frequencies;
  coh_struct.unified_filename = un_filename;
  coh_struct.params = params;
  coh_struct.within_trial_params = coh.params;
  coh_struct.align_params = coh.align_params;
  do_save( output_filename, coh_struct );
end

end

function do_save(filename, variable)
save( filename, 'variable' );
end