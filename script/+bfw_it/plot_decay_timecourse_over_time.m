function plot_decay_timecourse_over_time(bounds, t, start_times, labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

assert_ispair( bounds, labels );
assert_ispair( start_times, labels );
validateattributes( t, {'double', 'single'}, {'vector', 'numel', size(bounds, 2)} ...
  , mfilename, 't' );

handle_labels( labels );
mask = get_base_mask( labels );

plot_per_run( bounds, t, start_times, labels, mask, params );

end

function plot_per_run(bounds, t, start_times, labels, mask, params)

%%

figs_are = { 'session' };
pcats = { 'session', 'run_number' };

f_I = findall( labels, figs_are, mask );
fig = gcf();

for i = 1:numel(f_I)

  [p_I, p_C] = findall( labels, pcats, f_I{i} );
  
  run_numbers = bfw_it.parse_run_numbers( p_C(2, :) );
  [~, sorted_I] = sort( run_numbers );
  p_I = p_I(sorted_I);
  p_C = p_C(:, sorted_I);
  
  use_cols = 2;
  use_rows = ceil( numel(p_I) / use_cols );
  sub_shape = [ use_rows, use_cols ];
  
  clf( fig );

  for j = 1:numel(p_I)
    ax = bfw.subplot( sub_shape, j );
    cla( ax );
    
    hold( ax, 'on' );
    ylim( ax, [0, 1] );
    
    panel_ind = p_I{j};
    
    leg_handles = gobjects( 0 );
    leg_entries = {};
    
    for k = 1:numel(panel_ind)
      stim_ind = panel_ind(k);
      t_series = t + start_times(stim_ind);
      current_bounds = bounds(stim_ind, :);
      
      stim_t = combs( labels, 'stim_type', stim_ind );
      plot_data = smoothdata( current_bounds, 'smoothingfactor', 0.5 );

      if ( strcmp(stim_t, 'stim') )
        color = 'r';
      else
        color = 'b';
      end
      
      first_t = t_series(1);
      last_t = t_series(end);
      
      stim_ts(k) = stim_t;
      
      hs(k) = plot( ax, t_series, plot_data, color );
      shared_utils.plot.add_vertical_lines( ax, first_t );
      
      add_stim_leg = strcmp(stim_t, 'stim') && ~any(strcmp(leg_entries, 'stim'));
      add_sham_leg = strcmp(stim_t, 'sham') && ~any(strcmp(leg_entries, 'sham'));
      
      if ( add_stim_leg || add_sham_leg )
        leg_handles(end+1) = hs(k);
        leg_entries(end+1) = stim_t;
      end
    end
    
    title_labs = fcat.strjoin( combs(labels, {'session', 'run_number'}, panel_ind) );
    title_labs = strrep( title_labs, '_', ' ' );
    
    title( ax, title_labs );
    xlim( ax, [0, 300] );
    
    legend( leg_handles, leg_entries );
  end
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    plt_labs = prune( labels(f_I{i}) );
    
    save_p = get_save_p( params );
    dsp3.req_savefig( fig, save_p, plt_labs, figs_are );
  end
end

end

function save_p = get_save_p(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_decay_over_time' ...
  , dsp3.datedir, params.base_subdir );

end

function labels = handle_labels(labels)

bfw_it.add_stim_frequency_labels( labels );
bfw_it.decompose_image_id_labels( labels );
bfw_it.add_run_number( labels );

end

function mask = get_base_mask(labels)

mask = bfw_it.find_non_error_runs( labels );

end