conf = bfw.set_dataroot( '/Users/Nick/Desktop/bfw' );
base_counts_p = fullfile( bfw.dataroot(conf), 'analyses/spike_lda/reward_gaze_spikes_tree' );

counts_p = fullfile( base_counts_p, 'counts_right_object_only' );
rwd_counts_file = fullfile( counts_p, 'reward_counts.mat' );
rwd_counts = shared_utils.io.fload( rwd_counts_file );
replace( rwd_counts.labels, 'acc', 'accg' );

%%

psth = rwd_counts.psth;
fr = psth .* (1 / uniquetol(diff(rwd_counts.t)));

base_mask = fcat.mask( rwd_counts.labels ...
  , @findnone, 'reward-NaN' ...
  %{
  , @find, 'unit_uuid__1607' ...
  %}
);

fcats = { 'unit_uuid', 'region', 'session' };
do_save = true;

fig_I = findall_or_one( rwd_counts.labels, fcats, base_mask );

for i = 1:numel(fig_I)
  shared_utils.general.progress( i, numel(fig_I) );
  
  mask_func = @(l, m) fcat.mask(l, intersect(m, fig_I{i}) );
  
  pcats = {'unit_uuid', 'event-name', 'region'};
  gcats = 'reward-level';
  spec = csunion( pcats, gcats );

  plt_labels = bfw_cs.plot_psth( fr, rwd_counts.labels', rwd_counts.t ...
    , 'mask_func', mask_func ...
    , 'smooth_func', @(x) smoothdata(x, 'smoothingfactor', 0.75) ...
    , 'pcats', pcats ...
    , 'gcats', gcats ...
    , 'add_reward_size_regression', true ...
    , 'add_errors', false ...
    , 'panel_order', {'cs_target_acquire', 'cs_delay', 'cs_reward'} ...
  );

  if ( do_save )
    save_spec = intersect( spec, {'unit_uuid', 'region'} );
    
    save_p = fullfile( bfw.dataroot(conf), 'plots', 'cs-psth' ...
      , dsp3.datedir, char(combs(plt_labels, 'region')) );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, plt_labels, save_spec );
  end
end