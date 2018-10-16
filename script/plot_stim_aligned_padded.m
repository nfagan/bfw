conf = bfw.config.load();

use_events = true;

select_files = { '10112018', '10152018' };

if ( use_events )
  evt_outs = debug_raw_look_back( ...
      'config', conf ...
    , 'look_back', -1 ...
    , 'look_ahead', 5 ...
    , 'keep_within_threshold', 0.3 ...
    , 'files_containing', select_files ...
  );

  labs = evt_outs.labels';
  ib = evt_outs.traces;
  is_fix = evt_outs.traces;
  t = evt_outs.t;

  prune( bfw.get_region_labels(labs) );

else
  aligned_outs = get_stim_aligned_samples( ...
      'config', conf ...
    , 'look_back', -2 ...
    , 'look_ahead', 5 ...
    , 'samples_subdir', 'aligned_binned_raw_samples' ...
    , 'files_containing', select_files ...
  );

  labs = aligned_outs.labels';
  ib = aligned_outs.is_in_bounds;
  is_fix = aligned_outs.is_fixation;
  t = aligned_outs.t;

  prune( bfw.get_region_labels(labs) );

end

plot_p = fullfile( bfw.dataroot, 'plots', datestr(now, 'mmddyy') );

%%  

usedat = double( ib & is_fix );
uselabs = addcat( labs', {'stim_roi', 'stim_oob'} );

use_exclusive_bounds = true;

make_exclusive = cshorzcat( ...
  cellfun( @(x) sprintf('face_padded_%s', x), {'large', 'medium', 'small'}, 'un', 0 ) ...
  , 'face' ...
);

if ( use_exclusive_bounds )
  usedat = bfw.get_exclusive_bounds( usedat, uselabs, make_exclusive, 'uuid' );
%   usedat = bfw.get_exclusive_bounds( usedat, uselabs, {'eyes_nf', 'face'}, 'uuid' );
end

stim_t0 = t == 0;
assert( nnz(stim_t0) == 1 );
is_ib_t0 = logical( usedat(:, stim_t0) );

mask = fcat.mask( uselabs ...
  , @find, csunion('eyes_nf', make_exclusive) ...
);

[newdat, newlabs] = bfw.realign_bounds_to_stim_roi( usedat, uselabs', is_ib_t0, 'uuid', mask );

assert_ispair( newdat, newlabs );

%%  fix

t_ind = t >= 0 & t <= 5;
subset_t = t(t_ind);

fixdat = logical( newdat(:, t_ind) );

[nfix, totaldur] = bfw.get_fix_info_from_bounds( fixdat, subset_t );

%% pad small med large

subdir = 't1';

plabs = newlabs';
pdat = newdat;

do_save = true;
per_run = false;
is_padded = false;

I = findall( plabs, 'stim_roi' );

all_keep = [];

for i = 1:numel(I)
  all_keep = union( all_keep, find(plabs, {'in_bounds_face', 'in_bounds_eyes_nf'}, I{i}) );
end

if ( is_padded )
  mask = fcat.mask( plabs, all_keep ...
    , @findnone, '10112018_position_1.mat'...
    , @findnone, {'stim_on_eyes_nf', 'stim_on_not_eyes_nf', 'stim_on_face'} ...
    , @find, {'m1'} ...
    , @find, 'stim on in bounds' ...
  );
  subp_shape = [3, 1];
else
  mask = fcat.mask( plabs, all_keep ...
  , @findnone,  '10112018_position_1.mat'...
  , @find,      {'stim_on_face', 'stim_on_not_face'} ...
  , @find,      'm1' ...
);

  subp_shape = [2, 1];
end

[y, I] = keepeach( plabs', {'unified_filename', 'stim_type', 'stim_roi', 'roi'}, mask );

ps = rowmean( pdat, I );
summary_fix = rowmean( nfix, I );
summary_dur = rowmean( totaldur, I );

if ( ~per_run ), collapsecat( y, 'unified_filename' ); end

fig_cats = { 'unified_filename', 'region', 'roi', 'task_type' };
fig_I = findall( y, fig_cats );
figs = arrayfun( @(x) figure(x), 1:4, 'un', 0 );

for idx = 1:numel(fig_I)
  ind = fig_I{idx};
  sub_ps = ps(ind, :);

  pl = plotlabeled.make_common( 'fig', figs{1} );
  pl.add_errors = false;
  pl.x = t;
  pl.y_lims = [0, 1];
  pl.smooth_func = @(x) smooth(x, 5);
  pl.add_smoothing = false;
  pl.shape = subp_shape;

  gcats = { 'stim_type', 'unified_filename' };
  pcats = { 'stim_roi', 'task_type', 'roi' };

  axs = pl.lines( sub_ps, y(ind), gcats, pcats );

  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, 0 );

  %
  %
  % bar percent

  t_ind = t >= 0;
  t_meaned = nanmean( ps(ind, t_ind), 2 ) * 100;

  pl = plotlabeled.make_common( 'fig', figs{2} );
  pl.x_tick_rotation = 0;
  pl.shape = subp_shape;
  
  xcats = { 'stim_type', 'looks_by' };
  gcats = { 'task_type', 'unified_filename' };
  pcats = { 'stim_roi', 'roi' };
  
  bar_labs = prune( y(ind) );

  axs2 = pl.bar( t_meaned, bar_labs, xcats, gcats, pcats );
  
  %
  %
  % bar fix / duration
  
  pl.fig = figs{3};
  axs3 = pl.bar( summary_fix(ind), bar_labs, xcats, gcats, pcats );
  shared_utils.plot.ylabel( axs3, 'N-fixations' );
  
  pl.fig = figs{4};
  axs4 = pl.bar( summary_dur(ind), bar_labs, xcats, gcats, pcats );
  shared_utils.plot.ylabel( axs4, 'Total duration' );

  if ( do_save )
    plt_spec = dsp3.nonun_or_all( bar_labs, fig_cats );
    
    run_p = ternary( per_run, 'per_run', 'across_runs' );
    padded_p = ternary( is_padded, 'padded', 'binary' );
    
    common_inputs = { fullfile(plot_p, subdir, run_p, padded_p), bar_labs, plt_spec };
    
    dsp3.req_savefig( figs{1}, common_inputs{:}, 'lines__' );
    dsp3.req_savefig( figs{2}, common_inputs{:}, 'bar__' );
    dsp3.req_savefig( figs{3}, common_inputs{:}, 'nfix__' );
    dsp3.req_savefig( figs{4}, common_inputs{:}, 'totaldur__' );
  end
end
