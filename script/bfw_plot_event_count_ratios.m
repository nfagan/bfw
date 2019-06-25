function bfw_plot_event_count_ratios(lin_events, varargin)

plot_defaults = bfw.get_common_plot_defaults();
make_defaults = bfw.get_common_make_defaults();

defaults = shared_utils.struct.union( plot_defaults, make_defaults );
params = bfw.parsestruct( defaults, varargin );

lin_params = shared_utils.struct.intersect( params, make_defaults );

if ( nargin < 1 )
  lin_events = bfw_linearize_events( lin_params );
end

%%

sessions = bfw.get_sessions_by_stim_type( params.config, 'cache', true );

%%

non_nan = bfw_non_nan_linearized_event_times( lin_events );
non_overlapping = bfw_exclusive_events_from_linearized_events( lin_events );

ok_events = intersect( non_nan, non_overlapping );

%%

event_labs = lin_events.labels';

mask = fcat.mask( event_labs, ok_events ...
  , @find, 'm1' ...
);

[summarized_labs, event_I] = keepeach( event_labs', 'session', mask );

cts = [];
count_labs = fcat();
stp = 1;

% any_object1 = {'top_object1', 'bottom_object1'};
% any_object2 = {'top_object2', 'bottom_object2'};
% eye_roi_name = 'top_eyes';
% mouth_roi_name = 'bottom_mouth';

any_object1 = { 'left_nonsocial_object' };
any_object2 = { 'right_nonsocial_object' };

% any_object1 = { 'right_nonsocial_object' };
% any_object2 = { 'left_nonsocial_object' };
eye_roi_name = 'eyes_nf';
mouth_roi_name = 'mouth';

comparisons = { ...
    {{'face'}, [any_object1, any_object2]} ...
    %{
  , {{'top_eyes'}, {'top_object1', 'top_object2'}} ...
    %}
  , {{eye_roi_name}, {mouth_roi_name}} ...
  , {any_object1, any_object2} ...
  %{
  , {{'top_eyes'}, {'bottom_object1', 'bottom_object2'}} ...
  %}
  , {{eye_roi_name}, [any_object1, any_object2]} ...
};

comparison_names = { 'face_v_object', 'eyes_v_mouth', 'obj1_vs_obj2', 'eyes_vs_object'};

assert( numel(comparison_names) == numel(comparisons) );

for i = 1:numel(event_I)
  for j = 1:numel(comparisons)
    roi1 = comparisons{j}{1};
    roi2 = comparisons{j}{2};
    
    roi1_lab = strjoin( roi1, '_' );
    roi2_lab = strjoin( roi2, '_' );
    
%     setcat( summarized_labs, 'roi', sprintf('%s_over_%s', roi1_lab, roi2_lab) );
    setcat( summarized_labs, 'roi', comparison_names{j} );
    append( count_labs, summarized_labs, i );
    
    cts1 = numel( findor(event_labs, roi1, event_I{i}) );
  	cts2 = numel( findor(event_labs, roi2, event_I{i}) );
    
    if ( cts2 == 0 )
      cts(stp, 1) = nan;
    else
      cts(stp, 1) = cts1 / cts2;
    end
    
    stp = stp + 1;
  end
end

%%

pl = plotlabeled.make_common();
mask = fcat.mask( count_labs ...
  , @findor, sessions.no_stim_sessions ...
);
pl.color_func = @winter;

axs = pl.violinalt( cts(mask), count_labs(mask), 'roi', {} );
ylabel( axs(1), 'Relative number of events' );

% axs = pl.boxplot( cts(mask), count_labs(mask), 'roi', {} );
hold( axs, 'on' );
shared_utils.plot.add_horizontal_lines( axs, 1 );

if ( params.do_save )
  save_p = get_save_p( params );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prune(count_labs(mask)), 'roi' );
end

end

function p = get_save_p(params)

p = fullfile( bfw.dataroot(params.config), 'plots', 'event_count_ratios' ...
  , dsp3.datedir, params.base_subdir );

end