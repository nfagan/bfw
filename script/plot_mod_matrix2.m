import shared_utils.io.fload;

conf = bfw.config.load();

spike_p = bfw.get_intermediate_directory( 'modulation_type' );
event_spike_p = bfw.get_intermediate_directory( 'event_aligned_spikes' );
spike_mats = shared_utils.io.find( spike_p, '.mat' );

psth = Container();
full_psth = Container();
raster = Container();
null_psth = Container();
zpsth = Container();

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
%     psth_t = spikes.psth_t;
    psth_t = c_full_psth.psth_t;
    raster_t = spikes.raster_t;
    got_t = true;
  end
  
  psth = psth.append( spikes.psth );
  raster = raster.append( spikes.raster );
  null_psth = null_psth.append( spikes.null );
  zpsth = zpsth.append( spikes.zpsth );
end

psth_info_str = sprintf( 'step_%d_ms', spk_params.psth_bin_size * 1e3 );

%%  remove non-existent units

c_psth = full_psth.rm( 'unit_uuid__NaN' );
c_null_psth = null_psth.rm( 'unit_uuid__NaN' );
c_at_psth = psth.rm( 'unit_uuid__NaN' );
c_z_psth = zpsth.rm( 'unit_uuid__NaN' );

missing_unit_ids = setdiff( full_psth('unit_uuid'), c_null_psth('unit_uuid') );

if ( ~isempty(missing_unit_ids) )
  fprintf( '\n Warning: %d units did not have events associated with them.' ...
    , numel(missing_unit_ids) );
  c_psth = c_psth.rm( missing_unit_ids );
end

%%  z score within condition

z_each = { 'unit_uuid', 'channel', 'looks_to', 'looks_by' };
[I, C] = c_psth.get_indices( z_each );
c_psth = c_psth.require_fields( 'is_z' );
c_psth( 'is_z' ) = 'is_z__true';
new_dat = c_psth.data;

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  c_data = new_dat(I{i}, :);
  means = nanmean( c_data(:) );
  devs = nanstd( c_data(:) );
  
  c_data = (c_data - means) ./ devs;
  
  new_data(I{i}, :) = c_data;
end

%%  calculate modulation index

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;
window_not_minus_null = [-0.1, 0.2];

% new_labs = bfw.reclassify_cells( c_at_psth, c_null_psth, c_z_psth, psth_t, window_pre, window_post, 0.025/2 );
new_labs = c_at_psth.labels;

N = 1000;

% [modulation, sig] = ...
%   bfw.analysis.permute_population_modulation( c_psth, c_null_psth, psth_t, N, window_pre, window_post );

% summary_func = @nanmedian;
summary_func = @nanmean;

is_median = strcmp( func2str(summary_func), 'nanmedian' );
is_minus_null = true;

[modulation, sig] = ...
  bfw.analysis.permute_population_modulation_not_minus_null( c_psth, psth_t, N, window_not_minus_null, summary_func );

data_t = 'population_modulation_index';

if ( is_median )
  data_t = sprintf( '%s_median', base_t );
end

% save_p = fullfile( conf.PATHS.data_root, 'analyses', data_t, datestr(now, 'mmddyy') );
save_p = fullfile( conf.PATHS.data_root, 'analyses', 'population_modulation_index', '021318' );

to_save = struct();
to_save.modulation = modulation;
to_save.sig = sig;
to_save.params = spk_params;

shared_utils.io.require_dir( save_p );

full_fname = fullfile( save_p, 'modulation.mat' );

if ( shared_utils.io.fexists(full_fname) )
  fprintf( '\nNot saving because "%s" already exists.', full_fname );
  all_mods = shared_utils.io.fload( full_fname );
  modulation = all_mods.modulation;
  sig = all_mods.sig;
else
  save( full_fname, 'to_save' );
end

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

by_type = set_labels( c_null_psth, new_labs );
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

kind = 'cell-type';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );
fname = strjoin( flat_uniques(P, stats_each) );

formats = { 'epsc', 'png', 'fig' };

shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), formats, true );

%%  plot cell modulation direction by category

% by_mod_dir = psth_sub_null_at;
by_mod_dir = set_labels( c_null_psth, new_labs );
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

[I, C] = P.get_indices( {'looks_to', 'looks_by'} );

for i = 1:numel(I)
  
plt = P(I{i});

pl = ContainerPlotter();
f = figure(1); clf( f );
colormap( 'default' );

pl.order_by = { 'pre', 'post', 'pre_and_post', 'none' };

