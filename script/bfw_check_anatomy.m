xls_p = 'D:\data\bfw\public\coordinates';
xls_file = shared_utils.io.find( xls_p, '.xlsx' );
assert( numel(xls_file) == 1 );
[~, ~, raw] = xlsread( xls_file{1} );
xls_out = bfw_parse_anatomy_excel_file( raw );

%%

spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes', 'include_unit_index', true );

%%

to_keep = find( xls_out.non_nan );
coords = xls_out.coords(to_keep, :);
xls_labs = fcat.from( xls_out.labels(to_keep, :), xls_out.categories );

%%  pca using first level anova cells

match_cats = { 'unit_uuid', 'channel', 'unit_rating' };

anova_labels = bfw_ct.load_significant_social_cell_labels_from_anova( [], true );
bfw.add_monk_labels( anova_labels );
anova_cell_info = anova_labels(:, match_cats);
anova_ids = fcat.strjoin( anova_cell_info' )';

xls_ids = fcat.strjoin( xls_labs(:, match_cats)' )';
[exists_in_anova, loc_in_anova_ids] = ismember( xls_ids, anova_ids );
% [exists_in_xls, loc_in_xls] = ismember( anova_ids, xls_ids );
% anova_ids(~exists_in_xls, :)

match_coords = nan( rows(anova_labels), 3 );
match_coords(loc_in_anova_ids(exists_in_anova), :) = coords(exists_in_anova, :);

[~, score] = pca( match_coords );
pc1 = score(:, 1);
social_rs_outs = dsp3.ranksum( pc1, anova_labels, {'region', 'id_m1'}, 'significant', 'not_significant' );

%%  pca using eyes v obj anova cells

roi_anova_labels = bfw_ct.load_significant_roi_cell_labels_from_anova( [], true );
bfw.add_monk_labels( roi_anova_labels );

anova_cell_info = roi_anova_labels (:, match_cats);
anova_ids = fcat.strjoin( anova_cell_info' )';

xls_ids = fcat.strjoin( xls_labs(:, match_cats)' )';
[exists_in_anova, loc_in_anova_ids] = ismember( xls_ids, anova_ids );

match_coords = nan( rows(roi_anova_labels ), 3 );
match_coords(loc_in_anova_ids(exists_in_anova), :) = coords(exists_in_anova, :);

[~, score] = pca( match_coords );
pc1 = score(:, 1);
roi_rs_outs = dsp3.ranksum( pc1, roi_anova_labels, {'region', 'id_m1'}, 'significant', 'not_significant' );

%%  test for term

model_term_file = fullfile( 'D:\data\bfw\public', 'BigTable_Stepwise_term.mat' );
model_term_info = shared_utils.io.fload( model_term_file );
best_term_col = model_term_info(:, 5);
best_term_col = cellfun( @(x) conditional(@() isempty(x), 'NaN', @() x{1}) ...
  , best_term_col, 'un', 0 );
term_unit_ids = cellfun( @(x) conditional(@() ischar(x), sprintf('unit_uuid__%s', x) ...
  , @() sprintf('unit_uuid__%d', x)), model_term_info(:, 1), 'un', 0 );
term_unit_ids = [ term_unit_ids, model_term_info(:, 2) ];

term_labels = fcat.from( [term_unit_ids, best_term_col], {'unit_uuid', 'region', 'model-factor'} );
replace( term_labels, 'accg', 'acc' );
add_sessions_from_unit_ids( spikes.labels', term_labels );
bfw.add_monk_labels( term_labels );

xls_ids = fcat.strjoin( xls_labs(:, {'unit_uuid'})' )';
[exists_in_term_list, loc_in_term_list] = ismember( xls_ids, term_unit_ids );

match_coords = nan( rows(term_unit_ids ), 3 );
match_coords(loc_in_term_list(exists_in_term_list), :) = coords(exists_in_term_list, :);

[~, score] = pca( match_coords );
pc1 = score(:, 1);
term_anova_outs = dsp3.anova1( pc1, term_labels, {'region', 'id_m1'}, 'model-factor' );

%%  interactive cell type

inter_cell_labels = shared_utils.io.fload( fullfile('D:\data\bfw\public' ...
  , 'interactive_significant_labels.mat') ...
);
bfw.add_monk_labels( inter_cell_labels );

inter_unit_ids = inter_cell_labels(:, 'unit_uuid');
inter_unit_ids = cellfun( @(x) strrep(x, 'uuid__', 'unit_uuid__'), inter_unit_ids, 'un', 0 );
setcat( inter_cell_labels, 'unit_uuid', inter_unit_ids );

keep( inter_cell_labels, find(inter_cell_labels, 'early') );
inter_unit_ids = cellstr( inter_cell_labels, {'unit_uuid'} );

xls_ids = fcat.strjoin( xls_labs(:, {'unit_uuid'})' )';
[exists_in_inter_list, loc_in_inter_list] = ismember( xls_ids, inter_unit_ids );

match_coords = nan( rows(inter_unit_ids), 3 );
match_coords(loc_in_inter_list(exists_in_inter_list), :) = coords(exists_in_inter_list, :);

[~, score] = pca( match_coords );
pc1 = score(:, 1);
inter_anova_outs = dsp3.anova1( pc1, inter_cell_labels, {'region', 'id_m1'}, 'significant_for' );

%%  fdr correct p values

cats = { 'region', 'id_m1' };

soc_ps = cellfun( @(x) x.p, social_rs_outs.rs_tables );
soc_ls = cellstr( social_rs_outs.rs_labels, cats );
soc_inds = ones( size(soc_ps) );
soc_tbls = social_rs_outs.rs_tables;

roi_ps = cellfun( @(x) x.p, roi_rs_outs.rs_tables );
roi_ls = cellstr( roi_rs_outs.rs_labels, cats );
roi_inds = repmat( 2, size(roi_ps) );
roi_tbls = roi_rs_outs.rs_tables;

term_ps = cellfun( @(x) x.Prob_F{1}, term_anova_outs.anova_tables );
term_ls = cellstr( term_anova_outs.anova_labels, cats );
term_inds = repmat( 3, size(term_ps) );
term_tbls = term_anova_outs.anova_tables;

inter_ps = cellfun( @(x) x.Prob_F{1}, inter_anova_outs.anova_tables );
inter_ls = cellstr( inter_anova_outs.anova_labels, cats );
inter_inds = repmat( 4, size(inter_ps) );
inter_tbls = inter_anova_outs.anova_tables;

all_ps = [ soc_ps; roi_ps; term_ps; inter_ps ];
cts = cumsum( [numel(soc_ps); numel(roi_ps); numel(term_ps); numel(inter_ps)] );
all_ls = [ soc_ls; roi_ls; term_ls; inter_ls ];
all_inds = [ soc_inds; roi_inds; term_inds; inter_inds ];
all_tbls = [ soc_tbls; roi_tbls; term_tbls; inter_tbls ];
p_labels = fcat.from( all_ls, cats );
cts = cts - cts(1);

assert_ispair( all_ls, p_labels );

fdr_each = { 'id_m1' };
fdr_I = findall( p_labels, 'id_m1' );
fdr_p = nan( size(all_ps) );

for i = 1:numel(fdr_I)
  fdr_p(fdr_I{i}) = dsp3.fdr( all_ps(fdr_I{i}) );
end

% ps = dsp3.fdr( all_ps );

% sig_ps = find( ps < 0.05 );
% inds = arrayfun( @(x) find(x >= cts, 1, 'last'), sig_ps );
% offs = arrayfun( @(x, y) y - cts(x), inds, sig_ps );
