id_matrix = bfw_load_cell_id_matrix();

xls_uuids = cellfun( @(x) sprintf('unit_uuid__%s', x) ...
  , id_matrix.info(:, ismember(id_matrix.header, 'new_uuid')), 'un', 0 );

xls_dims = { 'ml', 'ap', 'z' }; % no ml, ap -> model term bla kuro, z -> model term bla, dmpfc

xls_coords = cell2mat( ...
  id_matrix.info(:, ismember(id_matrix.header, xls_dims)) );

%%  load anova ids

soc_anova_ids = bfw_ct.load_significant_social_cell_labels_from_anova( [], true );
bfw.add_monk_labels( soc_anova_ids );

roi_anova_ids = bfw_ct.load_significant_roi_cell_labels_from_anova( [], true );
bfw.add_monk_labels( roi_anova_ids );

%% 

analysis_cat = 'pca_type';
keep_categories = { 'region', 'session', 'id_m1', analysis_cat };

coord_index = 3;
pca_func = @(coords) deal(coords(:, coord_index), nan);
% pca_func = @pca_pc1

%%  pca social anova

soc_anova_coords = make_coordinates( xls_uuids, xls_coords, soc_anova_ids(:, 'unit_uuid') );
[soc_ps, soc_labs, soc_I, soc_outs] = pca_sig_test_each( ...
  pca_func, soc_anova_coords, soc_anova_ids, {'id_m1', 'region'}, 'significant', 'not_significant' );
addsetcat( soc_labs, analysis_cat, 'social_anova' );
  
%%  pca roi anova

roi_anova_coords = make_coordinates( xls_uuids, xls_coords, roi_anova_ids(:, 'unit_uuid') );
[roi_ps, roi_labs, roi_I, roi_outs] = pca_sig_test_each( ...
  pca_func, roi_anova_coords, roi_anova_ids, {'id_m1', 'region'}, 'significant', 'not_significant' );
addsetcat( roi_labs, analysis_cat, 'roi_anova' );

%%  pca interactive

inter_cell_labels = shared_utils.io.fload( fullfile('D:\data\bfw\public' ...
  , 'interactive_significant_labels.mat') ...
);
bfw.add_monk_labels( inter_cell_labels );
replace( inter_cell_labels, 'accg', 'acc' );

early_ind = find( inter_cell_labels, 'early' );
inter_cell_labels = prune( inter_cell_labels(early_ind) );
replace( inter_cell_labels, {'both_sig', 'm1_only_sig', 'm2_only_sig'}, 'interactive_sig' );

uuids = combs( inter_cell_labels, 'unit_uuid' );
for i = 1:numel(uuids)
  replace( inter_cell_labels, uuids{i}, strrep(uuids{i}, 'uuid__', 'unit_uuid__') );
end

inter_coords = make_coordinates( xls_uuids, xls_coords, inter_cell_labels(:, 'unit_uuid') );
[inter_ps, inter_labs, ~, inter_outs] = pca_sig_test_each( ...
  pca_func, inter_coords, inter_cell_labels, {'id_m1', 'region'}, 'interactive_sig', 'none_sig' );
addsetcat( inter_labs , analysis_cat, 'interactive' );

%%  test for term

model_term_file = fullfile( 'D:\data\bfw\public', 'Updated_BigTable_Stepwise_term.mat' );
model_term_info = shared_utils.io.fload( model_term_file );
best_term_col = model_term_info(:, 5);
best_term_col = cellfun( @(x) conditional(@() isempty(x), 'NaN', @() x{1}) ...
  , best_term_col, 'un', 0 );
best_term_col(strcmp(best_term_col, 'x1') | ...
              strcmp(best_term_col, 'x2') | ...
              strcmp(best_term_col, 'x3')) = {'significant_term'};

best_term_labels = cellfun( @(x) sprintf('best_term__%s', x), best_term_col, 'un', 0 );

term_unit_ids = cellfun( @(x) conditional(@() ischar(x), sprintf('unit_uuid__%s', x) ...
  , @() sprintf('unit_uuid__%d', x)), model_term_info(:, 1), 'un', 0 );

[~, xls_ind] = ismember( term_unit_ids(:, 1), xls_uuids );
term_sessions = id_matrix.info(xls_ind, ismember(id_matrix.header, 'session'));

term_unit_ids = [ term_unit_ids, model_term_info(:, 2), term_sessions, best_term_labels ];

term_coords = make_coordinates( xls_uuids, xls_coords, term_unit_ids(:, 1) );
term_cell_labels = fcat.from( term_unit_ids, {'unit_uuid', 'region', 'session', 'best_term'} );
replace( term_cell_labels, 'accg', 'acc' );
bfw.add_monk_labels( term_cell_labels );