bar( pl, plt, 'modulation_direction', {'looks_to', 'looks_by', 'cell_type'}, {'region'} );

pl.y_lim = [0, 100];

f2 = FigureEdits( f );
f2.one_legend();

kind = 'Cell-Direction';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );
fname = strjoin( flat_uniques(plt, stats_each) );

formats = { 'epsc', 'png', 'fig' };

shared_utils.plot.save_fig( f, fullfile(save_plot_p, fname), formats, true );

end

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
  store_is_sig = false( numel(I), 1 );
  store_coords = Container();

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
    
    store_is_sig(i) = current_is_sig;
    
    uid = C{i, 1};
    uid = uid(numel('unit_uuid__')+1:end);      
    
    if ( current_is_sig )
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
    else
      h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
    end
    
    if ( current_is_sig )
      text( x_coord + 0.05, y_coord, uid );
    end
    store_coords = append( store_coords, set_data(one(subset), [x_coord, y_coord]) );
    
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
  bin_size_samples = -1:0.1:1;
  ylims = [0, 70];
  
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
    
    histogram( ax2, X, bin_size_samples, 'facecolor', colors(reg) );
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
    
    histogram( ax3, Y, bin_size_samples, 'facecolor', colors(reg) );
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
  
  if ( is_median )
    kind = sprintf( '%s_median', kind );
  end
  
  if ( is_minus_null )
    kind = sprintf( '%s_minus_null', kind );
  end

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

%%

start_t = 0;
stop_t = 0.3;
t_ind = psth_t >= start_t & psth_t < stop_t;

should_keep_trials = false;

m_psth = c_psth;
m_psth = m_psth.only( {'m1', 'mutual', 'face', 'eyes'} );

m_psth.data = nanmean( m_psth.data(:, t_ind), 2 );

mean_each = { 'channel', 'unit_uuid', 'looks_to', 'looks_by' };

if ( should_keep_trials )
  max_keep = 12;

  rebuilt = Container();
  [I, C] = m_psth.get_indices( mean_each );
  for i = 1:numel(I)
    subset = m_psth(I{i});

    n_keep = randperm( min(max_keep, shape(subset, 1)) );
    subset = subset(n_keep);  
    rebuilt = append( rebuilt, subset );  
  end

  m_psth = rebuilt;
end

func_t = 'nanmean';

if ( strcmp(func_t, 'nanmean') )
  summary_func = @rowops.nanmean;
elseif ( strcmp(func_t, 'nanmedian') );
  summary_func = @rowops.nanmedian;
end

m_psth = m_psth.each1d( mean_each, summary_func );

m_psth = m_psth.require_fields( 'summary_func_t' );
m_psth('summary_func_t') = strrep( func2str(summary_func), '.', '' );

%%

conf = bfw.config.load();
save_p = fullfile( conf.PATHS.plots, 'population_response', datestr(now, 'mmddyy'), 'scatter' );

outer_plt_psth = m_psth;
% plt_psth = plt_psth({'unit_rating__3'});

outer_plt_psth = outer_plt_psth.collapse( 'unit_rating' );

figures_are = 'unit_rating';

[I2, C2] = outer_plt_psth.get_indices( figures_are );

base_filename = sprintf( '%d_%d', abs(start_t*1e3), abs(stop_t*1e3) );

for i = 1:numel(I2)
  
plt_psth = outer_plt_psth(I2{i});

[I, C] = plt_psth.get_indices( {'region', 'unit_rating'} );

subp_shape = shared_utils.plot.get_subplot_shape( numel(I) );

f = figure(1);
clf( f );

colors = containers.Map( {'accg', 'bla', 'ofc', 'dmpfc'}, {'r', 'g', 'b', 'c'} );

titles_are = { 'region', 'unit_rating', 'summary_func_t' };
fnames_are = unique( [titles_are, {'unit_rating', 'region'}] );

