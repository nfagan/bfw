%%  Load data

all_files = shared_utils.io.findmat( bfw.gid('raw_events_remade') );
all_files = shared_utils.io.filenames( all_files, true );
sessions = cellfun( @(x) x(1:8), all_files, 'un', 0 );
unique_sessions = unique( sessions );
num_session_bins = 42;
binned_sessions = shared_utils.vector.distribute( 1:numel(unique_sessions), num_session_bins );
binned_sessions = cellfun( @(x) unique_sessions(x), binned_sessions, 'un', 0 );

target_unit_ids = [ 588, 790, 2610, 1007, 1230, 1242, 322, 259, 359, 1771, 1796, 1795 ];
% target_unit_ids = xlsread( 'C:\Users\nick\Downloads\CellID.xlsx' );
use_target_units = true;

use_corrected_events = true;

events_subdir = 'raw_events_remade';
if ( ~use_corrected_events )
  events_subdir = 'raw_events';
end

% binned_sessions = { {'01132019'} };

%%  Load sessions containing target unit ids

cc_spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes' );
unit_id_strs = arrayfun( @(x) sprintf('unit_uuid__%d', x), target_unit_ids, 'un', 0 );
seshs = combs( cc_spikes.labels, 'session', find(cc_spikes.labels, unit_id_strs) );
binned_sessions = { seshs };

%%

for session_index = 1:numel(binned_sessions)
% for session_index = 1
  
shared_utils.general.progress( session_index, numel(binned_sessions) );

seshs = binned_sessions{session_index};
sesh_ind = ismember( sessions, seshs );

select_files = all_files(sesh_ind);

% select_files = [
%   {'01042019'}
%   {'01092019'}
%   {'01112019'}
%   {'01132019'}
%   {'01152019'}
%   {'02042018'}
%   {'09292018'}
%   {'10092018'}
% ];

bin_size = 1e-2;
step_size = 1e-2; % 10ms

res = bfw_make_psth_for_fig1( ...
    'is_parallel', true ...
  , 'window_size', bin_size ...
  , 'step_size', step_size ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 0.5 ...
  , 'files_containing', select_files(:)' ...
  , 'events_subdir', events_subdir ...
);

if ( isempty(res.gaze_counts.spikes) )
  continue
end

%%  Add whole face roi

gaze_counts = res.gaze_counts;
gaze_counts.labels = res.gaze_counts.labels';
replace( gaze_counts.labels, 'nonsocial_object_eyes_nf_matched', 'nonsocial_object' );

[~, transform_ind] = bfw.make_whole_face_roi( gaze_counts.labels );
gaze_counts.spikes = gaze_counts.spikes(transform_ind, :);
gaze_counts.rasters = gaze_counts.rasters(transform_ind, :);
gaze_counts.events = gaze_counts.events(transform_ind, :);

%%  Remove nonsocial object events prior to the actual introduction of the object.

base_mask = bfw.find_sessions_before_nonsocial_object_was_added( ...
  gaze_counts.labels, find(gaze_counts.labels, 'nonsocial_object') );

base_mask = setdiff( rowmask(gaze_counts.labels), base_mask );
base_mask = find( gaze_counts.labels, 'm1', base_mask );

%%  Plot psths w/ rasters

do_save = true;
smooth_each = true;
conf = bfw.config.load();

labels = gaze_counts.labels';
spikes = gaze_counts.spikes;
rasters = gaze_counts.rasters;
events = gaze_counts.events;

if ( smooth_each )
  for i = 1:size(spikes, 1)
    spikes(i, :) = movmean( spikes(i, :), 10 );
  end
end

spikes = spikes / bin_size;

assert_ispair( spikes, labels );
assert_ispair( rasters, labels );
assert_ispair( events, labels );

raster_span = 0.25;
raster_marker_size = 0.1;
peak_raster_marker_size = 32;
p_step_size = 0.025;
p_size = 10;

% smooth_func = @(x) smoothdata( x, 'SmoothingFactor', 0.8 );
smooth_func = @(x) smoothdata( x, 'movmean', 5 );

target_units = arrayfun( @(x) sprintf('unit_uuid__%d', x), target_unit_ids, 'un', 0 );

if ( use_target_units )
  mask = fcat.mask( labels, base_mask ...
    , @findor, target_units ...
  );
else
  mask = base_mask;
end

unit_I = findall( labels, {'region', 'unit_uuid', 'session'}, mask );
t = gaze_counts.t;
xlims = [-0.5, 0.5 ];

for i = 1:numel(unit_I)
%   shared_utils.general.progress( i, numel(unit_I) );
  
  pl = plotlabeled.make_common();
  pl.x = t;
  pl.add_smoothing = true;
  pl.smooth_func = smooth_func;
  pl.add_errors = false;
  pl.group_order = flip( {'nonsocial_object', 'face', 'eyes_nf', 'whole_face'} );
  
  unit_ind = unit_I{i};
  spks = spikes(unit_ind, :);
  labs = prune( labels(unit_ind) );
  rsts = rasters(unit_ind, :);  
  durs = events(unit_ind, gaze_counts.event_key('duration'));
  
  [axs, hs, inds] = pl.lines( spks, labs, 'roi', {'region', 'unit_uuid'} );
  for j = 1:numel(inds)
    ax = axs(j);
    hold( ax, 'on' );
    ipanel = inds{j};
    tot_inds = sum( cellfun(@numel, ipanel) );
    lims = get( axs(j), 'ylim' );
    lim_span = diff( lims );
    span_stp = (lim_span * raster_span) / tot_inds;
    
    if ( numel(hs{j}) == 4 )
      set_default_line_colors( hs{j} );
    end
    
    off = 0;
    for k = 1:numel(ipanel)
      iline = ipanel{k};
      line_color = get( hs{j}(k), 'color' );
      raster_xs = [];
      raster_ys = [];
      peak_xs = nan( size(iline) );
      peak_ys = nan( size(peak_xs) );
      
      after0 = t >= 0;
      t_after0 = t(after0);
      order_spikes = spks(iline, after0);
      order_durs = durs(iline);