[term_ps, term_labs, ~, term_outs] = pca_sig_test_each( ...
  pca_func, term_coords, term_cell_labels, {'id_m1', 'region'}, 'best_term__significant_term', 'best_term__NaN' );
addsetcat( term_labs, analysis_cat, 'model-term' );

%%  

test_label_sets = { soc_anova_ids, roi_anova_ids, inter_cell_labels, term_cell_labels };
social_cell_ids = soc_anova_ids(:, 'unit_uuid');
sig_label = { 'significant', 'significant', 'interactive_sig', 'best_term__significant_term' };

uuids = unique( cat_expanded(1, cellfun(@(x) x(:, 'unit_uuid'), test_label_sets, 'un', 0)) );
uuids = uuids(:);
combined_coords = nan( numel(uuids), 3 );

regions = cell( numel(uuids), 1 );
id_m1s = cell( size(regions) );
is_sig_labels = cell( size(regions) );
uuid_is_sig = false( numel(uuids), 1 );

for i = 1:numel(uuids)
  is_sig = false;
  for j = 1:numel(test_label_sets)
    cell_ind = find( test_label_sets{j}, uuids{i} );
    if ( ~isempty(cell_ind) )
      regions(i) = cellstr( test_label_sets{j}, 'region', cell_ind );
      id_m1s(i) = cellstr( test_label_sets{j}, 'id_m1', cell_ind );
      assert( numel(cell_ind) == 1 );
      if ( count(test_label_sets{j}, sig_label{j}, cell_ind) > 0 )
        is_sig = true;
        break
      end
    end
  end
  
  if ( is_sig )
    is_sig_labels{i} = 'sig';
  else
    is_sig_labels{i} = 'ns';
  end
  
  uuid_is_sig(i) = is_sig;
  uuid_ind = strcmp( xls_uuids, uuids{i} );
  combined_coords(i, :) = xls_coords(uuid_ind, :);
end

combined_labels = fcat.from( [uuids, regions, id_m1s, is_sig_labels] ...
  , {'unit_uuid', 'region', 'id_m1', 'significant'} );

[region_I, region_C] = findall( combined_labels, 'region' ...
  , find(combined_labels, social_cell_ids) );
region_ps = bfw.row_nanmean( double(uuid_is_sig), region_I );

[combined_ps, combined_labs, ~, combined_outs] = ...
  pca_sig_test_each( ...
    @pca_pc1, combined_coords, combined_labels, {'region', 'id_m1'}, 'sig', 'ns' );

fdr_I = findall( combined_labs, {'region', 'id_m1'} );
fdr_ps = combined_ps;
for i = 1:numel(fdr_I)
  fdr_ps(fdr_I{i}) = dsp3.fdr( combined_ps(fdr_I{i}) );
end

combined_labs(find(fdr_ps < 0.05))

