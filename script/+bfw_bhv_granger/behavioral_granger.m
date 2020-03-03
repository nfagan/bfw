function outs = behavioral_granger(look_outputs, varargin)

defaults = struct();
defaults.bin_size = 5e3;
defaults.step_size = 1e3;
defaults.alpha = 0.05;
defaults.max_lag = 50;
defaults.gauss_win_size = 100;
defaults.mask_func = @(labels, mask) mask;
defaults.permutation_test = false;
defaults.permutation_test_iters = 1e2;

params = bfw.parsestruct( defaults, varargin );

labels = look_outputs.labels';
look_vectors = look_outputs.look_vectors;

mask = get_base_mask( labels, params.mask_func );
each_I = findall( labels, 'unified_filename', mask );

bin_size = params.bin_size;
step_size = params.step_size;
alpha = params.alpha;
max_lag = params.max_lag;
permutation_test = params.permutation_test;
perm_iters = params.permutation_test_iters;

win = gausswin( params.gauss_win_size );
granger_fs = cell( numel(each_I), 1 );
granger_cvs = cell( size(granger_fs) );
granger_labels = cell( size(granger_fs) );
null_fs = cell( size(granger_fs) );
null_cvs = cell( size(granger_fs) );

has_m1_m2 = true( size(granger_fs) );

sums = cell( numel(each_I), 1 );
sum_labels = cell( size(sums) );

smoothed_traces = cell( size(sums) );

num_cols = rowzeros( rows(sums) );

%%

parfor i = 1:numel(each_I)  
  shared_utils.general.progress( i, numel(each_I) );
  
  prev_state = warning( 'off', 'all' );
  restore_warn = onCleanup( @() restore_warning_state(prev_state) );
  
  m1_ind = find( labels, 'm1', each_I{i} );
  m2_ind = find( labels, 'm2', each_I{i} );
  
  if ( isempty(m1_ind) || isempty(m2_ind) )
    has_m1_m2(i) = false;
    
  else
    look_m1 = look_vectors{m1_ind};
    look_m2 = look_vectors{m2_ind};

    bin_inds = shared_utils.vector.slidebin( 1:numel(look_m1), bin_size, step_size );
    
    granger_f = nan( 2, numel(bin_inds) );
    granger_cv = nan( size(granger_f) );
    
    null_f = cell( size(granger_f) );
    null_cv = cell( size(granger_f) );
    
    tmp_smooth_traces = cell( 2, numel(bin_inds) );

    for j = 1:numel(bin_inds)
      smooth_m1 = filter( win, 1, look_m1(bin_inds{j}) );
      smooth_m2 = filter( win, 1, look_m2(bin_inds{j}) );
      
      if ( nnz(smooth_m1) > 0 && nnz(smooth_m2) > 0 )
        [real_fs, real_cvs] = granger_both_directions( smooth_m1, smooth_m2, alpha, max_lag );

        granger_f(:, j) = real_fs;
        granger_cv(:, j) = real_cvs;

        if ( permutation_test )
          [null_f(:, j), null_cv(:, j)] = ...
            run_permutation_test( smooth_m1, smooth_m2, alpha, max_lag, perm_iters );
        end
      end
      
      tmp_smooth_traces{1, j} = smooth_m1;
      tmp_smooth_traces{2, j} = smooth_m2;
    end  
    
    g_labs = make_granger_labels( labels, each_I{i} );

    granger_fs{i} = granger_f;
    granger_cvs{i} = granger_cv;
    granger_labels{i} = g_labs;
    null_fs{i} = null_f;
    null_cvs{i} = null_cv;
    
    m1_sum = cellfun( @(x) sum(look_m1(x)), bin_inds );
    m2_sum = cellfun( @(x) sum(look_m2(x)), bin_inds );    
    
    sums{i} = [ m1_sum(:)'; m2_sum(:)' ];
    sum_labels{i} = g_labs';
    smoothed_traces{i} = tmp_smooth_traces;
    
    num_cols(i) = numel( bin_inds );
  end
end

%%

