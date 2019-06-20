function outs = null_matrix(data, labels, t, varargin)

assert_ispair( data, labels );
assert( numel(t) == size(data, 2), 'T does not match data.' );

defaults = bfw_pm.null_matrix_defaults();

params = bfw.parsestruct( defaults, varargin );

validate_contrasts( params.roi_contrasts, labels );
validate_bins( params.t_window_bins, t );

if ( ~isempty(params.seed) )
  rng( params.seed );
end

% First real
is_shuffled = false;
[real_mat, real_labs] = p_sig_units_for_all_contrasts( data, labels, t, is_shuffled, params );

% Then null
is_shuffled = true;

num_iters = params.iters;
null_mat = cell( num_iters, 1 );
null_labs = cell( size(null_mat) );
sig_counts = cell( size(null_mat) );

parfor i = 1:num_iters
  [curr_null_mat, curr_null_labs] = ...
    p_sig_units_for_all_contrasts( data, labels, t, is_shuffled, params );
  
  sig_counts{i} = double( real_mat > curr_null_mat );
  null_mat{i} = curr_null_mat;
  null_labs{i} = curr_null_labs;
end

sig_counts = sum_mult( sig_counts{:} );

outs = struct();
outs.params = params;
outs.real = real_mat;
outs.null = vertcat( null_mat{:} );
outs.real_labels = real_labs;
outs.null_labels = vertcat( fcat(), null_labs{:} );
outs.p_sig = 1 - sig_counts ./ num_iters;
outs.n_sig = sig_counts;

end

function a = sum_mult(varargin)

if ( nargin == 0 )
  a = [];
  return
end

a = varargin{1};

for i = 2:nargin
  a = a + varargin{i};
end

end

function [p_sig_units, sig_labels] = ...
  p_sig_units_for_all_contrasts(data, labels, t, is_shuffled, params)

roi_contrasts = params.roi_contrasts;

p_sig_units = [];
sig_labels = fcat();

test_each = { 'region' };
test_I = findall( labels, test_each );

for i = 1:numel(test_I)
  test_mask = test_I{i};
  
  for j = 1:numel(roi_contrasts)
    [curr_sig_units, curr_sig_labels] = ...
      p_sig_units_for_contrast( data, labels, t, test_mask, is_shuffled, roi_contrasts{j}, params );

    append( sig_labels, curr_sig_labels );
    p_sig_units = [ p_sig_units; curr_sig_units ];
  end
end

end

function [p_sig_units, sig_labels] = ...
  p_sig_units_for_contrast(data, labels, t, mask, is_shuffled, roi_contrast, params)

t_window_bins = params.t_window_bins;
alpha = params.alpha;
n_bin_threshold = params.n_bin_threshold;
require_consecutive_bins = params.require_consecutive_bins;

lab1 = roi_contrast{1};
lab2 = roi_contrast{2};

cell_inds = findall( labels, 'unit_uuid', mask );

num_cell_inds = numel(cell_inds);
num_bins = numel( t_window_bins );
num_t = numel( t );

is_sig_unit = false( num_cell_inds, num_bins );

subset_inds = cell( num_cell_inds, 1 );

for i = 1:num_cell_inds
  cell_ind = cell_inds{i};
  
  ind1 = find( labels, lab1, cell_ind );
  ind2 = find( labels, lab2, cell_ind );
  
  if ( is_shuffled )
    [ind1, ind2] = shuffle_inds( ind1, ind2 );
    t_ind1 = randperm(num_t);
    t_ind2 = randperm(num_t);
  else
    t_ind1 = 1:num_t;
    t_ind2 = 1:num_t;
  end
  
  ps = zeros( 1, num_t );
  
  for j = 1:num_t
    use_t1 = t_ind1(j);
    use_t2 = t_ind2(j);
    
    vec1 = data(ind1, use_t1);
    vec2 = data(ind2, use_t2);
    
    ps(j) = ranksum( vec1, vec2 );
  end
  
  sig_ps = ps < alpha;
  
  for k = 1:num_bins
    bin_start = t_window_bins{k}(1);
    bin_stop = t_window_bins{k}(2);
    
    in_bounds_t = t >= bin_start & t <= bin_stop;
    
    subset_ps = sig_ps(in_bounds_t);
    
    if ( require_consecutive_bins )
      [~, durs] = shared_utils.logical.find_all_starts( subset_ps );
      curr_is_sig = any( durs >= n_bin_threshold );
    else
      curr_is_sig = sum( subset_ps ) >= n_bin_threshold;
    end
    
    is_sig_unit(i, k) = curr_is_sig;
  end
  
  subset_inds{i} = union( ind1, ind2 );
end

p_sig_units = sum( is_sig_unit, 1 ) / num_cell_inds;

sig_labels = append1( fcat(), labels, vertcat(subset_inds{:}) );
roi_str = strjoin( sort(roi_contrast), '_' );
setcat( sig_labels, 'roi', roi_str );

end

function [ind1, ind2] = shuffle_inds(ind1, ind2)

num_ind1 = numel( ind1 );
num_ind2 = numel( ind2 );

num_inds = num_ind1 + num_ind2;

all_inds = [ ind1; ind2 ];
all_inds = all_inds(randperm(num_inds));

ind1 = all_inds(1:num_ind1);
ind2 = all_inds(num_ind1+1:end);

assert( numel(ind1) == num_ind1 );
assert( numel(ind2) == num_ind2 );

end

function validate_contrasts(contrasts, labels)

validateattributes( contrasts, {'cell'}, {}, mfilename, 'roi_contrasts' );

for i = 1:numel(contrasts)  
  validateattributes( contrasts{i}, {'cell'}, {'numel', 2}, mfilename, 'roi_contrasts' );
  assert( iscellstr(contrasts{i}), 'Roi contrasts must be cellstr.' );
  
  for j = 1:numel(contrasts{i})
    lab = contrasts{i}{j};
    
    if ( count(labels, lab) == 0 )
      error( 'Missing roi label: "%s".', lab );
    end
  end
end

end

function validate_bins(bins, t)

validateattributes( bins, {'cell'}, {}, mfilename, 't_window_bins' );

for i = 1:numel(bins)
  validateattributes( bins{i}, {'double'}, {'numel', 2}, mfilename, 'bin elements' );
  
  bin_start = bins{i}(1);
  bin_stop = bins{i}(2);

  t_start = find( t == bin_start );
  t_stop = find( t == bin_stop );

  assert( numel(t_start) == 1 && numel(t_stop) == 1 && t_stop > t_start, 'Invalid bin.' );
end

end