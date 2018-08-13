function make_sfcoherence(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.step_size = 50;
defaults = bfw.get_common_lfp_defaults( defaults );

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

aligned_p = bfw.get_intermediate_directory( 'event_aligned_lfp', conf );
rng_p = bfw.get_intermediate_directory( 'rng', conf );
spike_p = bfw.get_intermediate_directory( 'per_trial_mua', conf );
output_p = bfw.get_intermediate_directory( 'sfcoherence', conf );

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
  
  rng_file = shared_utils.io.fload( fullfile(rng_p, un_filename) );
  
  shared_utils.io.require_dir( output_p );
  
  if ( lfp.is_link )
    coh_struct = struct();
    coh_struct.is_link = true;
    coh_struct.data_file = lfp.data_file;
    coh_struct.unified_filename = un_filename;
    do_save( output_filename, coh_struct );
    continue;
  end
  
  spike_filename = fullfile( spike_p, un_filename );
  
  if ( ~shared_utils.io.fexists(spike_filename) )
    warning( 'Missing spike file for "%s".', un_filename );
    continue;
  end
  
  spike_file = shared_utils.io.fload( spike_filename );
  
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
  
  regions = lfp_cont('region');
  
  if ( numel(regions) ~= 2 )
    fprintf( '\n Skipping "%s" because there were %d region(s); expected 2.' ...
      , un_filename, numel(regions) );
    continue;
  end
  
  spike_cont = spike_file.data;
  
  window_size = lfp.params.window_size;
  
  windowed_lfp = shared_utils.array.bin3d( lfp_cont.data, window_size, step_size );  
  windowed_spikes = spike_cont.data;
  
  if ( numel(spike_file.time) ~= size(windowed_lfp, 3) )
    error( 'Mismatch in time dimension for lfp and spikes.' );
  end
  
  chronux_params = struct();
  chronux_params.Fs = params.sample_rate;
  chronux_params.tapers = [ 1.5, 2 ];
 
  channels_reg_a = lfp_cont.uniques_where( 'channel', regions{1} );
  channels_reg_b = lfp_cont.uniques_where( 'channel', regions{2} );
  
  chans_a = cellfun( @(x) str2double(x(3:4)), channels_reg_a );
  chans_b = cellfun( @(x) str2double(x(3:4)), channels_reg_b );
  
  rng( rng_file.state );
  
  pairs = bfw.select_pairs( chans_a, chans_b, 16 );
  
  is_valid = true( 1, size(pairs, 1) );  
  res = cell( 1, size(pairs, 1) );
  freqs = cell( size(res) );
  
  for j = 1:size(pairs, 1)    
    channel_a = num2str_zeropad( 'FP', pairs(j, 1) );
    channel_b = num2str_zeropad( 'WB', pairs(j, 2) );
    
    index_a = lfp_cont.where( {regions{1}, channel_a} );
    index_b = spike_cont.where( {regions{2}, channel_b} );
    
    if ( sum(index_a) ~= sum(index_b) )
      fprintf( ['\n Skipping "%s" because distributions across channels had' ...
        , ' different numbers of trials.'], un_filename );
      is_valid(j) = false;
      continue;
    end
    
    subset_a = windowed_lfp(index_a, :, :);
    subset_b = windowed_spikes(index_b, :);
    
    for h = 1:size(subset_a, 3)      
      one_t_a = subset_a(:, :, h)';
      one_t_b = subset_b(:, h);
      one_t_b = cellfun( @(x) struct('times', x), one_t_b );
      
      [C,~,~,~,~,f] = coherencycpt( one_t_a, one_t_b, chronux_params );
      
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
  coh_struct.sfcoherence = res;
  coh_struct.frequencies = freqs{1};
  coh_struct.unified_filename = un_filename;
  coh_struct.params = params;
  coh_struct.align_params = lfp.params;
  
%   do_save( output_filename, coh_struct, '-v7.3' );
  do_save( output_filename, coh_struct );
end

end

function B = select_gt( A, thresh )

if ( numel(A) < 2 )
  B = A;
  return;
end

first_ind = 1;
sec_ind = first_ind + 1;

B = A(1);

while ( first_ind <= numel(A) && sec_ind <= numel(A) )
  
  first = A(first_ind);
  sec = A(sec_ind);
  
  difference = abs( sec - first );
  
  if ( difference >= thresh )
    B(end+1) = sec;
    first_ind = sec_ind;
  end
  
  sec_ind = sec_ind + 1;
end

B = B(:);

end

function n = num2str_zeropad(pref, n)

if ( n < 10 )
  n = sprintf( '%s0%d', pref, n );
else
  n = sprintf( '%s%d', pref, n );
end

end

function do_save(filename, variable, varargin)
save( filename, 'variable', varargin{:} );
end

%       dt = 1/chronux_params.Fs;
%       N = size(one_t_a, 1);
%       
%       start_ts = [ 0, -0.5, -1 ];
%       
%       cs = cell( 1, numel(start_ts) );
%       ts = cell( 1, numel(start_ts) );
%       
%       for hdx = 1:numel(start_ts)
%       
%         start_t = start_ts(hdx);
%         t = (0:dt:(N-1)*dt) + start_t;
% 
%         one_t_b_prime = arrayfun( @(x) setfield(x, 'times', x.times + start_t), one_t_b );
% 
%   %       [C,~,~,~,~,f] = coherencycpt( one_t_a, one_t_b, chronux_params, [], t );
%         [C,~,~,~,~,f] = coherencycpt( one_t_a, one_t_b_prime, chronux_params, [], t );
% 
%         C = C';
%         
%         cs{hdx} = C;
%         ts{hdx} = t;
%       end
%       
%       figure(1); clf();
%       plot( cs{1}(1, :), 'r' ); hold on;
%       plot( cs{2}(1, :), 'b' ); hold on;
%       
%       legend( arrayfun(@num2str, start_ts, 'un', false) );