non_empty = has_m1_m2;
nc = max( num_cols(non_empty) );
nc_smooth = max( cellfun(@(x) size(x, 2), smoothed_traces) );

smoothed_traces = vertcat_expanded( pad_columns_cell(smoothed_traces(non_empty), nc_smooth) );

sums = vertcat_expanded( pad_columns_numeric(sums(non_empty), nc) );

granger_fs = vertcat_expanded( pad_columns_numeric(granger_fs(non_empty), nc) );
granger_cvs = vertcat_expanded( pad_columns_numeric(granger_cvs(non_empty), nc) );

null_fs = vertcat_expanded( pad_columns_cell(null_fs(non_empty), nc) );
null_cvs = vertcat_expanded( pad_columns_cell(null_cvs(non_empty), nc) );

sum_labels = sum_labels(non_empty);
sum_labels = vertcat( fcat, sum_labels{:} );

granger_labels = granger_labels(non_empty);
granger_labels = vertcat( fcat, granger_labels{:} );

assert_ispair( granger_fs, granger_labels );
assert_ispair( granger_cvs, granger_labels );
assert_ispair( sums, sum_labels );

outs = struct();
outs.granger_fs = granger_fs;
outs.granver_cvs = granger_cvs;
outs.null_fs = null_fs;
outs.null_cvs = null_cvs;
outs.granger_labels = granger_labels;
outs.smoothed_traces = smoothed_traces;
outs.sums = sums;
outs.sum_labels = sum_labels;
outs.params = params;

end

function [fs, cvs] = granger_both_directions(m1, m2, alpha, max_lag)

fs = nan( 2, 1 );
cvs = nan( 2, 1 );

[fs(1), cvs(1)] = granger_cause( m1, m2, alpha, max_lag );
% reverse direction
[fs(2), cvs(2)] = granger_cause( m2, m1, alpha, max_lag );

end

function [fs, cvs] = run_permutation_test(m1, m2, alpha, max_lag, iters)

one_fs = nan( iters, 1 );
one_cvs = nan( iters, 1 );

fs = { one_fs; one_fs };
cvs = { one_cvs; one_cvs };

for i = 1:iters
  shuff_m1 = circ_permute_vector( m1 );
  shuff_m2 = circ_permute_vector( m2 );
  
  [tmp_fs, tmp_cvs] = granger_both_directions( shuff_m1, shuff_m2, alpha, max_lag );
  
  for j = 1:2
    fs{j}(i) = tmp_fs(j);
    cvs{j}(i) = tmp_cvs(j);
  end
end

end

function o = circ_permute_vector(a)

na = numel( a );
begin = randi( na, 1 );

first = a(begin:end);
rest = a(1:begin-1);

o = [ first(:)', rest(:)' ];

if ( iscolumn(a) )
  o = o(:);
end

end

function restore_warning_state(prev_state)
warning( prev_state );
end

function mask = get_base_mask(labels, mask_func)
mask = mask_func( labels, rowmask(labels) );
end

function o = vertcat_expanded(a)
o = vertcat( a{:} );
end

function o = pad_columns_cell(a, s)

o = cell( size(a) );

for i = 1:numel(a)
  tmp = a{i};
  num_pad = s - size( tmp, 2 );
  pad_with = cell( rows(tmp), num_pad );
  o{i} = [ tmp, pad_with ];
end

end

function o = pad_columns_numeric(a, s)

o = cell( size(a) );

for i = 1:numel(a)
  tmp = a{i};
  num_pad = s - size( tmp, 2 );
  pad_spec = [ 0, num_pad ];
  o{i} = padarray( tmp, pad_spec, nan, 'post' );
end

end

function labs = make_sum_labels(labels, index)

labs = append1( fcat(), labels, index, 2 );
setcat( labs, 'looks_by', {'m1', 'm2'} );

end

function labs = make_granger_labels(labels, index)

labs = append1( fcat(), labels, index, 2 );
directions = { 'm1->m2', 'm2->m1' };
addsetcat( labs, 'direction', directions );

end