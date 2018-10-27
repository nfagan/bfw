conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf, 'cache', true );

plot_p = fullfile( bfw.dataroot, 'plots', 'stim', datestr(now, 'mmddyy') );

%%
select_files = session_types.m1_radius_sessions; %  "face stim"

lbs = [0, 2.5];
las = [2.5, 5];
kinds = { 'early', 'late' };

labs = fcat();
nfix = [];
lookdur = [];
stim_distances = [];

for i = 1:numel(kinds)

  evt_outs = bfw_stim_distance_vs_fixations( ...
      'config', conf ...
    , 'files_containing', select_files ...
    , 'look_back', lbs(i) ...
    , 'look_ahead', las(i) ...
  );

  nfix = [ nfix; evt_outs.nfix ];
  lookdur = [ lookdur; evt_outs.lookdur ];
  stim_distances = [ stim_distances; evt_outs.stim_distances ];
  
  addsetcat( evt_outs.labels, 'look_period', kinds{i} );
  
  prune( bfw.get_region_labels(evt_outs.labels) );
  
  append( labs, evt_outs.labels' );
end

%%  means

uselabs = labs';

mask = fcat.mask( uselabs, find(~isnan(stim_distances)) ...
  , @findnone, session_types.m1_exclusive_sessions ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, 'eyes_nf' ...
);

mean_masked = nanmean( stim_distances(mask) );
dev_masked = nanstd( stim_distances(mask) );

thresh = mean_masked + dev_masked * 3;
mask = mask( stim_distances(mask) <= thresh );

% edges = [ 0:50:round(thresh) ];
edges = 2;

assert_ispair( stim_distances, uselabs );

[~, edges] = histcounts( stim_distances(mask), edges );
bin_indices = discretize( stim_distances(mask), edges );

bin_values = rownan( rows(uselabs) );

for i = 1:numel(bin_indices)
  if ( isnan(bin_indices(i)) ), continue; end
  
  bin_values(mask(i)) = edges(bin_indices(i));
end

addsetcat( uselabs, 'distance_bin', cellstr(num2str(bin_values)) );

spec = { 'looks_by', 'unified_filename', 'roi', 'stim_type', 'distance_bin', 'look_period' };

[meanlabs, I] = keepeach( uselabs', spec, mask );

meanfix = rownanmean( nfix, I );
meandur = rownanmean( lookdur, I );

repset( addcat(meanlabs, 'measure'), 'measure', {'n-fixations', 'look-duration'} );

meandat = [ meanfix; meandur ];

%%

pltdat = meandat;
pltlabs = meanlabs';

pl = plotlabeled.make_common();

mask = fcat.mask( pltlabs, find(~isnan(pltdat)) ...
  , @find, {'m1', 'eyes_nf'} ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, {'look-duration', 'dmpfc'} ...
);

pl.fig = figure(2);

xcats = { 'distance_bin' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'measure', 'region', 'look_period' };

axs = pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );


%%

do_save = true;
subdir = 'bin_350';

pltlabs = meanlabs';

X = str2double( cellstr(pltlabs, 'distance_bin') );
Y = meandat;

bvals = unique( X(~isnan(X)) );

% jitter
stim_ind = find( pltlabs, 'stim' );
X(stim_ind) = X(stim_ind) + 5;

assert_ispair( X, pltlabs );
assert_ispair( Y, pltlabs );

pl = plotlabeled.make_common();
pl.marker_size = 10;

mask = fcat.mask( pltlabs, find(~isnan(X)) ...
  , @find, {'m1', 'eyes_nf'} ...
  , @findnone, '10112018_position_1.mat' ...
);

fcats = { 'measure', 'region' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'measure', 'region' };

I = findall( pltlabs, fcats, mask );

figs = gobjects( size(I) );
all_axs = gobjects(0);

for i = 1:numel(I)
  f = figure(i);
  
  pl.fig = f;
  
  plt_x = X(I{i});
  plt_y = Y(I{i});
  plt_labs = pltlabs(I{i});

  [ax, ids] = pl.scatter( plt_x, plt_y, plt_labs, gcats, pcats );

  h = plotlabeled.scatter_addcorr( ids, plt_x, plt_y );
  
%   set( ax, 'xtick', bvals );
  shared_utils.plot.xlabel( ax, 'Distance from eye-center (px)' );
  shared_utils.plot.match_xlims( ax );
  
  figs(i) = f;
  
  all_axs = [ all_axs; ax(:) ];
end

shared_utils.plot.match_xlims( all_axs );

if ( do_save )
  for i = 1:numel(I)
    shared_utils.plot.fullscreen( figs(i) );
    full_plot_p = fullfile( plot_p, subdir );
    dsp3.req_savefig( figs(i), full_plot_p, pltlabs(I{i}), csunion(fcats, pcats), 'scatter' );
  end
end