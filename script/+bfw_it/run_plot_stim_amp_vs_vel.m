conf = bfw.config.load();
conf.PATHS.data_root = fullfile( '/mnt/dunham', bfw_image_task_data_root() );

select_files = {'04202019', '04222019', '04262019', '04282019', '04302019', '05052019'};

amp_vel_outs = bfw_stim_amp_vs_vel( ...
    'look_ahead', 5 ...
  , 'files_containing', select_files ...
  , 'fixations_subdir', 'raw_eye_mmv_fixations' ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'minimum_fix_length', 10 ...
  , 'minimum_saccade_length', 10 ...
  , 'config', conf ...
);

amps = amp_vel_outs.amps;
vels = amp_vel_outs.velocities;
labs = amp_vel_outs.labels';
ns =   amp_vel_outs.ns;

replace( labs, 'm1_exclusive_event', 'eye_stim' );
replace( labs, 'm1_radius_excluding_inner_rect', 'face_stim' );
prune( labs );

addcat( labs, 'region' );

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'stim_amp_v_vel', dsp3.datedir );

%%

do_save = true;
run_level = true;
subdir = '';

pl = plotlabeled();
pl.marker_size = 10;
pl.shape = [2, 1];
pl.panel_order = { 'free_viewing', 'nonsocial_control' };

pltlabs = labs';

X = amps;
Y = vels;

bfw_it.add_stim_frequency_labels( pltlabs );
% bfw_it.decompose_image_id_labels( pltlabs );
mask = bfw_it.find_non_error_runs( pltlabs );

if ( run_level )
  [pltlabs, run_I] = keepeach( pltlabs', {'unified_filename', 'stim_type'}, mask );
  X = bfw.row_nanmean( X, run_I );
  Y = bfw.row_nanmean( Y, run_I );
  mask = rowmask( X );
end

fcats = { 'region', 'stim_protocol' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'region', 'stim_protocol', 'stim_frequency' };

I = findall( pltlabs, fcats, mask );

all_axs = [];
figs = gobjects( numel(I), 1 );
figlabs = cell( size(figs) );

for i = 1:numel(I)
  pltx = X(I{i});
  plty = Y(I{i});
  
  nan_ind = isnan( pltx ) | isnan( plty );
  
  pltx = pltx(~nan_ind);
  plty = plty(~nan_ind);
  plt_labs = pltlabs(I{i}(~nan_ind));
  
  pl.fig = figure(i);

  [axs, ids] = pl.scatter( pltx, plty, plt_labs, gcats, pcats );
  
  xlim( axs, [0, 250] );
  ylim( axs, [0, 9e3] );
  xlabel( axs(1), 'Amplitude (px)' );
  ylabel( axs(1), 'Peak velocity (px/s)' );
  
  plotlabeled.scatter_addcorr( ids, pltx, plty, 0.05, false );
  
  all_axs = [ all_axs; axs(:) ];
  
  figs(i) = figure(i);
  
  figlabs{i} = plt_labs;
end

shared_utils.plot.match_xlims( all_axs );
shared_utils.plot.match_ylims( all_axs );
shared_utils.plot.fullscreen( figs );

for i = 1:numel(all_axs)
  axis( all_axs(i), 'square' );
end

if ( do_save )
  for i = 1:numel(figs)
    dsp3.req_savefig( figs(i), fullfile(plot_p, subdir), figlabs{i}, fcats, 'amp_vel' );
  end
end

%%  compare stim to sham, within freq

uselabs = labs';
run_level = true;

X = amps;
Y = vels;

bfw_it.add_stim_frequency_labels( uselabs );
mask = bfw_it.find_non_error_runs( uselabs );

nans = isnan( X ) | isnan( Y );
mask = intersect( mask, find(~nans) );

if ( run_level )
  [uselabs, run_I] = keepeach( uselabs', {'unified_filename', 'stim_type'}, mask );
  X = bfw.row_nanmean( X, run_I );
  Y = bfw.row_nanmean( Y, run_I );
  mask = rowmask( X );
end

test_each = { 'region', 'task_type', 'stim_protocol', 'stim_frequency' };

[plabs, I] = keepeach( uselabs', test_each, mask );

iters = 1e3;

all_ps = rownan( numel(I) );

for i = 1:numel(I)
  ind = I{i};
  
  subset = uselabs(I{i});
  
  diffs = rownan( iters+1 );
  
  for j = 1:iters+1
    if ( j == 1 )
      perm_ind = rowmask( subset );
    else
      perm_ind = randperm( rows(subset) );
    end
    
    keep( subset, perm_ind );
    
    stim_ind = find( subset, 'stim' );
    sham_ind = find( subset, 'sham' );
    
    xstim = X(ind(stim_ind));
    ystim = Y(ind(stim_ind));
    
    xsham = X(ind(sham_ind));
    ysham = Y(ind(sham_ind));
    
    pstim = polyfit( xstim, ystim, 1 );
    psham = polyfit( xsham, ysham, 1 );
    
    slope_stim = pstim(1);
    slope_sham = psham(1);
    
    diffs(j) = slope_stim - slope_sham;
  end
  
  real_diff = diffs(1);
  fake_diffs = diffs(2:end);
  
  if ( sign(real_diff) == -1 )
    p = sum(fake_diffs < real_diff) / iters;
  else
    p = sum(fake_diffs > real_diff) / iters;
  end
  
  all_ps(i) = p;  
end

[t_inds, rc] = tabular( plabs, test_each );

tbl = fcat.table( cellrefs(all_ps, t_inds), rc{:} );

% dsp3.writetable( tbl, fullfile(plot_p, subdir, 'ps.csv') );