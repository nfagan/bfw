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

%%  remove non-existent units

c_psth = full_psth.rm( 'unit_uuid__NaN' );
c_null_psth = null_psth.rm( 'unit_uuid__NaN' );
c_at_psth = psth.rm( 'unit_uuid__NaN' );

missing_unit_ids = setdiff( full_psth('unit_uuid'), c_null_psth('unit_uuid') );

if ( ~isempty(missing_unit_ids) )
  fprintf( '\n Warning: %d units did not have events associated with them.', numel(missing_unit_ids) );
  c_psth = c_psth.rm( missing_unit_ids );
end

%%  calculate modulation index

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;

N = 1000;

[modulation, sig] = ...
  bfw.analysis.permute_population_modulation( c_psth, c_null_psth, psth_t, N, window_pre, window_post );

%%  subtract null

to_sub_full = c_psth.rm( {'m1_leads_m2', 'm2_leads_m1'} );
to_sub_at = c_at_psth.rm( {'m1_leads_m2', 'm2_leads_m2'} );

psth_sub_null = bfw.subtract_null_psth( to_sub_full, c_null_psth, psth_t, window_pre, window_post, false );
psth_sub_null_at = bfw.subtract_null_psth( to_sub_at, c_null_psth, psth_t, window_pre, window_post, true );

%%  n cells by area

[I, C] = modulation.get_indices({'looks_to', 'looks_by', 'unit_uuid', 'channel'});
%   ensure all indices refer to a single unit
cellfun( @(x) assert(sum(x) == 1), I );

to_count = modulation.each1d( {'looks_to', 'looks_by', 'unit_uuid', 'channel'}, @(x) x(1) );
to_count = to_count.counts( 'region' );

%%  plot cell types by category

by_type = c_null_psth;
by_type = by_type({'mutual', 'm1'});
by_type = by_type.replace( 'm1', 'exclusive' );

[I, C] = by_type.get_indices({'looks_to', 'looks_by', 'unit_uuid', 'channel'});

%   ensure all indices refer to a single unit
cellfun( @(x) assert(sum(x) == 1), I );

stats_each = { 'looks_to', 'looks_by', 'region' };
percs_for = { 'cell_type' };
percs_of = by_type.pcombs( percs_for );

N = by_type.for_each( stats_each, @counts, percs_for, percs_of );
P = by_type.for_each( stats_each, @percentages, percs_for, percs_of );

P = P.rm( 'none' );

pl = ContainerPlotter();
f = figure(1); clf( f );

pl.order_by = { 'pre', 'post', 'pre_and_post', 'none' };

bar( pl, P, 'cell_type', {'looks_to', 'looks_by'}, 'region' );

f2 = FigureEdits( f );
f2.one_legend();

kind = 'Cell-type';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );
fname = kind;

formats = { 'epsc', 'png', 'fig' };

shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), formats, true );

%%  plot cell modulation direction by category

by_mod_dir = psth_sub_null_at;
by_mod_dir = by_mod_dir({'mutual', 'm1'});
% by_mod_dir = by_mod_dir.rm( 'none' );

[I, C] = by_mod_dir.get_indices({'looks_to', 'looks_by', 'unit_uuid', 'channel'});

%   ensure all indices refer to a single unit
cellfun( @(x) assert(sum(x) == 1), I );

stats_each = { 'looks_to', 'looks_by', 'region', 'cell_type' };
percs_for = { 'modulation_direction' };
percs_of = by_mod_dir.pcombs( percs_for );

N = by_mod_dir.for_each( stats_each, @counts, percs_for, percs_of );
P = by_mod_dir.for_each( stats_each, @percentages, percs_for, percs_of );

P = P.rm( 'none' );

pl = ContainerPlotter();
f = figure(1); clf( f );
colormap( 'default' );

pl.order_by = { 'pre', 'post', 'pre_and_post', 'none' };

bar( pl, P, 'modulation_direction', {'looks_to', 'looks_by', 'cell_type'}, {'region'} );

f2 = FigureEdits( f );
f2.one_legend();

kind = 'Cell-type';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );
fname = kind;

formats = { 'epsc', 'png', 'fig' };

% shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), formats, true );


%%  anova -- subtract null

to_anova = psth_sub_null({'m1', 'mutual'});
to_anova = to_anova.replace( 'm1', 'exclusive' );

groups_are = { 'looks_by', 'looks_to' };
[I, C] = to_anova.get_indices( {'unit_uuid', 'channel'} );

to_anova = to_anova.require_fields( {'anova_factor'} );

