conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf, 'cache', true );

eyes_sessions = session_types.m1_exclusive_sessions;
face_sessions = session_types.m1_radius_sessions;

select_files = csunion( eyes_sessions, face_sessions );

plot_p = fullfile( bfw.dataroot, 'plots', 'stim', datestr(now, 'mmddyy') );

%%

amp_vel_outs = bfw_stim_amp_vs_vel( ...
    'look_ahead', 5 ...
  , 'files_containing', select_files ...
  , 'fixations_subdir', 'eye_mmv_fixations' ...
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

prune( bfw.get_region_labels(labs) );

%%

do_save = true;
subdir = 'amp_vs_vel';

pl = plotlabeled();
pl.marker_size = 10;

pltlabs = labs';

X = amps;
Y = vels;

mask = fcat.mask( pltlabs ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
);

if ( isempty(mask) ), fprintf( '\n None matched.\n\n' ); end

fcats = { 'region', 'stim_protocol' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'region', 'stim_protocol' };

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
  
  plotlabeled.scatter_addcorr( ids, pltx, plty );
  
  all_axs = [ all_axs; axs(:) ];
  
  figs(i) = figure(i);
  
  figlabs{i} = plt_labs;
end

shared_utils.plot.match_xlims( all_axs );
shared_utils.plot.match_ylims( all_axs );
shared_utils.plot.fullscreen( figs );

if ( do_save )
  for i = 1:numel(figs)
    dsp3.req_savefig( figs(i), fullfile(plot_p, subdir), figlabs{i}, fcats, 'amp_vel' );
  end
end

%%

uselabs = labs';

X = amps;
Y = vels;

mask = fcat.mask( uselabs, find(~isnan(X) & ~isnan(Y)) ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, {'stim', 'sham'} ...
);

test_each = { 'region', 'task_type', 'stim_protocol' };

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

dsp3.writetable( tbl, fullfile(plot_p, subdir, 'ps.csv') );