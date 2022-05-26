function [cohs, freqs, t, info] = sfcoherence(spikes, lfp, events, pairs, varargin)

defaults.min_t = -0.5;
defaults.max_t = 0.5;
defaults.bin_width = 0.15;
defaults.bin_step = 0.05;
defaults.fs = 1e3;
defaults.chronux_params = struct( 'Fs', 1e3, 'tapers', [1.5, 2] );
defaults.verbose = false;
defaults.f_lims = [-inf, inf];
defaults.keep_if = @(x) true(size(x, 1), 1);
defaults.single_precision = false;

params = shared_utils.general.parsestruct( defaults, varargin );

t = params.min_t:params.bin_step:params.max_t;

cohs = cell( size(pairs, 1), 1 );
freqs = cell( size(cohs) );
inds = cell( size(cohs) );

parfor i = 1:size(pairs, 1)
  if ( params.verbose )
    fprintf( '\n %d of %d', i, size(pairs, 1) );
  end
  
  p = pairs(i, :);
  unit = spikes{p(1)};
  channel = lfp(p(2), :);
  
  for j = 1:numel(t)
    t0 = events(:) + t(j) - params.bin_width * 0.5;
    t1 = t0 + params.bin_width;
    
    aligned_lfp = align_lfp_window( channel, t0, params );
    aligned_spikes = align_spikes( unit, t0, t1 );    
    
    [C,~,~,~,~,f] = coherencycpt( aligned_lfp', aligned_spikes, params.chronux_params );
    f_ind = f >= params.f_lims(1) & f <= params.f_lims(2);
    C = C(f_ind, :);
    f = f(f_ind);
    
    if ( j == 1 )
      coh = nan( size(C, 2), size(C, 1), numel(t) );
    end
    coh(:, :, j) = C';
  end
  
  keep_ind = find( params.keep_if(coh) );
  coh = coh(keep_ind, :, :);
  inds{i} = keep_ind;
  
  if ( params.single_precision )
    coh = single( coh );
  end
  
  cohs{i} = coh;
  freqs{i} = f;
end

if ( isempty(cohs) )
  freqs = [];
  t = [];
else
  freqs = freqs{1};
end

if ( nargout > 3 )
  info = struct();
  info.params = params;
  info.inds = inds;
end

end

function aligned_spks = align_spikes(unit, t0, t1)

aligned_spks = struct( 'spikes', {} );
for i = 1:numel(t0)
  spk_ind = unit >= t0(i) & unit < t1(i);
  aligned_ts = unit(spk_ind) - t0(i);
  aligned_spks(i) = struct( 'spikes', aligned_ts(:) );
end

end

function [aligned_lfp, ok_t] = align_lfp_window(channel, t0, params)

ib_ind = @(i) i >= 0 & i < numel(channel);

lfp_bin_size = floor( params.bin_width * params.fs );
trunc_t0 = floor( t0 ./ (1 / params.fs) ) * (1 / params.fs);
lfp_i0 = floor( trunc_t0 * params.fs );
lfp_i1 = lfp_i0 + lfp_bin_size;

aligned_lfp = nan( numel(t0), lfp_bin_size );

ok_t = find( ~isnan(t0) & ib_ind(lfp_i0) & ib_ind(lfp_i1) );
for i = 1:numel(ok_t)
  i0 = lfp_i0(ok_t(i)) + 1;
  i1 = lfp_i1(ok_t(i)) + 1;
  aligned_lfp(ok_t(i), :) = channel(i0:i1-1);
end

end