anova_results = Container();

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  one_unit = to_anova(I{i});
  groups = cellfun( @(x) one_unit(x, :), groups_are, 'un', false );
  [p, t, stats] = anovan( one_unit.data, groups, 'model', 'full', 'display', 'off' );
  [c, means, ~, gnames] = multcompare( stats, 'dimension', 1:2, 'display', 'on' );
  
  gnames = strrep( gnames, 'X1=', '' );
  gnames = strrep( gnames, 'X2=', '' );
  
  subset_c = arrayfun( @(x) gnames{x}, c(:, 1:2), 'un', false );
  rest_c = arrayfun( @(x) x, c(:, 3:end), 'un', false );
  recombined_c = [ subset_c, rest_c ];
  
  x1_sig = p(1) <= .05;
  x2_sig = p(2) <= .05;
  x1_x2_sig = p(3) <= .05;
  
  base_cont = one( one_unit );
  
  post_comparisons_sig = c(:, end) <= .05;
  
  if ( ~any(p <= .05) )
    base_cont('anova_factor') = 'anova__none';
    anova_results = anova_results.append( base_cont );
    continue;
  end
  
  x1_str = strjoin( one_unit(groups_are{1}), ' vs. ' );
  x2_str = strjoin( one_unit(groups_are{2}), ' vs. ' );
  x1_x2_str = strjoin( groups_are, ' X ' );
  
  if ( x1_sig )
    x1_cont = base_cont;
    x1_cont('anova_factor') = x1_str;
    anova_results = anova_results.append( x1_cont );
  end
  
  if ( x2_sig )
    x1_cont = base_cont;
    x1_cont('anova_factor') = x2_str;
    anova_results = anova_results.append( x1_cont );
  end
  
  if ( x1_x2_sig )
    x1_cont = base_cont;
    x1_cont('anova_factor') = x1_x2_str;
    anova_results = anova_results.append( x1_cont );
  end
  
  if ( ~any(post_comparisons_sig) )
    continue;
  end
  
  subset_sig = recombined_c(post_comparisons_sig, :);
  
  for j = 1:size(subset_sig, 1)
    subset_gnames = subset_sig(j, 1:2);
    x1_cont = base_cont;
    x1_cont('anova_factor') = strjoin( subset_gnames, '__' );
    anova_results = anova_results.append( x1_cont );
  end
end

%%
factor_ids = { x1_str, x2_str, x1_x2_str, 'anova__none' };
to_stats = anova_results;
to_stats = to_stats(factor_ids);

f = figure(1); 
clf( f );

pl = ContainerPlotter();
pl.add_legend = false;

count_cat = 'anova_factor';
count_labs = to_stats.pcombs( count_cat );

N = to_stats.for_each( {'region'}, @counts, count_cat, count_labs );
P = to_stats.for_each( {'region'}, @percentages, count_cat, count_labs );

N.labels.labels = strrep( N.labels.labels, 'exclusive', 'excl' );
N.labels.labels = strrep( N.labels.labels, 'mutual', 'mut' );

pl.bar( N, 'anova_factor', 'looks_to', 'region' );

f2 = figure(2);
clf( f2 );

to_stats = anova_results.rm( factor_ids );
count_cat = 'anova_factor';
count_labs = to_stats.pcombs( count_cat );
N = to_stats.for_each( {'region'}, @counts, count_cat, count_labs );

pl.bar( N, 'anova_factor', 'looks_to', 'region' );
%%  n + percent cells by type

to_stats = psth.rm( 'unit_uuid__NaN' );

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
  fprintf( '\n %d of %d', j, size(all_c, 1) );

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
  c_is_sig = true( numel(I), 1 );

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

    ef_is_sig = subset_is_sig.data(1) <= alpha;
    me_is_sig = subset_is_sig.data(2) <= alpha;
    
    sig_data(i, :) = [ x_coord, y_coord ];
    
    current_is_sig = ef_is_sig || me_is_sig;
    
    if ( current_is_sig )
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
    else
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
    end
    
%     if ( ~(ef_is_sig || me_is_sig) )
%       h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
%     end
%     if ( ef_is_sig || me_is_sig )
%       h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
%     elseif ( ef_is_sig )
%       plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 2 ); hold on;
%     elseif ( me_is_sig )
%       plot( x_coord, y_coord, sprintf('%s+', current_color), 'MarkerFaceColor', 'k', 'markersize', 6 ); hold on;
%     end

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
    if ( corr_p < .001 )
      p_str = sprintf( 'p < .001' );
    else
      p_str = sprintf( 'p = %0.3f', corr_p );
    end
    r_str = sprintf( 'r = %0.3f', corr_r );
    full_str = sprintf( '(%s, %s)', r_str, p_str );
    text( 0.75, res(2) - 0.1, full_str );    
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
  ylims = [0, 35];
  
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
      if ( hist_sig1 < .001 )
        p_str = sprintf( 'p < .001' );
      else
        p_str = sprintf( 'p = %0.3f', hist_sig1 );
      end
      text( med1+0.1, ylims(2), p_str, 'parent', ax2 );    
    end
    
    histogram( ax3, Y, n_bins, 'facecolor', colors(reg) );
    xlim( ax3, [-1, 1] );
    ylim( ax3, ylims );
    xlabel( ax3, 'Mutual over Exclusive' );
    plot( ax3, [med2; med2], ylims, 'k-' );
    
    if ( hist_sig2 <= 0.05 )
      plot( ax3, med2+0.05, ylims(2), 'k*' );
      if ( hist_sig2 < .001 )
        p_str = sprintf( 'p < .001' );
      else
        p_str = sprintf( 'p = %0.3f', hist_sig2 );
      end
      text( med2+0.1, ylims(2), p_str, 'parent', ax3 );
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