for idx = 1:numel(I)
  
  subset_psth = plt_psth(I{idx});
  
  reg = C{idx, 1};
  
  subplot( subp_shape(1), subp_shape(2), idx );
  
  func = @(x, first, sec) (x({first}) - x({sec})) ./ (x({first}) + x({sec}));
  
  subset_psth = subset_psth.collapse( {'channel', 'look_order', 'session_name', 'unified_filename'} );  
  m_ratio_eyes_face = subset_psth.for_each( 'region', @(x) func(x, 'eyes', 'face') );
  m_ratio_mut_excl = subset_psth.for_each( 'region', @(x) func(x, 'mutual', 'm1') );
  
  assert( eq_ignoring(m_ratio_eyes_face.labels, m_ratio_mut_excl.labels ...
    , {'looks_by', 'looks_to'}) );
  
  X = m_ratio_mut_excl.data;
  Y = m_ratio_eyes_face.data;
  
  non_nans = ~isnan(X) & ~isnan(Y);
  
  [r, p] = corr( X, Y, 'rows', 'complete' );
  ps = polyfit( X(non_nans), Y(non_nans), 1 );
  res = polyval( ps, [-1, 1] );
  
  if ( p < 0.05 )
    hold on;
    plot( 1, 1, 'k*' );
    plot( [-1, 1], res );
  end
  
  scatter( X, Y, 4, colors(reg));
  
  ylim( [-1, 1] );
  xlim( [-1, 1] );
  
  hold on;
  
  plot( [0, 0], [-1, 1], 'k--' );
  plot( [-1, 1], [0, 0], 'k--' );
  
  title( strjoin(flat_uniques(subset_psth, titles_are), ' | ') );
  
  xlabel( 'Mutual over Exclusive' );
  ylabel( 'Eyes over Face' );
  
end

filename = strjoin( flat_uniques(plt_psth, fnames_are), '_' );

filename = sprintf( '%s_%s', base_filename, filename );
  
shared_utils.io.require_dir( save_p );
shared_utils.plot.save_fig( f, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, true );
end

%%  sliding window correlation

m_psth = c_psth;
m_psth = m_psth.only( {'m1', 'mutual', 'face', 'eyes'} );

bin_size = 0.3;
step_size = 0.3;

bin_size_samples = round( bin_size / (psth_t(2) - psth_t(1)) );

%%

[I, C] = m_psth.get_indices( {'region'} );

means_each = { 'looks_to', 'looks_by', 'unit_uuid', 'channel' };

contrast_rs = Container();
contrast_ps = Container();

noncontrast_rs = Container();
noncontrast_ps = Container();

for i = 1:numel(I)
  
  one_reg = m_psth(I{i});
  
  one_reg_means = one_reg.each1d( means_each, @rowops.nanmean );
  
  %   get contrast ratio
  func = @(x, first, sec) (x({first}) - x({sec})) ./ (x({first}) + x({sec}));
  
  one_reg_means = one_reg_means.collapse( {'channel', 'look_order', 'session_name', 'unified_filename'} );  
  m_ratio_eyes_face = one_reg_means.for_each( 'region', @(x) func(x, 'eyes', 'face') );
  m_ratio_mut_excl = one_reg_means.for_each( 'region', @(x) func(x, 'mutual', 'm1') );
  
  eyes_face_data = squeeze( nanmean(shared_utils.array.bin3d(m_ratio_eyes_face.data, bin_size_samples), 2) );
  mut_excl_data = squeeze( nanmean(shared_utils.array.bin3d(m_ratio_mut_excl.data, bin_size_samples), 2) );
  
  %   get non contrast ratio
  collapsed_looks_by = one_reg_means.each1d( setdiff(means_each, 'looks_by'), @rowops.nanmean );
  nc_eyes_face_data = get_data( collapsed_looks_by );
  collapsed_looks_to = one_reg_means.each1d( setdiff(means_each, 'looks_to'), @rowops.nanmean );
  nc_mut_excl_data = get_data( collapsed_looks_to );
  
  nc_mut_excl_data = squeeze( nanmean(shared_utils.array.bin3d(nc_mut_excl_data, bin_size_samples), 2) );
  nc_eyes_face_data = squeeze( nanmean(shared_utils.array.bin3d(nc_eyes_face_data, bin_size_samples), 2) );
  
  rs = zeros( 1, size(eyes_face_data, 2) );
  ps = zeros( size(rs) );
  
  for j = 1:size(mut_excl_data, 2)
    
    X = mut_excl_data(:, j);
    Y = eyes_face_data(:, j);
    
    [r, p] = corr( X, Y, 'rows', 'complete' );
    
    rs(j) = r;
    ps(j) = p;
  end
  
  contrast_rs = append( contrast_rs, set_data(one(one_reg), rs) );
  contrast_ps = append( contrast_ps, set_data(one(one_reg), ps) );
  
  eye_face_rs = zeros( size(rs) );
  eye_face_ps = zeros( size(ps) );
  
  mut_excl_rs = zeros( size(rs) );
  mut_excl_ps = zeros( size(rs) );
  
  for j = 1:size(nc_mut_excl_data, 2)

    eyes = nc_eyes_face_data( collapsed_looks_by.where('eyes'), j );
    face = nc_eyes_face_data( collapsed_looks_by.where('face'), j );
    mut = nc_mut_excl_data( collapsed_looks_to.where('mutual'), j );
    excl = nc_mut_excl_data( collapsed_looks_to.where('m1'), j );
    
    [eye_face_rs(j), eye_face_ps(j)] = corr( eyes, face, 'rows', 'complete' );
    [mut_excl_rs(j), mut_excl_ps(j)] = corr( mut, excl, 'rows', 'complete' );
    
  end
  
  roi_rs = set_data( one(collapsed_looks_by), eye_face_rs );
  roi_ps = set_data( one(collapsed_looks_by), eye_face_ps );
  
  roi_rs('looks_to') = 'eyes_face';
  roi_rs = roi_rs.collapse( 'looks_by' );
  roi_ps('looks_to') = 'eyes_face';
  roi_ps = roi_ps.collapse( 'looks_by' );
  
  look_type_rs = set_data( one(collapsed_looks_to), mut_excl_rs );
  look_type_ps = set_data( one(collapsed_looks_to), mut_excl_ps );
  
  look_type_rs('looks_by') = 'mut_excl';
  look_type_rs = look_type_rs.collapse( 'looks_to' );
  look_type_ps('looks_by') = 'mut_excl';
  look_type_ps = look_type_ps.collapse( 'looks_to' );
  
  noncontrast_rs = extend( noncontrast_rs, roi_rs, look_type_rs );
  noncontrast_ps = extend( noncontrast_ps, roi_ps, look_type_ps );
