function plot_positional_info(distances, labels, varargin)

assert_ispair( distances, labels );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.mask_func = @(l, m) m;
defaults.before_plot_func = @(varargin) deal(varargin{1:nargout});
defaults.fcats = {};
defaults.pcats = {};
defaults.gcats = {};
defaults.xcats = {};
defaults.add_points = false;
defaults.points_are = {};

params = bfw.parsestruct( defaults, varargin );
mask = params.mask_func( labels, rowmask(labels) );

plot_per_monkey( distances, labels', mask, 'distances', params );

end

function plot_per_monkey(data, labels, mask, kind, params)

fcats = union( {'id_m1', 'id_m2', 'looks_by', 'region'}, params.fcats );
xcats = union( {'target_roi', 'source_roi'}, params.xcats );
gcats = union( {'stim_type'}, params.gcats );
pcats = union( {'task_type', 'region', 'id_m1', 'id_m2', 'looks_by'} ...
 , params.pcats );

plot_bars( data, labels', mask, fcats, xcats, gcats, pcats, kind, params );

end

function plot_bars(data, labels, mask, fcats, xcats, gcats, pcats, kind, params)

fig_I = findall_or_one( labels, fcats, mask );
specificity = unique( [fcats(:)', xcats(:)', gcats(:)', pcats(:)'] );

for i = 1:numel(fig_I)
  [d, l] = params.before_plot_func( data, labels', specificity, fig_I{i} );

  pl = plotlabeled.make_common();
  pl.fig = gcf();
  pl.x_tick_rotation = 30;
  pl.add_points = params.add_points;
  pl.points_are = params.points_are;
  pl.marker_size = 4;
  pl.marker_type = 'ko';
  pl.connect_points = ~isempty( params.points_are );
  pl.main_line_width = 2;

  axs = pl.bar( d, l, xcats, gcats, pcats );
  
  if ( params.do_save )
    save_p = get_save_p( params, kind );
    shared_utils.plot.fullscreen( pl.fig );
    dsp3.req_savefig( pl.fig, save_p, l', fcats, params.prefix );
  end
end

end

function save_p = get_save_p(params, kind)

subdir = params.base_subdir;
save_p = bfw_st.stim_summary_plot_p( params, kind, subdir );

end