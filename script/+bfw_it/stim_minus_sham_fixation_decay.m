function [p, p_labs, real_diffs, mean_null] = stim_minus_sham_fixation_decay(bounds, labels, perm_I, varargin)

defaults = struct();
defaults.iters = 1e3;
defaults.seed = [];
defaults.test_signed = false;
defaults.abs = false;

params = bfw.parsestruct( defaults, varargin );

assert_ispair( bounds, labels );
bounds = double( bounds );

if ( ~isempty(params.seed) )
  rng( params.seed );
end

real_diffs = nan( numel(perm_I), size(bounds, 2) );
null_diffs = nan( size(real_diffs) );

p_labs = fcat();

for i = 1:numel(perm_I)
  current_real_diff = mean_stim_minus_sham( bounds, labels, perm_I{i}, false );
  
  if ( params.abs )
    real_diffs(i, :) = abs( current_real_diff );
  else
    real_diffs(i, :) = current_real_diff;
  end
  
  append1( p_labs, labels, perm_I{i} );
end

real_diff = nanmean( real_diffs, 1 );
sig_counts = zeros( 1, size(bounds, 2) );
all_null = nan( params.iters, size(bounds, 2) );

for i = 1:params.iters
  null_diffs(:) = nan;
  
  for j = 1:numel(perm_I)
    current_null_diff = mean_stim_minus_sham( bounds, labels, perm_I{j}, true );
    
    if ( params.abs )
      null_diffs(j, :) = abs( current_null_diff );
    else
      null_diffs(j, :) = current_null_diff;
    end
  end
  
  null_diff = nanmean( null_diffs, 1 );
  
  if ( params.test_signed )
    is_test_lt = sign( real_diff ) == -1;
    is_test_gt = sign( real_diff ) == 1;
    
    is_sig = false( size(sig_counts) );
    is_sig(is_test_lt) = real_diff(is_test_lt) < null_diff(is_test_lt);
    is_sig(is_test_gt) = real_diff(is_test_gt) > null_diff(is_test_gt);
  else
    is_sig = abs( real_diff ) > abs( null_diff );
  end
  
  sig_counts = sig_counts + double( is_sig );
  all_null(i, :) = null_diff;
end

p = 1 - ( sig_counts / params.iters );
mean_null = nanmean( all_null, 1 );

one( p_labs );

end

function diff = mean_stim_minus_sham(bounds, labels, mask, shuffle)

n_perm = numel( mask );

stim_ind = find( labels, 'stim', mask );
sham_ind = find( labels, 'sham', mask );
n_stim = numel( stim_ind );

if ( shuffle )
  stim_ind = mask(randperm(n_perm, n_stim));
  sham_ind = setdiff( mask, stim_ind );
end

diff = mean_x_minus_y( bounds, stim_ind, sham_ind );

end

function diff = mean_x_minus_y(bounds, x_ind, y_ind)

diff = mean( bounds(x_ind, :), 1 ) - mean( bounds(y_ind, :), 1 );

end