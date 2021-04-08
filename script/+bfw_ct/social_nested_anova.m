function out = social_nested_anova(spikes, labels, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

assert_ispair( spikes, labels );
validateattributes( spikes, {'double'}, {'vector'}, mfilename, 'spikes' );
  
subset_spikes = spikes(mask);
subset_social_group = make_social_group( labels, mask );

anova_factors = { 'roi' };
groups = cellfun( @(x) categorical(labels, x, mask), anova_factors, 'un', 0 );
groups{end+1} = subset_social_group;

% Nest rois in social
nesting = zeros( numel(anova_factors)+1 );
nesting(strcmp(anova_factors, 'roi'), numel(groups)) = 1;

[p, tbl, stats] = anovan( subset_spikes, groups ...
  , 'nested', nesting ...
  , 'varnames', [anova_factors, {'social'}] ...
  , 'display', 'off' ...
);

out_labs = keepeach_or_one( labels', {}, mask );
post_hoc_labs = addsetcat( out_labs', 'anova_factor', 'social' );

addcat( out_labs, 'anova_factor' );
repset( out_labs, 'anova_factor', [anova_factors, {'social'}] );

%% post hoc eyes vs noneye face

eye_ind = find( labels, 'eyes_nf', mask );
ne_face_ind = find( labels, 'face', mask );
p_post_hoc = ranksum( spikes(eye_ind), spikes(ne_face_ind) );

%%

out = struct();
out.anova_labels = out_labs;
out.anova_p = p;
out.anova_tbl = tbl;
out.anova_stats = stats;
out.roi_p = p(1);
out.social_p = p(2);
out.post_hoc_eyes_v_non_eye_face = p_post_hoc;
out.post_hoc_labels = post_hoc_labs;

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
rois = { 'eyes_nf', 'face', 'face_non_eyes', 'whole_face' };
end

function rois = nonsocial_rois()
rois = { 'left_nonsocial_object', 'right_nonsocial_object', 'nonsocial_object' ...
  , 'left_nonsocial_object_eyes_nf_matched', 'right_nonsocial_object_eyes_nf_matched' ...
  , 'nonsocial_object_eyes_nf_matched' ...
};
end