pca_coeffs = vertcat( cat_expanded(1, cellfun(@(x) x(:)', combined_outs.pc1_coeffs, 'un', 0)) );
addsetcat( combined_labs, analysis_cat, 'combined' );

linearized_pca_coeffs = [];
linearized_pca_coeff_labels = fcat();

for j = 1:size(pca_coeffs, 1)
  coeffs = pca_coeffs(j, :);  
  f = addcat( combined_labs(j), 'dimension' );
  for k = 1:numel(coeffs)
    linearized_pca_coeffs(end+1, 1) = coeffs(k);
    append( linearized_pca_coeff_labels, f );
    addsetcat( ...
      linearized_pca_coeff_labels, 'dimension', xls_dims{k}, rows(linearized_pca_coeff_labels) );
  end
end

%%  combine

all_ps = { soc_ps, roi_ps, inter_ps, term_ps };
all_ls = { soc_labs, roi_labs, inter_labs, term_labs };
all_coeffs = { soc_outs.pc1_coeffs, roi_outs.pc1_coeffs, inter_outs.pc1_coeffs, term_outs.pc1_coeffs };

ps = vertcat( all_ps{:} );
p_labels = fcat();
addcat( p_labels, 'dimension' );

pca_coeffs = [];
pca_coeff_labels = fcat();

linearized_pca_coeffs = [];
linearized_pca_coeff_labels = fcat();

expect3 = false;

for i = 1:numel(all_ls)
  f = fcat.from( all_ls{i}(:, keep_categories), keep_categories );
  assert_ispair( all_ps{i}, f );
  append( p_labels, addcat(f, 'dimension') );
  
  if ( expect3 )
    for j = 1:numel(all_coeffs{i})
      coeffs = all_coeffs{i}{j};
      assert( numel(xls_dims) == numel(coeffs) );
      append( pca_coeff_labels, f, j );
      pca_coeffs(end+1, :) = coeffs(:)';

      for k = 1:numel(coeffs)
        linearized_pca_coeffs(end+1, 1) = coeffs(k);
        append( linearized_pca_coeff_labels, f, j );
        addsetcat( ...
          linearized_pca_coeff_labels, 'dimension', xls_dims{k}, rows(linearized_pca_coeff_labels) );
      end
    end
  end
end

assert_ispair( linearized_pca_coeffs, linearized_pca_coeff_labels );
assert_ispair( pca_coeffs, pca_coeff_labels );

fdr_I = findall( p_labels, {'region', 'id_m1'} );
fdr_ps = ps;
for i = 1:numel(fdr_I)
  fdr_ps(fdr_I{i}) = dsp3.fdr( ps(fdr_I{i}) );
end

p_labels(find(fdr_ps < 0.05))

%%  scatter3

pcats = { 'region' };
gcats = { analysis_cat };

% plt_labs = pca_coeff_labels';
% plt_coeffs = pca_coeffs;

% plt_labs = combined_labs';
% plt_coeffs = pca_coeffs;

plt_labs = combined_labels';
plt_coeffs = combined_coords;
gcats = { 'significant' };

assert_ispair( plt_coeffs, plt_labs );

[p_I, p_C] = findall( plt_labs, pcats );
sub_shape = plotlabeled.get_subplot_shape( numel(p_I) );

offset_stp = 0.1;

for i = 1:numel(p_I)
  pind = p_I{i};
  ax = subplot( sub_shape(1), sub_shape(2), i );
  cla( ax );
  hold( ax, 'on' );
  
  [g_I, g_C] = findall( plt_labs, gcats, pind );
  colors = hsv( numel(g_I) );
  
  for j = 1:numel(g_I)
    gind = g_I{j};
    coeffs = abs( plt_coeffs(gind, :) + offset_stp * (j-1) );
    h = scatter3( ax, coeffs(:, 1), coeffs(:, 2), coeffs(:, 3) );
    set( h, 'MarkerFaceColor', colors(j, :) );
    set( h, 'MarkerEdgeColor', colors(j, :) );
  end
  
  view( ax, 3 );
  title( ax, strrep(fcat.strjoin(p_C(:, i)), '_', ' ') );
%   xlim( ax, [0, 1] );
  xlabel( ax, 'ml' );
%   ylim( ax, [0, 1] );
  ylabel( ax, 'ap' );
%   zlim( ax, [0, 1] );
  zlabel( ax, 'z' );
end

%%

xcats = { 'id_m1', analysis_cat };
gcats = { 'dimension' };
pcats = { 'region' };

pl = plotlabeled.make_common();

axs = pl.bar( abs(linearized_pca_coeffs), linearized_pca_coeff_labels ...
  , xcats, gcats, pcats ...
);

%%

function [ps, labs, each_I, outs] = pca_sig_test_each(pca_func, coords, labels, each, label_a, label_b)

assert_ispair( coords, labels );
assert( all(haslab(labels, [cellstr(label_a), cellstr(label_b)])) );

[labs, each_I] = keepeach( labels', each );
ps = nan( size(each_I) );
pc1_coeffs = cell( size(each_I) );

for i = 1:numel(each_I)
  ri = each_I{i};
%   [pc1, pc1_coeff] = pca_pc1( coords(ri, :) );
  [pc1, pc1_coeff] = pca_func( coords(ri, :) );  
  pc1_coeffs{i} = pc1_coeff;
  
  pc1_labs = prune( labels(ri) );
  ps(i) = pc1_sig_test( pc1 ...
    , find(pc1_labs, label_a) ...
    , find(pc1_labs, label_b) ...
  );
end

outs = struct();
outs.pc1_coeffs = pc1_coeffs;

end

function [pc1, pc1_coeffs] = pca_pc1(coords)

[coeff, score, ~, t2] = pca( coords );
pc1 = score(:, 1);
pc1_coeffs = coeff(:, 1);

end

function p = pc1_sig_test(pc1, ind_a, ind_b)

sig = pc1(ind_a);
ns = pc1(ind_b);
p = ranksum( sig, ns );

end

function coords = make_coordinates(xls_ids, xls_coords, target_ids)

assert( numel(xls_ids) == size(xls_coords, 1) );

coords = nan( numel(target_ids), 3 );
[~, to_dst_ind] = ismember( target_ids, xls_ids );
assert( sum(to_dst_ind == 0) == 0 );
coords(:, :) = xls_coords(to_dst_ind, :);

end

