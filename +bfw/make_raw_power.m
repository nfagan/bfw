function make_raw_power(varargin)

ff = @fullfile;

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.step_size = 50;
defaults = bfw.get_common_lfp_defaults( defaults );

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

aligned_p = bfw.gid( ff('event_aligned_lfp', isd), conf );
output_p = bfw.gid( ff('raw_power', osd), conf );

lfp_mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

step_size = params.step_size;

for i = 1:numel(lfp_mats)
  fprintf( '\n %d of %d', i, numel(lfp_mats) );
  
  lfp = fload( lfp_mats{i} );
  
  un_filename = lfp.unified_filename;
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  shared_utils.io.require_dir( output_p );
  
  if ( lfp.is_link )
    pow_struct = struct();
    pow_struct.is_link = true;
    pow_struct.data_file = lfp.data_file;
    pow_struct.unified_filename = un_filename;
    do_save( output_filename, pow_struct );
    continue;
  end
  
  lfp_cont = lfp.lfp;
  
  if ( params.filter )
    f1 = params.f1;
    f2 = params.f2;
    filt_order = params.filter_order;
    fs = params.sample_rate;
    lfp_cont.data = bfw.zpfilter( lfp_cont.data, f1, f2, fs, filt_order );
  end
  
  if ( params.reference_subtract )
    lfp_cont = bfw.ref_subtract( lfp_cont );
  else
    lfp_cont = lfp_cont.rm( 'ref' );
  end
  
  window_size = lfp.params.window_size;
  
  windowed_data = shared_utils.array.bin3d( lfp_cont.data, window_size, step_size );
  
  chronux_params = struct();
  chronux_params.Fs = params.sample_rate;
  chronux_params.tapers = [ 1.5, 2 ];
  
  channels = lfp_cont( 'channel' );
  
  is_valid = true( 1, numel(channels) );  
  res = cell( 1, numel(channels) );
  freqs = cell( size(res) );
  
  for j = 1:numel(channels)
    
    index_a = lfp_cont.where( channels{j} );
    
    subset_a = windowed_data(index_a, :, :);
    
    for h = 1:size(subset_a, 3)      
      one_t_a = subset_a(:, :, h)';
      
      [pxx, f] = mtspectrumc( one_t_a, chronux_params );
      
      pxx = pxx';
      
      if ( h == 1 )
        all_c = nan( [size(pxx), size(subset_a, 3)] );
      end
      
      all_c(:, :, h) = pxx;      
    end
    
    cont = Container( all_c, lfp_cont.labels.keep(index_a) );    
    res{j} = cont;
    freqs{j} = f;
  end
  
  if ( ~all(is_valid) )
    fprintf( '\n Skipped some. Not saving "%s" ... ', un_filename );
    continue;
  end
  
  pow_struct = struct();
  pow_struct.is_link = false;
  pow_struct.raw_power = res;
  pow_struct.frequencies = freqs{1};
  pow_struct.unified_filename = un_filename;
  pow_struct.params = params;
  pow_struct.align_params = lfp.params;
  
  do_save( output_filename, pow_struct, '-v7.3' );
end

end

function do_save(filename, variable, varargin)
save( filename, 'variable', varargin{:} );
end