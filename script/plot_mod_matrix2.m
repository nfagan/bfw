import shared_utils.io.fload;

conf = bfw.config.load();

spike_p = bfw.get_intermediate_directory( 'modulation_type' );
event_spike_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
spike_mats = shared_utils.io.find( spike_p, '.mat' );

psth = Container();
full_psth = Container();
raster = Container();
null_psth = Container();

got_t = false;

for i = 1:numel(spike_mats)
  fprintf( '\n %d of %d', i, numel(spike_mats) );
  
  spikes = shared_utils.io.fload( spike_mats{i} );
      
  if ( spikes.is_link ), continue; end
  
  c_full_psth = shared_utils.io.fload( fullfile(event_spike_p, spikes.unified_filename) );
  
  if ( isfield(c_full_psth, 'is_link') && c_full_psth.is_link )
    c_full_psth = shared_utils.io.fload( fullfile(event_spike_p, c_full_psth.data_file) );
  end
  if ( ~full_psth.contains(spikes.psth('session_name')) )
    full_psth = full_psth.append( c_full_psth.psth );
  end
  
  spk_params = spikes.params;
  
  if ( ~got_t )
    psth_t = spikes.psth_t;
    raster_t = spikes.raster_t;
    got_t = true;
  end
  
  psth = psth.append( spikes.psth );
  raster = raster.append( spikes.raster );
  null_psth = null_psth.append( spikes.null );
end

psth_info_str = sprintf( 'step_%d_ms', spk_params.psth_bin_size * 1e3 );

%%

c_psth = full_psth.rm( 'unit_uuid__NaN' );
c_null_psth = null_psth.rm( 'unit_uuid__NaN' );

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;

N = 1000;

[modulation, sig] = ...
  bfw.analysis.permute_population_modulation( c_psth, c_null_psth, psth_t, N, window_pre, window_post );

%%  n + percent cells by type

to_stats = psth;

percs_for = { 'cell_type' };
percs_c = to_stats.pcombs( percs_for );

stats_each = { 'region', 'looks_to', 'looks_by' };

p_sig = to_stats.for_each( stats_each, @percentages, percs_for, percs_c );
n_sig = to_stats.for_each( stats_each, @counts, percs_for, percs_c );

for i = 1:2
  
if ( i == 1 )
  use = p_sig;
  fname = 'percent_by_type';
  lab = '% Modulated cells';
else
  use = n_sig;
  fname = 'number_by_type';
  lab = 'N modulated cells';
end

plt = use({'mutual', 'm1'});

plt = plt.replace( 'm1', 'exclusive' );

pl = ContainerPlotter();
pl.y_label = lab;

f = figure(1); clf( f );

bar( pl, plt, 'cell_type', {'looks_to', 'looks_by'}, 'region' );

kind = 'by_type';

date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );

end


%%

a = sig;
a = a.require_fields( 'modulation_type' );
a('modulation_type') = 'eyes_over_face';
b = set_data( a, a.data(:, 2) );
b('modulation_type') = 'mutual_over_exclusive';
a.data = a.data(:, 1);

to_stats = [ a; b];

stats_each = { 'modulation_type', 'region' };

alpha = 0.025;

n_sig = to_stats.each1d( stats_each, @(x) sum(x <= alpha) );
p_sig = to_stats.each1d( stats_each, @(x) perc(x <= alpha) );

pl = ContainerPlotter();

f = figure( 1 );
clf( f );

bar( pl, p_sig, 'modulation_type', 'region', {'looks_to', 'looks_by'} );

%%

all_c = modulation.pcombs( {'region'} );

corr_results = Container();

for j = 1:size(all_c, 1)

  plt_psth = modulation(all_c(j, :));
  plt_sig = sig(all_c(j, :));

  [I, C] = plt_psth.get_indices( {'unit_uuid', 'channel'} );

  f = figure(1); clf( f );

  colors = containers.Map();
  colors( 'bla' ) = 'r';
  colors( 'accg' ) = 'b';
  colors( 'ofc' ) = 'g';
  colors( 'dmpfc' ) = 'm';

  legend_components = containers.Map();

  alpha = 0.025;

  require_significant = '';
  
  sig_data = zeros( numel(I), 2 );
  c_is_sig = false( numel(I), 1 );

  for i = 1:numel(I)
    subset = plt_psth(I{i});
    subset_is_sig = plt_sig(I{i});

    assert( shape(subset, 1) == 1 && shapes_match(subset, subset_is_sig) );

    regs = subset('region');
    assert( numel(regs) == 1 );
    reg = char( regs );

    current_color = colors( reg );

    x_coord = subset.data(2);
    y_coord = subset.data(1);