%       [order_ind, peak_ind] = order_by_peak( order_spikes, 'desc' );
      [order_durs, order_ind] = sort( order_durs, 'desc' );
      
      for h = 1:numel(iline)
        curr = iline(order_ind(h));        
        rst = cellfun( @(x) x(:)', rsts(curr, :), 'un', 0 );
        rst = horzcat( rst{:} );
        y = lims(2) - span_stp * off;
        ys = repmat( y, size(rst) );
        raster_xs = [ raster_xs; rst(:) ];
        raster_ys = [ raster_ys; ys(:) ];
%         peak_xs(h) = t_after0(peak_ind(h));
        peak_xs(h) = order_durs(h);
        peak_ys(h) = y;
        off = off + 1;
      end

      hrst = scatter( axs(j), raster_xs, raster_ys );
      set( hrst, 'MarkerFaceColor', line_color );
      set( hrst, 'MarkerEdgeColor', line_color );
      set( hrst, 'sizedata', raster_marker_size );
      
      hpeak = scatter( axs(j), peak_xs, peak_ys, 'k*' );
      set( hpeak, 'sizedata', peak_raster_marker_size );
    end
    
    anova_res = arrayfun( @(x) bfw_ct.social_nested_anova(spks(:, x), labs), 1:size(spks, 2) );
    social_p = [anova_res.social_p];
    eye_ne_face_p = [anova_res.post_hoc_eyes_v_non_eye_face];
    
    max_y = max( get(ax, 'ylim') );
    tmp_y = plot_sig( ax, social_p, t, [0, 1, 0], p_size, p_step_size, 0 );
    max_y = max( tmp_y, max_y );
    
    tmp_y = plot_sig( ax, eye_ne_face_p, t, [1, 0, 0], p_size, p_step_size, 1 );
    max_y = max( tmp_y, max_y );
    
%     % Test against nonsocial object.
%     rois = cellfun( @(x) combs(labs, 'roi', x), ipanel );
%     [~, ns_ind] = ismember( 'nonsocial_object', rois );
%     [~, ef_ind] = ismember( {'eyes_nf', 'face'}, rois );
%     [~, fo_ind] = ismember( {'whole_face', 'nonsocial_object'}, rois );
%     
%     if ( ~any(ef_ind == 0) )
%       ind_eyes = ipanel{ef_ind(1)};
%       ind_face = ipanel{ef_ind(2)};
%       tmp_y = plot_comparing( ax, spks, t, ind_eyes, ind_face, p_step_size, p_size, 0, [1, 0, 0] );
%       max_y = max( tmp_y, max_y );
%     end
%     if ( ~any(fo_ind == 0) )
%       ind_face = ipanel{fo_ind(1)};
%       ind_obj = ipanel{fo_ind(2)};
%       tmp_y = plot_comparing( ax, spks, t, ind_face, ind_obj, p_step_size, p_size, 1, [0, 1, 0] );
%       max_y = max( tmp_y, max_y );
%     end
    
    set( ax, 'ylim', [lims(1), max_y] );
    set( ax, 'xlim', xlims );
  end
  
  if ( do_save )
    reg = char( combs(labs, 'region') );
    shared_utils.plot.fullscreen( gcf );
    save_p = fullfile( bfw.dataroot(conf), 'plots/static_psth', dsp3.datedir, reg );
    dsp3.req_savefig( gcf, save_p, labs, {'region', 'unit_uuid'} );
  end
end

end

%%

function set_default_line_colors(hs)

assert( numel(hs) == 4 );

orange = [252, 186, 3] / 255;
purple = [252, 3, 244] / 255;
blue = [3, 3, 252] / 255;
green = [3, 252, 86] / 255;

colors = flip( {green, purple, blue, orange} );
for i = 1:numel(hs)
  set( hs(i), 'color', colors{i} );
end

end

function max_y = plot_comparing(ax, spks, t, ind_a, ind_b, p_step_size, p_size, y_off, base_color)

dat_a = spks(ind_a, :);
dat_b = spks(ind_b, :);
ps = arrayfun( @(x) ranksum(dat_a(:, x), dat_b(:, x)), 1:size(dat_a, 2) );
max_y = plot_sig( ax, ps, t, base_color, p_size, p_step_size, y_off );

end

function max_y = plot_sig(ax, ps, t, base_color, p_size, p_step_size, y_off)

threshs = [0.05, 0.01];
colors = { base_color * 0.5, base_color };
ylims = get( ax, 'ylim' );
lim_span = diff( ylims );
max_y = max( ylims );

for i = 1:numel(threshs)
  sigi = ps < threshs(i);
  sigts = t(sigi);
  y = max( ylims ) + lim_span * p_step_size * y_off;
  ys = repmat( y, size(sigts) );
  max_y = max( max_y, y );

  hsig = scatter( sigts, ys );  
  set( hsig, 'MarkerFaceColor', colors{i} );
  set( hsig, 'MarkerEdgeColor', colors{i} );
  set( hsig , 'sizedata', p_size );
end

end

function [order, peak_ind] = order_by_peak(mat, ord)

[~, peak_ind] = max( mat, [], 2 );
[peak_ind, order] = sort( peak_ind, ord );

end