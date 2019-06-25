function plot_fix_info_over_time(fix_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.bar_width = 2;
defaults.y_lims = [];
defaults.mask = rowmask( fix_outs.labels );

params = bfw.parsestruct( defaults, varargin );

labels = fix_outs.labels';

handle_labels( labels );
mask = get_base_mask( labels, params.mask );

plot_interleaved_bar( fix_outs, labels, mask, params, 'total_duration' );
plot_interleaved_bar( fix_outs, labels, mask, params, 'n_fix' );

end

function plot_interleaved_bar(fix_outs, labels, mask, params, kind)

stop_col = find( strcmp(fix_outs.fix_info_key, kind) );
assert( ~isempty(stop_col), 'No key matched "%s".', kind );

y_lims = params.y_lims;

if ( strcmp(kind, 'total_duration') && isempty(y_lims) )
  y_lims = [0, 10e3];
end

bar_width = params.bar_width;

figs_are = { 'session' };
pcats = { 'session', 'run_number', 'region', 'block_design' };
gcats = { 'stim_type' };

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
  
  axs = gobjects( size(p_I) );
  has_leg = containers.Map();
  
  vert_lines = cell( size(p_I) );
  horz_lines = cell( size(p_I) );

  for j = 1:numel(p_I)
    ax = bfw.subplot( sub_shape, j );
    cla( ax );
    axs(j) = ax;
    hold( ax, 'on' );
    
    if ( ~isempty(y_lims) )
      ylim( ax, y_lims );
    end

    xlim( ax, [-10, 310] );
    
    panel_ind = p_I{j};
    [g_I, g_C] = findall( labels, gcats, panel_ind );
    
    for k = 1:numel(g_I)
      group_ind = g_I{k};
      stim_t = g_C{1, k};
      
      if ( strcmp(stim_t, 'stim') )
        color = 'r';
      else
        color = 'b';
      end
      
      if ( strcmp(kind, 'next_fixation') )
        x_coords = fix_outs.next_fixation_start_times(group_ind);
      else
        x_coords = fix_outs.relative_start_times(group_ind);
      end

      y_coords = fix_outs.fix_info(group_ind, stop_col);
      trial_starts = fix_outs.trial_starts(group_ind);
      image_offsets = fix_outs.image_offsets(group_ind);

      for h = 1:numel(x_coords)        
        rect = [ x_coords(h), 0, x_coords(h)+bar_width, y_coords(h) ];
        
%         hs = bfw.plot_rect_as_lines( ax, rect );
%         set( hs, 'linewidth', 1.5 );
%         set( hs, 'color', color );

        [xs, ys] = bfw.rect2verts( rect );
        hs = patch( ax, xs, ys, color );
        
        if ( ~isKey(has_leg, stim_t) )
          has_leg(stim_t) = hs(1);
        end
      end
      
      vert_lines{j} = [ vert_lines{j}; unique(trial_starts) ];
      horz_lines{j} = [ horz_lines{j}; unique(image_offsets) ];
    end
    
    titles_are = { 'session', 'run_number', 'stim_frequency', 'region', 'block_design' };
    
    title_labs = fcat.strjoin( combs(labels, titles_are, panel_ind) );
    title_labs = strrep( title_labs, '_', ' ' );
    
    title( ax, title_labs );
  end
  
  shared_utils.plot.match_ylims( axs );
  ylabel( axs(1), strrep(kind, '_', ' ') );
  
  for j = 1:numel(axs)
    start_hs = shared_utils.plot.add_vertical_lines( axs(j), vert_lines{j}, 'k' );
    set( start_hs, 'linewidth', 1 );

    stop_hs = shared_utils.plot.add_vertical_lines( axs(j), horz_lines{j}, 'k--' );
    set( stop_hs, 'linewidth', 0.5 );
  end
  
  leg_entries = keys( has_leg );
  leg_handles = values( has_leg );
  legend( horzcat(leg_handles{:}), leg_entries );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    plt_labs = prune( labels(f_I{i}) );
    
    save_p = get_save_p( params, kind );
    dsp3.req_savefig( fig, save_p, plt_labs, figs_are, 'bars' );
  end
end


end

function plot_bar(fix_outs, labels, mask, params, kind)

stop_col = find( strcmp(fix_outs.fix_info_key, kind) );
assert( ~isempty(stop_col), 'No key matched "%s".', kind );

if ( strcmp(kind, 'total_duration') )
  y_lims = [0, 10e3];
else
  y_lims = [];
end

figs_are = { 'session' };
pcats = { 'session', 'run_number', 'stim_type' };

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
  
  axs = gobjects( size(p_I) );

  for j = 1:numel(p_I)
    ax = bfw.subplot( sub_shape, j );
    cla( ax );
    axs(j) = ax;
    
    hold( ax, 'on' );
    
    panel_ind = p_I{j};
    
    if ( strcmp(kind, 'next_fixation') )
      x_coords = fix_outs.next_fixation_start_times(panel_ind);
    else
      x_coords = fix_outs.relative_start_times(panel_ind);
    end
    
    y_coords = fix_outs.fix_info(panel_ind, stop_col);
    
    stim_t = p_C(3, j);
    if ( strcmp(stim_t, 'stim') )
      color = 'r';
    else
      color = 'b';
    end
    
    bar_width = 2;
    
    if ( ~isempty(y_lims) )
      ylim( ax, y_lims );
    end
    
    xlim( ax, [-10, 310] );
    
    if ( strcmp(kind, 'next_fixation') )
      h = bar( ax, x_coords + bar_width, y_coords, color, 'BarWidth', bar_width );
      
      stim_starts = fix_outs.relative_start_times(panel_ind);
      shared_utils.plot.add_vertical_lines( ax, stim_starts );
    else
      for k = 1:numel(x_coords)
        rect = [ x_coords(k), 0, x_coords(k)+bar_width, y_coords(k) ];
        hs = bfw.plot_rect_as_lines( ax, rect );
        set( hs, 'linewidth', 1.5 );
        set( hs, 'color', color );
      end
      
%       h = bar( ax, x_coords+bar_width*2, y_coords, color, 'BarWidth', bar_width );
      
      trial_starts = fix_outs.trial_starts(panel_ind);
      image_offsets = fix_outs.image_offsets(panel_ind);
      
      start_hs = shared_utils.plot.add_vertical_lines( ax, unique(trial_starts), 'k' );
      set( start_hs, 'linewidth', 1 );
      
      stop_hs = shared_utils.plot.add_vertical_lines( ax, unique(image_offsets), 'k--' );
      set( stop_hs, 'linewidth', 0.5 );
    end
    
    titles_are = { 'session', 'run_number', 'stim_frequency', 'stim_type' };
    
    title_labs = fcat.strjoin( combs(labels, titles_are, panel_ind) );
    title_labs = strrep( title_labs, '_', ' ' );
    
    title( ax, title_labs );
  end
  
  shared_utils.plot.match_ylims( axs );
  
  ylabel( axs(1), strrep(kind, '_', ' ') );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    plt_labs = prune( labels(f_I{i}) );
    
    save_p = get_save_p( params, kind );
    dsp3.req_savefig( fig, save_p, plt_labs, figs_are, 'bars' );
  end
end

end

function plot_dur(fix_outs, labels, mask, params, kind)

switch ( kind )
  case 'total_duration'
    stop_col = 2;
  case 'next_fixation'
    stop_col = 3;
  otherwise
    error( 'Unrecognized kind: "%s".', kind );
end

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
  
  axs = gobjects( size(p_I) );

  for j = 1:numel(p_I)
    ax = bfw.subplot( sub_shape, j );
    cla( ax );
    axs(j) = ax;
    
    hold( ax, 'on' );
    
    panel_ind = p_I{j};
    
    leg_handles = gobjects( 0 );
    leg_entries = {};
    
    for k = 1:numel(panel_ind)
      stim_ind = panel_ind(k);
      
      stim_t = combs( labels, 'stim_type', stim_ind );

      if ( strcmp(stim_t, 'stim') )
        color = 'r';
      else
        color = 'b';
      end
      
      start_t = fix_outs.relative_start_times(stim_ind);
      stop_t = start_t + fix_outs.fix_info(stim_ind, stop_col) / 1e3;
      
      y_coords = [1, 1];
      
      hs(k) = plot( ax, [start_t, stop_t], y_coords, color );
      
      set( hs(k), 'linewidth', 2 );
      
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
  
  shared_utils.plot.match_ylims( axs );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    plt_labs = prune( labels(f_I{i}) );
    
    save_p = get_save_p( params, kind );
    dsp3.req_savefig( fig, save_p, plt_labs, figs_are );
  end
end

end

function plot_n_fix(fix_outs, labels, mask, params)

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
  
  axs = gobjects( size(p_I) );

  for j = 1:numel(p_I)
    ax = bfw.subplot( sub_shape, j );
    cla( ax );
    axs(j) = ax;
    
    hold( ax, 'on' );
    
    panel_ind = p_I{j};
    
    leg_handles = gobjects( 0 );
    leg_entries = {};
    
    for k = 1:numel(panel_ind)
      stim_ind = panel_ind(k);
      
      stim_t = combs( labels, 'stim_type', stim_ind );

      if ( strcmp(stim_t, 'stim') )
        color = 'r';
      else
        color = 'b';
      end
      
      use_t = fix_outs.relative_start_times(stim_ind);
      plot_dat = fix_outs.fix_info(stim_ind, 1);
      
      hs(k) = plot( ax, use_t, plot_dat, sprintf('%so', color) );
      
      add_stim_leg = strcmp(stim_t, 'stim') && ~any(strcmp(leg_entries, 'stim'));
      add_sham_leg = strcmp(stim_t, 'sham') && ~any(strcmp(leg_entries, 'sham'));
      
      if ( add_stim_leg || add_sham_leg )
        leg_handles(end+1) = hs(k);
        leg_entries(end+1) = stim_t;
      end
    end
    
    titles_are = { 'session', 'run_number', 'stim_frequency' };
    
    title_labs = fcat.strjoin( combs(labels, titles_are, panel_ind), ' | ' );
    title_labs = strrep( title_labs, '_', ' ' );
    
    title( ax, title_labs );
    xlim( ax, [0, 300] );
    
    legend( leg_handles, leg_entries );
  end
  
  shared_utils.plot.match_ylims( axs );
  ylabel( axs(1), 'N Fixations' );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    plt_labs = prune( labels(f_I{i}) );
    
    save_p = get_save_p( params, 'n_fix' );
    dsp3.req_savefig( fig, save_p, plt_labs, figs_are );
  end
end

end

function save_p = get_save_p(params, kind)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_fix_info_over_time' ...
  , dsp3.datedir, params.base_subdir, kind );

end

function labels = handle_labels(labels)

bfw_it.add_stim_frequency_labels( labels );
bfw_it.decompose_image_id_labels( labels );
bfw_it.add_run_number( labels );

end

function mask = get_base_mask(labels, mask)

mask = bfw_it.find_non_error_runs( labels, mask );

end