%     h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;

    ef_is_sig = subset_is_sig.data(1) <= alpha;
    me_is_sig = subset_is_sig.data(2) <= alpha;
    
    current_is_sig = ef_is_sig || me_is_sig;
    
    if ( current_is_sig )
      sig_data(i, :) = [ x_coord, y_coord ];
      c_is_sig(i) = true;
    end
    
    if ( ~(ef_is_sig || me_is_sig) )
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
    end
    if ( ef_is_sig || me_is_sig )
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
    elseif ( ef_is_sig )
      plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 2 ); hold on;
    elseif ( me_is_sig )
      plot( x_coord, y_coord, sprintf('%s+', current_color), 'MarkerFaceColor', 'k', 'markersize', 6 ); hold on;
    end

    if ( ~legend_components.isKey(reg) )
      legend_components(reg) = h;
    end
  end
  
  sig_data = sig_data(c_is_sig, :);
  
  [corr_r, corr_p] = corr( sig_data );
  ps = polyfit( sig_data(:, 1), sig_data(:, 2), 1 );
  res = polyval( ps, [-1, 1] );
  corr_p = corr_p(1, 2);
  corr_r = corr_r(1, 2);
  
  hold on;
  plot( [-1, 1], res );
  
  if ( corr_p <= 0.05 )
    plot( 1, res(2) + 0.05, 'k*' );
  end
  
  corr_results = corr_results.append( set_data(one(plt_psth), [corr_r, corr_p]) );
  % title( 'ACCg' );

  hold on;
  plot( [-1, 1], [0, 0], 'k-' );
  plot( [0, 0], [-1, 1], 'k-' );

  xlabel( 'mutual over exclusive' );
  ylabel( 'eyes over face' );

  ylim( [-1, 1] );
  xlim( [-1, 1] );

  ylim( [-1, 1] );
  xlim( [-1, 1] );

  axis( 'square' );

  leg_keys = legend_components.keys();
  leg_elements = gobjects( 1, numel(leg_keys) );

  for i = 1:numel(leg_keys)
    leg_elements(i) = legend_components(leg_keys{i}); 
  end

  legend( leg_elements, leg_keys );

  %

  f2 = figure(2); clf( f2 );
  ax2 = gca();
  
  f3 = figure(3); clf( f3 );
  ax3 = gca();
  
  cmbs_each = { 'region' };  
  reg_combs = plt_psth.pcombs( cmbs_each );
  
%   n_bins = 20; 
  n_bins = -1:0.1:1;
  ylims = [0, 30];
  
  for i = 1:size(reg_combs, 1)
    ind = plt_psth.where( reg_combs(i, :) );
    X = plt_psth.data(ind, 1);
    Y = plt_psth.data(ind, 2);
    
    hist_sig1 = signrank( X );
    hist_sig2 = signrank( Y );
    med1 = median( X );
    med2 = median( Y );
    
    [categories, ~, ids] = categorical( plt_psth.labels.keep(ind) );
    
    cmb_inds = cellfun( @(x) find(strcmp(ids, x)), cmbs_each );    
    categories = categories(:, cmb_inds);
    
    set( ax2, 'nextplot', 'add' );
    set( ax3, 'nextplot', 'add' );
    
    reg = reg_combs{i, find(strcmp(cmbs_each, 'region'))};
    
    histogram( ax2, X, n_bins, 'facecolor', colors(reg) );
    xlim( ax2, [-1, 1] );
    ylim( ax2, ylims );
    xlabel( ax2, 'Eyes over Face' );
    plot( ax2, [med1; med1], ylims, 'k-' );
    
    if ( hist_sig1 <= 0.05 )
      plot( ax2, med1+0.05, ylims(2), 'k*' );
    end
    
    histogram( ax3, Y, n_bins, 'facecolor', colors(reg) );
    xlim( ax3, [-1, 1] );
    ylim( ax3, ylims );
    xlabel( ax3, 'Mutual over Exclusive' );
    plot( ax3, [med2; med2], ylims, 'k-' );
    
    if ( hist_sig2 <= 0.05 )
      plot( ax3, med2+0.05, ylims(2), 'k*' );
    end
    
    legend( ax2, reg );
    legend( ax3, reg );
  end

  %   save
  kind = 'population_matrix_from_null';

  fname = strjoin( plt_psth.flat_uniques({'region'}), '_' );
  fname = sprintf( 'population_matrix_%s_%s', require_significant, fname );
  fname_hist1 = sprintf( '%s_hist_eyes_face', fname );  
  fname_hist2 = sprintf( '%s_hist_mut_excl', fname );
  
  date_dir = datestr( now, 'mmddyy' );
  save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
  save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
  shared_utils.io.require_dir( save_plot_p );
  
  formats = { 'epsc', 'png', 'fig' };
  
  shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), formats, true );
  shared_utils.plot.save_fig( f2, fullfile(save_plot_p, fname_hist1), formats, true );
  shared_utils.plot.save_fig( f3, fullfile(save_plot_p, fname_hist2), formats, true );
  
end

