function [coh, has_data] = bfw_normalize_sfcoherence(src_coh, coh_labels, varargin)

assert_ispair( src_coh, coh_labels );

defaults = struct();
defaults.norm_type = 'minus_mean';
defaults.cs_coh = [];
defaults.cs_coh_labels = fcat();
defaults.cs_t = [];
defaults.normalizer = src_coh;

params = shared_utils.general.parsestruct( defaults, varargin );

coh_norm_type = params.norm_type;
cs_coh = params.cs_coh;
cs_coh_labels = params.cs_coh_labels;
cs_t = params.cs_t;

normalizer = params.normalizer;

assert_ispair( cs_coh, cs_coh_labels );
assert( isempty(cs_coh) || numel(cs_t) == size(cs_coh, 3) );
assert_ispair( normalizer, coh_labels );

need_set_has_data = true;
switch ( coh_norm_type )
  case 'minus_mean'
    norm_I = findall( coh_labels, {'session', 'lfp-region'} );
    mus = bfw.row_nanmean( double(normalizer), norm_I );
    coh = src_coh;
    for i = 1:numel(norm_I)
      ni = norm_I{i};
      coh(ni, :, :) = coh(ni, :, :) - mus(i, :, :);
    end

  case 'norm01'
    norm_I = findall( coh_labels, {'session', 'lfp-region'} );
    mins = cate1( rowifun(@(x) min(x, [], 1), norm_I, normalizer, 'un', 0) );
    maxs = cate1( rowifun(@(x) max(x, [], 1), norm_I, normalizer, 'un', 0) );
    coh = src_coh;
    for i = 1:numel(norm_I)
      ni = norm_I{i};
      span = rowref( maxs, i ) - rowref( mins, i );
      coh(ni, :, :) = (rowref(coh, ni) - rowref(mins, i)) ./ span;
    end
    
  case 'zscore'
    norm_I = findall( coh_labels, {'session', 'channel', 'region', 'unit_uuid'} );
    coh = src_coh;
    for i = 1:numel(norm_I)
      ni = norm_I{i};
      subset = rowref( src_coh, ni );
      mu = nanmean( subset, 1 );
      dev = nanstd( subset, [], 1 );
      coh(ni, :, :) = (subset - mu) ./ dev;
    end

  case {'cs', 'zscore_cs'}
    %%
    [coh_I, norm_C] = findall( coh_labels, {'session', 'channel', 'region', 'unit_uuid'} );
    cs_I = bfw.find_combinations( cs_coh_labels, norm_C );
    
%     [cs_I, cs_C] = findall( cs_coh_labels, {'session', 'channel', 'region', 'unit_uuid'} );
%     coh_I = bfw.find_combinations( coh_labels, cs_C );
    coh = nan( size(src_coh) );
    has_data = false( size(src_coh, 1), 1 );
    
    cs_subset = nanmean( cs_coh(:, :, cs_t >= 0 & cs_t < 0.15), 3 );
    for i = 1:numel(coh_I)
      src_i = cs_I{i};
      dst_i = coh_I{i};
      mu = nanmean( cs_subset(src_i, :, :), 1 );
      dev = nanstd( cs_subset(src_i, :, :), [], 1 );
      minus_mu = (src_coh(dst_i, :, :) - mu);
      if ( strcmp(coh_norm_type, 'zscore_cs') )
        coh(dst_i, :, :) = minus_mu ./ dev;
      else
        coh(dst_i, :, :) = minus_mu;
      end
      has_data(coh_I{i}) = true;
    end
    coh(~isfinite(coh)) = nan;
    need_set_has_data = false;

  case 'none'
    coh = src_coh;

  otherwise
    error( 'Unrecognized coh norm type "%s".', coh_norm_type );
end

if ( need_set_has_data )
  has_data = true( size(coh, 1), 1 );
end

end