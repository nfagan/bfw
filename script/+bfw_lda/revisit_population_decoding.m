function outs = revisit_population_decoding(gaze_counts, rwd_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.each = { 'region' };
defaults.gaze_mask_func = @bfw.default_mask_func;
defaults.rwd_mask_func = @bfw.default_mask_func;
defaults.gaze_t_win = [0, 0.3];
defaults.rwd_t_win = [-0.25, 0];
defaults.iters = 1;
defaults.shuffle = false;
defaults.permutation_test = false;
defaults.include_reward = true;
defaults.resample_to_larger_n = false;
defaults.model_type = 'lda';
defaults.gaze_condition = 'roi';
defaults.match_gaze_and_reward_units = true;

params = bfw.parsestruct( defaults, varargin );

shared_ids = bfw_lda.shared_unit_ids( gaze_counts.labels, rwd_counts.labels );

base_gaze_mask = get_gaze_mask( gaze_counts.labels, params.gaze_mask_func, shared_ids );
base_rwd_mask = get_rwd_mask( rwd_counts.labels, params.rwd_mask_func, shared_ids );

cs = get_shared_combs( gaze_counts.labels, rwd_counts.labels ...
  , base_gaze_mask, base_rwd_mask, params.each );

gaze_spikes = get_gaze_spikes( gaze_counts, params );
rwd_spikes = get_rwd_spikes( rwd_counts, params );

num_combs = size( cs, 2 );

perf = cell( num_combs, 1 );
labels = cell( size(perf) );

ps = cell( size(perf) );
p_labels = cell( size(perf) );

for i = 1:num_combs
  fprintf( '\n  ' );
  shared_utils.general.progress( i, num_combs );
  
  comb_uuid = sprintf( 'comb-%s', shared_utils.general.uuid() );
  
  gaze_mask_func = @(l, m) find(l, cs(:, i), intersect(m, base_gaze_mask));
  rwd_mask_func = @(l, m) find(l, cs(:, i), intersect(m, base_rwd_mask));
  
  col_cat = { 'unit_uuid' };
  
  gaze_lda_outs = run_gaze( gaze_spikes, gaze_counts.labels, col_cat ...
    , gaze_mask_func, false, params );
  
  if ( params.include_reward )
    rwd_lda_outs = run_rwd( rwd_spikes, rwd_counts.labels, col_cat ...
      , rwd_mask_func, false, params );
  end
  
  if ( params.permutation_test )
    null_gaze_outs = run_gaze( gaze_spikes, gaze_counts.labels, col_cat ...
      , gaze_mask_func, true, params );
    
    if ( params.include_reward )
      null_rwd_outs = run_rwd( rwd_spikes, rwd_counts.labels, col_cat ...
        , rwd_mask_func, true, params );
    end
  end

  if ( params.include_reward )
    to_join = make_joined_labels( gaze_lda_outs.labels', rwd_lda_outs.labels' );
    tmp_perf = [ gaze_lda_outs.performance, rwd_lda_outs.performance ];
  else
    to_join = gaze_lda_outs.labels';
    tmp_perf = gaze_lda_outs.performance;
  end
  
  maybe_addsetcat( to_join, 'data-type', 'real' );
  maybe_addsetcat( to_join, 'comb-uuid', comb_uuid );
  tmp_labels = to_join';
  
  if ( params.permutation_test )
    if ( params.include_reward )
      null_to_join = ...
        make_joined_labels( null_gaze_outs.labels', null_rwd_outs.labels' );
      tmp_perf = [ tmp_perf; [null_gaze_outs.performance, null_rwd_outs.performance] ];
    else
      null_to_join = null_gaze_outs.labels';
      tmp_perf = [ tmp_perf; null_gaze_outs.performance ];
    end
    
    maybe_addsetcat( null_to_join, 'data-type', 'null' );
    maybe_addsetcat( null_to_join, 'comb-uuid', comb_uuid );
    append( tmp_labels, null_to_join );
    
    combined_labels = one( append(to_join', null_to_join) );
    combined_p_gaze = null_p_value( gaze_lda_outs.performance, null_gaze_outs.performance );
    
    if ( params.include_reward )
      combined_p_rwd = null_p_value( rwd_lda_outs.performance, null_rwd_outs.performance );
    else
      combined_p_rwd = nan;
    end
    
    ps{i} = [combined_p_gaze, combined_p_rwd];
    p_labels{i} = combined_labels;
  end
  
  perf{i} = tmp_perf;
  labels{i} = tmp_labels;
end

outs = struct();
outs.performance = vertcat( perf{:} );
outs.labels = vertcat( fcat, labels{:} );
outs.ps = vertcat( ps{:} );
outs.p_labels = vertcat( fcat, p_labels{~cellfun('isempty', p_labels)} );

end

function p = null_p_value(perf, null_perf)

if ( isempty(perf) )
  p = [];
else
  p = 1 - pnz( mean(perf) > null_perf );
end

end

function lda_outs = run_rwd(rwd_spikes, rwd_labels, col_cat, mask_func, shuffle, params)

lda_outs = ...
  bfw_lda.fitcdiscr_matrix( rwd_spikes, rwd_labels, col_cat, 'reward-level' ...
  , 'shuffle', shuffle ...
  , 'iters', params.iters ...
  , 'mask_func', mask_func ...
  , 'resample_to_larger_n', params.resample_to_larger_n ...
  , 'model_type', params.model_type ...
);

end

function lda_outs = ...
  run_gaze(gaze_spikes, gaze_labels, col_cat, mask_func, shuffle, params)

lda_outs = ...
  bfw_lda.fitcdiscr_matrix( gaze_spikes, gaze_labels, col_cat, params.gaze_condition ...
  , 'shuffle', shuffle ...
  , 'iters', params.iters ...
  , 'mask_func', mask_func ...
  , 'resample_to_larger_n', params.resample_to_larger_n ...
  , 'model_type', params.model_type ...
);

end

function to_join = make_joined_labels(gaze_labs, rwd_labs)

to_join = one( gaze_labs' );
one( rwd_labs );
join( to_join, rwd_labs );
repmat( to_join, rows(gaze_labs) );

end

function mask = get_gaze_mask(labels, func, shared_ids)

mask = func( labels, find_combs(labels, shared_ids) );

end

function mask = get_rwd_mask(labels, func, shared_ids)

mask = func( labels, fcat.mask(labels, find_combs(labels, shared_ids) ...
  , @find, 'no-error' ...
  , @findnone, 'reward-NaN' ...
));

end

function cs = get_shared_combs(a, b, mask_a, mask_b, cats)

combs_a = combs( a, cats, mask_a );
combs_b = combs( b, cats, mask_b );

rows_a = unique( categorical(combs_a'), 'rows' );
rows_b = unique( categorical(combs_b'), 'rows' );

cs = cellstr( intersect(rows_a, rows_b, 'rows') )';

end

function ind = find_combs(labels, ids)

inds = cell( size(ids, 2), 1 );

for i = 1:size(ids, 2)
  ind = find( labels, ids(:, i) );
  assert( ~isempty(ind) );
  inds{i} = ind;
end

ind = vertcat( inds{:} );

end

function spikes = get_rwd_spikes(rwd_counts, params)

t = params.rwd_t_win;
spikes = ...
  nanmean( rwd_counts.psth(:, mask_gele(rwd_counts.t, t(1), t(2))), 2 );

end

function spikes = get_gaze_spikes(gaze_counts, params)

t = params.gaze_t_win;
spikes = ...
  nanmean( gaze_counts.spikes(:, mask_gele(gaze_counts.t, t(1), t(2))), 2 );

end
