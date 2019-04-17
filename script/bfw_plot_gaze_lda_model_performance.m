function bfw_plot_gaze_lda_model_performance(lda_perf, lda_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @(labels, mask) mask;
defaults.alpha = 0.05;

params = bfw.parsestruct( defaults, varargin );

assert_ispair( lda_perf, lda_labels );

run_average_model_performance( lda_perf, lda_labels', params );
prop_significant( lda_perf, lda_labels', params );

end

function run_average_model_performance(perf, labels, params)

% false -> plot with all units
average_model_performance( perf, labels', false, params );

% true -> plot with only significant lda units
average_model_performance( perf, labels', true, params );

end

function prop_significant(perf, labels, params)

[p_correct, had_missing, p_value] = decompose_performance( perf );

mask = fcat.mask( labels, find_non_missing(had_missing) ...
  , @find, 'non-shuffled' ... % find real percent only
  , @findnone, 'unit_uuid__NaN' ...
);

mask = params.mask_func( labels', mask );

sig_cat = 'significant';
nonsig_lab = sprintf( 'not-%s', sig_cat );

addsetcat( labels, sig_cat, nonsig_lab );
setcat( labels, sig_cat, sig_cat, find(p_value < params.alpha) )

props_each = { 'region', 'roi' };
props_of = sig_cat;

[props, prop_labels] = proportions_of( labels, props_each, props_of, mask );

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;

xcats = { 'shuffled-type'};
gcats = { sig_cat, 'roi' };
pcats = { 'region' };

plt_mask = findnone( prop_labels, nonsig_lab );

pltdat = props(plt_mask);
pltlabs = prune( prop_labels(plt_mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  base_p = get_base_plot_p( params );
  save_p = fullfile( base_p, 'percent_significant_lda_units' );
  shared_utils.plot.fullscreen( gcf );
  
  dsp3.req_savefig( gcf, save_p, pltlabs, csunion(pcats, gcats) );
end


end

function average_model_performance(perf, labels, require_significant, params)

[p_correct, had_missing, p_value] = decompose_performance( perf );

mask = fcat.mask( labels, find_non_missing(had_missing) ...
  , @findnone, 'real-null' ...
  , @findnone, 'unit_uuid__NaN' ...
);

mask = params.mask_func( labels', mask );

if ( require_significant )
  mask = intersect( mask, find(p_value < 0.05) );
  sig_subdir = 'only_significant_lda_units';
else
  sig_subdir = 'all_units';
end

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;

xcats = { 'roi' };
gcats = { 'shuffled-type' };
pcats = { 'region' };

pltdat = p_correct(mask);
pltlabs = prune( labels(mask) );

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  base_p = get_base_plot_p( params );
  save_p = fullfile( base_p, 'average_model_performance', sig_subdir );
  shared_utils.plot.fullscreen( gcf );
  
  dsp3.req_savefig( gcf, save_p, pltlabs, csunion(pcats, gcats) );
end

end

function p = get_base_plot_p(params)

p = fullfile( bfw.dataroot(params.config), 'plots', 'gaze_lda' ...
  , dsp3.datedir, params.base_subdir );

end

function ind = find_non_missing(had_missing)

ind = find( ~isnan(had_missing) & had_missing == 0 );

end

function [p_correct, had_missing, p_value] = decompose_performance(perf)

p_correct = perf(:, 1);
had_missing = perf(:, 2);
p_value = perf(:, 3);

end
