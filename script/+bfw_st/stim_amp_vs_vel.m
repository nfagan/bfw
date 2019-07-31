function stim_amp_vs_vel(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw.set_dataroot( bfw_st.make_data_root(defaults.config) );
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

session_types = bfw.get_sessions_by_stim_type( conf, 'cache', true );

eyes_sessions = session_types.m1_exclusive_sessions;
face_sessions = session_types.m1_radius_sessions;

select_files = csunion( eyes_sessions, face_sessions );

plot_p = fullfile( bfw.dataroot(conf), 'plots', 'stim_summary', datestr(now, 'mmddyy') );

%%

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

prune( bfw.get_region_labels(labs) );
prune( bfw.add_monk_labels(labs) );

%%

do_save = params.do_save;
subdir = 'amp_vs_vel';

pl = plotlabeled();
pl.marker_size = 10;
pl.shape = [2, 1];
pl.panel_order = { 'free_viewing', 'nonsocial_control' };

pltlabs = labs';

X = amps;
Y = vels;

mask = fcat.mask( pltlabs ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
);

if ( isempty(mask) ), fprintf( '\n None matched.\n\n' ); end

specs = { {}, {'id_m1'} };

for idx = 1:numel(specs)

  fcats = { 'region', 'stim_protocol' };
  gcats = { 'stim_type' };
  pcats = { 'task_type', 'region', 'stim_protocol' };
  
  fcats = [ fcats, specs{idx} ];
  pcats = [ pcats, specs{idx} ];

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

    xlim( axs, [0, 1200] );

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
end

end