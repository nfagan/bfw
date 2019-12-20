function run_stim_amp_vs_vel_stats(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

amp_vel_outs = bfw_st.load_amp_vel( 'config', conf );
stat_outs = bfw_st.stim_amp_vs_vel_stats( amp_vel_outs );

%%

row_cats = { 'region', 'id_m1', 'task_type' };
row_labels = cellstr( stat_outs.labels, row_cats );
row_labels = fcat.strjoin( row_labels', ' | ' );

tbl = fcat.table( stat_outs.ps, row_labels, {'p'} );

%%

save_p = fullfile( bfw.dataroot(conf), 'analyses', 'stim_amp_vs_vel', dsp3.datedir() );
dsp3.req_writetable( tbl, save_p, stat_outs.labels, row_cats );

end