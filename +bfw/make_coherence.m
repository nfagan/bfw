function make_coherence(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.step_size = 50;
defaults.sample_rate = 1e3;
defaults.reference_subtract = true;

params = bfw.parsestruct( defaults, varargin );

aligned_p = bfw.get_intermediate_directory( 'event_aligned_lfp' );
output_p = bfw.get_intermediate_directory( 'coherence' );

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
    coh_struct = struct();
    coh_struct.is_link = true;
    coh_struct.data_file = lfp.data_file;
    coh_struct.unified_filename = un_filename;
    do_save( output_filename, coh_struct );
    continue;
  end
  
  lfp_cont = lfp.lfp;
  
  if ( params.reference_subtract )
    lfp_cont = bfw.ref_subtract( lfp_cont );
  end
  
  regions = lfp_cont('region');
  
  if ( numel(regions) ~= 2 )
    fprintf( '\n Skipping "%s" because there were %d region(s); expected 2.' ...
      , un_filename, numel(regions) );
    continue;
  end
  
  window_size = lfp.params.window_size;
  
  windowed_data = shared_utils.array.bin3d( lfp_cont.data, window_size, step_size );
  
  chronux_params = struct();
  chronux_params.Fs = params.sample_rate;
  chronux_params.tapers = [ 1.5, 2 ];
 
  channels_reg_a = lfp_cont.uniques_where( 'channel', regions{1} );
  channels_reg_b = lfp_cont.uniques_where( 'channel', regions{2} );
  
  combinations = bfw.allcombn( {1:numel(channels_reg_a), 1:numel(channels_reg_b)} );
  
  combinations = combinations(1:4, :);
  
  is_valid = true( 1, size(combinations, 1) );  
  res = cell( 1, size(combinations, 1) );
  freqs = cell( size(res) );
  
  parfor j = 1:size(combinations, 1)    
    channel_a = channels_reg_a{ combinations{j, 1} };
    channel_b = channels_reg_b{ combinations{j, 2} };
    
    index_a = lfp_cont.where( {regions{1}, channel_a} );
    index_b = lfp_cont.where( {regions{2}, channel_b} );
    
    if ( sum(index_a) ~= sum(index_b) )
      fprintf( ['\n Skipping "%s" because distributions across channels had' ...
        , ' different numbers of trials.'], un_filename );
      is_valid(j) = false;
      continue;
    end
    
    subset_a = windowed_data(index_a, :, :);
    subset_b = windowed_data(index_b, :, :);
    
    for h = 1:size(subset_a, 3)      
      one_t_a = subset_a(:, :, h)';
      one_t_b = subset_b(:, :, h)';
      
      [C,~,~,~,~,f] = coherencyc( one_t_a, one_t_b, chronux_params );
      
      C = C';
      
      if ( h == 1 )
        all_c = nan( [size(C), size(subset_a, 3)] );
      end
      
      all_c(:, :, h) = C;      
    end
    
    cont = Container( all_c, lfp_cont.labels.keep(index_a) );
    cont('channel') = strjoin( {channel_a, channel_b}, '_' );
    cont('region') = strjoin( {regions{1}, regions{2}}, '_' );
    
    res{j} = cont;
    freqs{j} = f;
  end
  
  if ( ~all(is_valid) )
    fprintf( '\n Skipped some. Not saving "%s" ... ', un_filename );
    continue;
  end
  
  coh_struct = struct();
  coh_struct.is_link = false;
  coh_struct.coherence = res;
  coh_struct.frequencies = freqs{1};
  coh_struct.unified_filename = un_filename;
  coh_struct.params = params;
  
  do_save( output_filename, coh_struct, '-v7.3' );
end

end

function do_save(filename, variable, varargin)
save( filename, 'variable', varargin{:} );
end