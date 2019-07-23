function bfw_plot_mutual_psth(psth_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask = rowmask( psth_outs.labels );
defaults.marker_size = 2;
defaults.raster_fraction = 0.2;

params = bfw.parsestruct( defaults, varargin );

labels = psth_outs.labels';

handle_labels( labels );
mask = get_base_mask( labels, params.mask );

plot_initiator_terminator( psth_outs, labels, mask, params )

end

function plot_initiator_terminator(psth_outs, labels, mask, params)

mask = mutual_mask( labels, mask );

subdir_cats = { 'region' };

fig_cats = { 'unit_uuid' };
% fig_cats = {};
fig_I = findall_or_one( labels, fig_cats, mask );

fig = figure(1);
shared_utils.plot.prevent_legend_autoupdate( fig );

psth_dat = psth_outs.psth;

for i = 1:numel(fig_I)
  fig_ind = fig_I{i};
  
  pl = plotlabeled.make_common();
  pl.x = psth_outs.t;
  pl.panel_order = { 'onset', 'offset' };
  pl.add_smoothing = true;
  pl.smooth_func = @(x) smooth( x, 5 );
  
  gcats = { 'mutual_event_type' };
%   pcats = { 'region', 'aligned_to', 'roi' };
  pcats = { 'region', 'aligned_to', 'roi', 'unit_uuid' };
  
  plot_dat = psth_dat(fig_ind, :);
  plot_labs = labels(fig_ind);
  
  [axs, hs, inds] = pl.lines( plot_dat, plot_labs, gcats, pcats );
  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, 0 );
  
  add_rasters( axs, hs, inds, plot_dat, psth_outs.t, params );
  
  subdir_combs = combs( plot_labs, subdir_cats );
  subdir_label = strjoin( columnize(fcat.strjoin(subdir_combs))', '_' );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    save_p = get_save_p( params, subdir_label );
    dsp3.req_savefig( fig, save_p, plot_labs, [pcats, fig_cats] );
  end
end

end

function add_rasters(axs, hs, inds, plot_dat, t, params)

lim_frac = params.raster_fraction;
marker_size = params.marker_size;

for i = 1:numel(axs)
  ax = axs(i);
  ind = inds{i};
  psth_h = hs{i};
  
  n_trials = sum( cellfun(@numel, ind) );
  lims = get( ax, 'ylim' );
  hold( ax, 'on' );
  
  trial_span = (lims(2) - lims(1)) / n_trials * lim_frac;
  span_stp = 1;
  
  for j = 1:numel(ind)
    if ( isempty(ind{j}) )
      continue;
    end
       
    current_line_h = psth_h(j);
    raster_dat = plot_dat(ind{j}, :) > 0;
    raster_inds = find_raster_inds( raster_dat );
    
    for k = 1:numel(raster_inds)
      raster_ind = raster_inds{k};
      
      if ( isempty(raster_ind) )
        continue;
      end
      
      y_coord = lims(2) - ((span_stp - 1) * trial_span);
      y_coord = repmat( y_coord, size(raster_ind) );
      x_coord = t(raster_ind);
      
      raster_h = plot( ax, x_coord, y_coord, 'k*' );
      set( raster_h, 'color', get(current_line_h, 'color') );
      set( raster_h, 'markersize', marker_size );
      
      span_stp = span_stp + 1;
    end
  end
end

end

function inds = find_raster_inds(raster_dat)

inds = cell( rows(raster_dat), 1 );

for i = 1:rows(raster_dat)
  inds{i} = find( raster_dat(i, :) );
end

end

function labels = handle_labels(labels)

bfw.unify_single_region_labels( labels );

onset_ind = find( labels, 'onset' );
offset_ind = find( labels, 'offset' );

[initiator_inds, initiators] = findall( labels, 'initiator', onset_ind );
[terminator_inds, terminators] = findall( labels, 'terminator', offset_ind );

addcat( labels, 'mutual_event_type' );

for i = 1:numel(initiator_inds)
  initiator_label = sprintf( 'onset_%s', initiators{1, i} );
  setcat( labels, 'mutual_event_type', initiator_label, initiator_inds{i} );
end

for i = 1:numel(terminator_inds)
  terminator_label = sprintf( 'offset_%s', terminators{1, i} );
  setcat( labels, 'mutual_event_type', terminator_label, terminator_inds{i} );
end

end

function mask = mutual_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @find, 'mutual' ...
  , @findnone, {'offset_simultaneous_stop', 'onset_simultaneous_start'} ...
);

end

function mask = get_base_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @findnone, bfw.nan_unit_uuid() ...
);

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'mutual_psth' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end