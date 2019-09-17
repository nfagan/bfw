function outs = anova_classification(gaze_outs)

labels = gaze_outs.labels';
handle_labels( labels );

mask = get_base_mask( labels );

anova_outs = anova_classify( gaze_outs.spikes, labels, mask );
summarize_performance( anova_outs );

end

function summarize_performance(anova_outs)

%%

is_sig = anova_outs.ps < 0.05;

roi_sig = is_sig(:, 1);
social_sig = is_sig(:, 2);
labels = anova_outs.labels';

summary_labels = fcat();

addcat( labels, 'main_effect' );
setcat( labels, 'main_effect', 'roi' );
append( summary_labels, labels );
setcat( labels, 'main_effect', 'social' );
append( summary_labels, labels );

is_sig = [ roi_sig; social_sig ];

pl = plotlabeled.make_common();
pl.summary_func = @mean;
pl.error_func = @(varargin) nan;

xcats = {};
gcats = { 'region' };
pcats = { 'main_effect' };

axs = pl.bar( double(is_sig), summary_labels, xcats, gcats, pcats );

end

function outs = anova_classify(spikes, labels, mask)

anova_each = { 'unit_uuid', 'session', 'region' };
anova_factors = { 'roi' };

[anova_labs, anova_I] = keepeach( labels', anova_each, mask );
social_group = make_social_group( labels, mask );

ps = cell( size(anova_I) );
stat_tables = cell( size(ps) );

parfor i = 1:numel(anova_I)
  anova_ind = anova_I{i}; 
  
  subset_spikes = spikes(anova_ind);
  
  groups = cellfun( @(x) categorical(labels, x, anova_ind), anova_factors, 'un', 0 );
  groups{end+1} = social_group(anova_ind);
  
  nesting = zeros( numel(anova_factors)+1 );
  roi_ind = find( strcmp(anova_factors, 'roi') );
  % Nest rois in social
  nesting(roi_ind, numel(groups)) = 1;
  
  [p, tbl, stats] = anovan( subset_spikes, groups ...
    , 'nested', nesting ...
    , 'varnames', [anova_factors, {'social'}] ...
    , 'display', 'off' ...
  );

  ps{i} = p(:)';
  stat_tables{i} = stats;
end

ps = vertcat( ps{:} );
stat_tables = vertcat( stat_tables{:} );

outs = struct();
outs.ps = ps;
outs.stat_tables = stat_tables;
outs.labels = anova_labs;

end

function social_group = make_social_group(labels, mask)

social_ind = findor( labels, social_rois(), mask );  
nonsocial_ind = findor( labels, nonsocial_rois(), mask );
social_group = categorical();
social_group(rowmask(labels), 1) = '<undefined>';
social_group(social_ind) = 'social';
social_group(nonsocial_ind) = 'nonsocial';

end

function rois = social_rois()

rois = { 'eyes_nf', 'face', 'face_non_eyes' };

end

function rois = nonsocial_rois()

rois = { 'left_nonsocial_object', 'right_nonsocial_object', 'nonsocial_object' ...
  , 'left_nonsocial_object_eyes_nf_matched', 'right_nonsocial_object_eyes_nf_matched' ...
};

end

function labels = handle_labels(labels)

bfw.unify_single_region_labels( labels );

end

function mask = get_base_mask(labels)

mask = fcat.mask( labels ...
  , @findnone, bfw.nan_unit_uuid() ...
  , @find, 'm1' ...
  , @find, 'exclusive_event' ...
);

end