end

%%

save_p = fullfile( conf.PATHS.plots, 'population_response', datestr(now, 'mmddyy') ...
  , 'corrs_over_time' );

subps_are = { 'region' };
titles_are = unique( [subps_are] );

kind = 'contrast';

switch ( kind )
  case 'mut_excl'
    ylab = 'R (mutual vs. exclusive)';
    to_plt_rs = noncontrast_rs({kind});
    to_plt_ps = noncontrast_ps({kind});
  case 'eyes_face'
    ylab = 'R (eyes vs. face)';
    to_plt_rs = noncontrast_rs({kind});
    to_plt_ps = noncontrast_ps({kind});
  case 'contrast'
    ylab = 'R (contrast)';
    to_plt_rs = contrast_rs;
    to_plt_ps = contrast_ps;
end

[I, C] = to_plt_rs.get_indices( subps_are );

subp_shape = shared_utils.plot.get_subplot_shape( numel(I) );

f = figure(1);
clf( f );

ts = psth_t(1:bin_size_samples:numel(psth_t));

axs = gobjects( 1, numel(I) );

for i = 1:numel(I)
  axs(i) = subplot( subp_shape(1), subp_shape(2), i );
  
  subset_r = to_plt_rs(I{i});
  subset_p = to_plt_ps(I{i});
  
  assert( shapes_match(subset_r, subset_p) && shape(subset_r, 1) == 1 );
  
  plot( ts, subset_r.data );  
  hold on;
  
  xlabel( '(s) from event' );
  
  if ( i == 1 )
    ylabel( ylab );
  end
  
  title( strjoin(flat_uniques(subset_r, titles_are), ' | ') );
    
end

ylims = cell2mat( arrayfun(@(x) get(x, 'ylim'), axs, 'un', false)' );
lims = [ min(ylims(:, 1)), max(ylims(:, 2)) ];

set( axs, 'ylim', lims );
set( axs, 'nextplot', 'add' );

[~, zero_ind] = min( abs(0 - psth_t) );

arrayfun( @(x) plot(x, [psth_t(zero_ind), psth_t(zero_ind)], lims, 'k--'), axs );

for i = 1:numel(I)
  
  subset_p = to_plt_ps(I{i});
  
  is_sig = find( subset_p.data < 0.05 );
  
  for j = 1:numel(is_sig)
    plot( axs(i), ts(is_sig(j)), max(ylims(:, 2)), 'k*', 'markersize', 4 );
  end
end

fname = sprintf( '%s_%s', kind, strjoin(flat_uniques(to_plt_rs, {'looks_to', 'looks_by'})) );
shared_utils.io.require_dir( save_p );
shared_utils.plot.save_fig( f, fullfile(save_p, fname), {'epsc', 'png', 'fig'}, true );
