function scatter_gaze_perf_vs_modulation_index(perf, labels, event_info, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.event_mask_func = @bfw.default_mask_func;
defaults.lda_each = { 'region' };
defaults.behav_metric = 'duration';

params = bfw.parsestruct( defaults, varargin );
behav_metric = validatestring( params.behav_metric ...
  , {'duration', 'total_duration', 'nfix'}, mfilename, 'behav_metric' );

assert_ispair( perf, labels );

mask = params.mask_func( labels, rowmask(labels) );
event_mask = ...
  params.event_mask_func( event_info.labels, rowmask(event_info.labels) );

scatter_I = findall_or_one( labels, 'roi-pairs', mask );

for i = 1:numel(scatter_I)
  scatter_one( perf, labels, scatter_I{i}, event_info, event_mask, params );
end

end

function [roi_a, roi_b] = rois_from_roi_pair(roi_pair)

splt = strsplit( roi_pair, ' ' );
assert( numel(splt) == 3 );
roi_a = splt{1};
roi_b = splt{3};

end

function scatter_one(perf, labels, mask, event_info, event_mask, params)

roi_pair = combs( labels, 'roi-pairs', mask );
assert( numel(roi_pair) == 1 );
[roi_a, roi_b] = rois_from_roi_pair( roi_pair{1} );

[mean_labs, each_I, each_C] = ...
  keepeach( labels', params.lda_each, mask );
mean_perf = bfw.row_nanmean( perf, each_I );
mod_indices = nan( rows(mean_perf), 1 );

fix_dur = bfw.event_column( event_info, 'duration' );
gaze_dat = fix_dur;

for i = 1:numel(each_I)
  match_ind = find( event_info.labels, each_C(:, i), event_mask );
  ind_a = find( event_info.labels, roi_a, match_ind );
  ind_b = find( event_info.labels, roi_b, match_ind );
  
  subset_a = gaze_dat(ind_a);
  subset_b = gaze_dat(ind_b);
  
  switch ( params.behav_metric )
    case 'duration'
      mu_a = nanmean( subset_a );
      mu_b = nanmean( subset_b );
      
    case 'total_duration'
      mu_a = nansum( subset_a );
      mu_b = nansum( subset_b );
      
    case 'nfix'
      mu_a = numel( subset_a );
      mu_b = numel( subset_b );
    
    otherwise
      error( 'Unrecognized behav_metric "%s".', params.behav_metric );
  end
  
  mod_indices(i) = abs( (mu_a - mu_b) / (mu_a + mu_b) );
end

%%

pcats = {'roi-pairs', 'region'};

pl = plotlabeled.make_common();
pl.marker_size = 4;
[axs, ids] = ...
  pl.scatter( mod_indices, mean_perf, mean_labs, {}, pcats );

shared_utils.plot.xlabel( axs, sprintf('Modulation index (%s)', params.behav_metric) );
shared_utils.plot.ylabel( axs, 'Gaze decoding accuracy' );

hs = plotlabeled.scatter_addcorr( ids, mod_indices, mean_perf );

if ( params.do_save )
  save_p = get_save_p( params );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, mean_labs, pcats );
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'gaze_accuracy_vs_gaze_behav', params.base_subdir, varargin{:} );

end