function [spike_dat, spike_labels, t] = transform_cc_spike_sets(spike_sets, region_labels)

% 0.4 - 0.2, 0.2 - 0, 0-0.2, 0.2-0.4
% First sig point after first bin edge, 5 significant bins
%   fdr correct for 3 relevant roi-contrasts

spike_sets = filter_sets( spike_sets );
[n_cols, t] = validate_sets( spike_sets, region_labels );

n_func = @(y) sum( cellfun(@(x) size(x, 1), y) );
total_rows = sum( cellfun(@(x) n_func(x.setCNT{1}) + n_func(x.setCNT{2}), spike_sets) );

spike_dat = zeros( total_rows, n_cols );

stp = 1;

spike_labels = fcat();

for i = 1:numel(spike_sets)
  set = spike_sets{i};
  counts = set.setCNT;
  labels = set.LA;
  
  for j = 1:numel(counts)
    roi_lab = labels{j};
    
    if ( count(spike_labels, roi_lab) ~= 0 )
      continue;
    end
    
    per_unit_counts = vertcat( counts{j}{:} );
    per_unit_n_counts = cellfun( @(x) size(x, 1), counts{j} );
    per_unit_labs = fcat.create( 'roi', roi_lab, 'unit_uuid', bfw.nan_unit_uuid(), 'region', '<region>' );
    
    n_counts = size( per_unit_counts, 1 );
    spike_dat(stp:stp+n_counts-1, :) = per_unit_counts;
    
    stp = stp + n_counts;
    
    for k = 1:numel(per_unit_n_counts)
      setcat( per_unit_labs, 'unit_uuid', sprintf('unit_uuid-%d', k) );
      setcat( per_unit_labs, 'region', region_labels{k} );
      append1( spike_labels, per_unit_labs, 1, per_unit_n_counts(k) );
    end
  end
end

spike_dat = spike_dat(1:stp-1, :);

assert_ispair( spike_dat, spike_labels );

end

function sets = filter_sets(sets)

labels = cellfun( @(x) x.LA, sets, 'un', 0 );
is_fix_set = cellfun( @(x) any(cellfun(@(y) ~isempty(strfind(y, 'fix')), x)), labels );
sets = sets(~is_fix_set);

end

function [cols, t_series] = validate_sets(sets, region_labels)

assert( iscellstr(region_labels), 'Expected region labels to be a cell array of strings.' );

msg = 'Invalid spike set.';

min_t = -0.5;
max_t = 0.5;
bin_s = 0.01;
t_series = min_t:bin_s:max_t;
n_t = numel( t_series );

for i = 1:numel(sets)
  assert( isstruct(sets{i}), msg );
  assert( isfield(sets{i}, 'setCNT'), msg );
  assert( numel(sets{i}.setCNT) == 2, msg );
  assert( isequaln(size(sets{i}.setCNT{1}), size(sets{i}.setCNT{2})), msg );
  assert( iscell(sets{i}.setCNT{1}) && iscell(sets{i}.setCNT{2}), msg );
  
  if ( i == 1 )
    assert( ~isempty(sets{i}.setCNT{1}), msg );
    cols = size( sets{i}.setCNT{1}{1}, 2 );
    tot_n_units = numel( sets{i}.setCNT{1} );
    assert( cols == n_t, msg );
  end
  
  all_cols1 = unique( cellfun(@(x) size(x, 2), sets{i}.setCNT{1}) );
  all_cols2 = unique( cellfun(@(x) size(x, 2), sets{i}.setCNT{2}) );
  
  assert( numel(all_cols1) == 1 && all_cols1 == cols, msg );
  assert( numel(all_cols2) == 1 && all_cols2 == cols, msg );
  
  n_units = numel( sets{i}.setCNT{1} );
  assert( n_units == tot_n_units, msg );
  assert( n_units == numel(region_labels), msg );
end

end