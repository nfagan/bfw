function make_coherence(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.step_size = 50;

params = bfw.parsestruct( defaults, varargin );

aligned_p = bfw.get_intermediate_directory( 'event_aligned_lfp' );
output_p = bfw.get_intermediate_directory( 'coherence' );

lfp_mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

step_size = params.step_size;

for i = 1:numel(lfp_mats)
  
  lfp = fload( lfp_mats{i} );
  
  un_filename = lfp.unified_filename;
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  if ( lfp.is_link )
    coh_struct = struct();
    coh_struct.is_link = true;
    coh_struct.data_file = lfp.data_file;
    coh_struct.unified_filename = un_filename;
    do_save( output_filename, coh_struct );
    continue;
  end
  
  lfp_cont = lfp.lfp;
  
  window_size = lfp.params.window_size;
  
  windowed_data = shared_utils.array.bin3d( lfp_cont.data, window_size, step_size );
  
  params.chronux_params.Fs = obj.fs;
  [C,~,~,~,~,f] = coherencyc(a, b, params.chronux_params );
  
    
end

end

function do_save(filename, variable)
save( filename, 'variable' );
end