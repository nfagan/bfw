conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf );

plot_p = fullfile( get_nf_local_dataroot, 'plots', 'stim', datestr(now, 'mmddyy') );

%%
select_files = session_types.m1_radius_sessions; %  "face stim"

evt_outs = debug_raw_look_back( ...
    'config', conf ...
  , 'look_back', -1 ...
  , 'look_ahead', 5 ...
  , 'keep_within_threshold', 0.3 ...
  , 'files_containing', select_files ...
  , 'include_samples', true ...
  , 'use_stop_time', true ...
);

labs = evt_outs.labels';
ib = evt_outs.traces;
is_fix = evt_outs.traces;
t = evt_outs.t;
samples = evt_outs.samples;
sample_key = evt_outs.samples_key;
stim_distances = evt_outs.stim_distances;

prune( bfw.get_region_labels(labs) );

%%  get fix events + duration

t_ind = t >= 0 & t <= 5;
subset_t = t(t_ind);

fixdat = logical( ib(:, t_ind) );

[nfix, totaldur] = bfw.get_fix_info_from_bounds( fixdat, subset_t );

%%  means

uselabs = labs';

n_bins = 5;

mask = fcat.mask( uselabs ...
  , @findnone, session_types.m1_exclusive_sessions ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, 'face_padded_large' ...
);

[~, edges] = histcounts( stim_distances, n_bins );
bin_indices = discretize( stim_distances, edges );

bin_values = nan( size(bin_indices) );

for i = 1:numel(bin_values)
  if ( isnan(bin_indices(i)) ), continue; end
  bin_values(i) = edges(bin_indices(i));
end

addsetcat( uselabs, 'distance_bin', cellstr(num2str(bin_values)) );

spec = { 'looks_by', 'unified_filename', 'roi', 'stim_type', 'distance_bin' };

[meanlabs, I] = keepeach( uselabs', spec, mask );

meanfix = rownanmean( nfix, I );
meandur = rownanmean( totaldur, I );

repset( addcat(meanlabs, 'measure'), 'measure', {'n-fixations', 'look-duration'} );

meandat = [ meanfix; meandur ];

%%

do_save = false;

pltlabs = meanlabs';

X = cellfun( @str2double, cellstr(pltlabs, 'distance_bin') );
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
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, 'face_padded_large' ...
);

fcats = { 'measure' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'measure' };

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
  
  set( ax, 'xtick', bvals );
  shared_utils.plot.xlabel( ax, 'Distance from eye-center (px)' );
  shared_utils.plot.match_xlims( ax );
  
  figs(i) = f;
  
  all_axs = [ all_axs; ax(:) ];
end

if ( do_save )
  for i = 1:numel(I)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( f, plot_p, pltlabs(I{i}), csunion(fcats, pcats), 'scatter' );
  end
end
