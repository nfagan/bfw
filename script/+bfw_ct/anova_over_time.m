function outs = anova_over_time(psth, labels, t, varargin)

defaults = struct();
defaults.time_windows = { [0, 0.3], [-0.3, 0] };
defaults.exclusive_end_range = [ false, true ];
defaults.flip_range = [ false, true ];
defaults.mask_func = @(l, m) m;
defaults.alpha = 0.05;
defaults.min_num_consecutive_significant = 1;

params = bfw.parsestruct( defaults, varargin );
validate_params( params );

mask = get_base_mask( labels, params.mask_func );

assert_ispair( psth, labels );
assert( numel(t) == size(psth, 2), 'Time vector does not correspond to columns of psth.' );

out_labels = cell( numel(params.time_windows), 1 );
out_mins = cell( size(out_labels) );

for i = 1:numel(params.time_windows)
  shared_utils.general.progress( i, numel(params.time_windows) );
  
  t_range = params.time_windows{i};
  
  if ( params.exclusive_end_range(i) )
    t_ind = find( t >= t_range(1) & t < t_range(2) );
  else
    t_ind = find( t >= t_range(1) & t <= t_range(2) );
  end
  
  window_outs = anova_multiple_time_windows( psth, labels', t_ind, mask );
  sig_inds = 1:numel( t_ind );
  
  if ( params.flip_range )
    sig_inds = fliplr( sig_inds );
  end
  
  is_sig = window_outs.p(:, sig_inds) < params.alpha;
  
  if ( params.min_num_consecutive_significant == 1 )
    [min_sig_inds, has_ind] = find_first_significant( is_sig );
  else
    [min_sig_inds, has_ind] = find_first_consecutive_significant( is_sig, params.min_num_consecutive_significant );
  end
  
  min_ts = nan( size(min_sig_inds) );
  min_ts(has_ind) = columnize( t(t_ind(sig_inds(min_sig_inds(has_ind)))) );
  
  out_mins{i} = min_ts;
  out_labels{i} = addsetcat( window_outs.p_labels, 'time_window', time_window_str(t_range) );
end

out_mins = vertcat( out_mins{:} );
out_labels = vertcat( fcat(), out_labels{:} );

outs = struct();
outs.min_ts = out_mins;
outs.min_labels = out_labels;

end

function validate_params(params)

validateattributes( params.time_windows, {'cell'}, {}, mfilename, 'time_windows' );
validateattributes( params.exclusive_end_range, {'logical'}, {'numel', numel(params.time_windows)} ...
  , mfilename, 'exclusive_end_range' );
validateattributes( params.flip_range, {'logical'}, {'numel', numel(params.time_windows)} ...
  , mfilename, 'flip_range' );

end

function str = time_window_str(t_range)

str = sprintf( '%0.2f:%0.2f', t_range(1), t_range(2) );

end

function [min_inds, has_ind] = find_first_consecutive_significant(is_sig, num_consecutive)

min_inds = nan( rows(is_sig), 1 );
has_ind = false( size(min_inds) );

for i = 1:numel(min_inds)
  [inds, durs] = shared_utils.logical.find_islands( is_sig(i, :) );
  first_consecutive = find( durs >= num_consecutive, 1 );
  
  if ( ~isempty(first_consecutive) )
    min_inds(i) = inds(first_consecutive);
    has_ind(i) = true;
  end
end

end

function [min_inds, has_ind] = find_first_significant(is_sig)

min_inds = nan( rows(is_sig), 1 );
has_ind = false( size(min_inds) );

for i = 1:numel(min_inds)
  first_sig = find( is_sig(i, :), 1 );
  
  if ( ~isempty(first_sig) )
    min_inds(i) = first_sig;
    has_ind(i) = true;
  end
end

end

function outs = anova_multiple_time_windows(psth, labels, t_indices, mask)

p_mat = [];
p_labels = fcat();

for i = 1:numel(t_indices)
  shared_utils.general.progress( i, numel(t_indices), ' ' );
  
  [ps, p_labels] = anova_one_time_window( psth(:, t_indices(i)), labels', mask );
  
  if ( i == 1 )
    p_mat = nan( rows(ps), numel(t_indices) );
  end
  
  p_mat(:, i) = ps;
end

outs = struct();
outs.p = p_mat;
outs.p_labels = p_labels;

end

function mask = get_base_mask(labels, mask_func)

mask = findnone( labels, 'outside1' );
mask = mask_func( labels, mask );

end

function [ps, p_labels] = anova_one_time_window(psth, labels, mask)

anovas_each = { 'region', 'unit_uuid' };
anova_factor = { 'roi' };

anova_outs = dsp3.anova1( psth, labels', anovas_each, anova_factor ...
  , 'mask', mask ...
);

ps = cellfun( @(x) x.Prob_F{1}, anova_outs.anova_tables );
p_labels = anova_outs.anova_labels';

end