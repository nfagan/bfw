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

specificity = { 'unit_uuid', 'looks_by', 'looks_to' };

pop_psth = psth;
pop_null_psth = null_psth;
pop_raster = raster;

n_event_thresh = -Inf;

pop_psth = pop_psth.rm( {'unit_uuid__NaN'} );
pop_null_psth = pop_null_psth.rm( {'unit_uuid__NaN'} );
pop_raster = pop_raster.rm( {'unit_uuid__NaN'} );

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;

window_pre_ind = psth_t >= window_pre(1) & psth_t < window_pre(2);
window_post_ind = psth_t >= window_post(1) & psth_t < window_post(2);

modulated_psth = Container();

[I, C] = pop_psth.get_indices( specificity );

is_sig = true( numel(I), 1 );
too_few_events = false( size(is_sig) );

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_psth = pop_psth(I{i});
  subset_null = pop_null_psth(C(i, :));
  subset_raster = pop_raster(C(i, :));
  
  assert( shape(subset_psth, 1) == 1 && shapes_match(subset_psth, subset_null) );
  
  cell_type = char( subset_psth('cell_type') );
  
  sum_spikes = sum( any(subset_raster.data, 2) );
  
  if ( ~any(sum_spikes >= n_event_thresh) || shape(subset_raster, 1) < n_event_thresh )
    cell_type = 'none';
    too_few_events(i) = true;
  end
  
  real_mean_pre = nanmean( subset_psth.data(:, window_pre_ind), 2 );
  real_mean_post = nanmean( subset_psth.data(:, window_post_ind), 2 );
  
  fake_mean_pre = nanmean( subset_null.data(:, window_pre_ind), 2 );
  fake_mean_post = nanmean( subset_null.data(:, window_post_ind), 2 );
    
  switch ( cell_type )
    case 'pre'
      mod_amt = abs( real_mean_pre - fake_mean_pre );
    case 'post'
      mod_amt = abs( real_mean_post - fake_mean_post );
    case { 'pre_and_post' }
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post] );
    case 'none'
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post] );
      is_sig(i) = false;
    otherwise
      error( 'Unrecognized cell type "%s".', cell_type );
  end
  
  modulated_psth = modulated_psth.append( set_data(subset_psth, mod_amt) );
        
end

%%  n sig

stats_each = { 'looks_to', 'looks_by', 'region' };

to_stats = pop_psth;
to_stats = to_stats.rm( 'm2' );
% to_stats = to_stats( {'mutual', 'm1', 'm2'} );

n_sig = to_stats.for_each( stats_each, @counts, 'cell_type', to_stats('cell_type') );
p_sig = to_stats.for_each( stats_each, @percentages, 'cell_type', to_stats('cell_type') );

for i = 1:2

figure(1); clf();

pl = ContainerPlotter();
pl.y_lim = [0, 100];

if ( i == 1 )
  plt = p_sig;
  base_fname = 'population_percent_significant';
else
  plt = n_sig;
  base_fname = 'population_n_significant';
end

plt.bar( pl, 'region', {'cell_type'}, {'looks_by', 'looks_to'} );

%   save
kind = 'significant_per_region';

fname = strjoin( plt.flat_uniques({'session_name'}), '_' );
fname = sprintf( '%s_%s', base_fname, fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

end

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );

%%

plt_psth = modulated_psth.rm( 'm2' );

[I, C] = plt_psth.get_indices( 'unit_uuid' );

fig = figure(1); clf( fig );

x_range = 1;
y_range = 1;

colors = containers.Map();
colors( 'bla' ) = 'r';
colors( 'accg' ) = 'b';
colors( 'ofc' ) = 'g';

res = Container();

legend_components = containers.Map();

% require_significant = 'any_eyes_face';
require_significant = 'mut_excl';

for i = 1:numel(I)
  subset = plt_psth(I{i});
  
  subset_is_sig = is_sig(I{i});
  
  regs = subset('region');
  assert( numel(regs) == 1 );
  reg = char( regs );
  
  current_color = colors( reg );
  
  ind_eyes = subset.where( 'eyes' );
  ind_face = subset.where( 'face' );
  ind_mut = subset.where( 'mutual' );
  ind_excl = subset.where( 'm1' );
  
  is_sig_eyes = subset_is_sig(ind_eyes);
  is_sig_face = subset_is_sig(ind_face);
  is_sig_mut = subset_is_sig(ind_mut);
  is_sig_excl = subset_is_sig(ind_excl);
  
  all_is_sig = is_sig_eyes && is_sig_face && is_sig_mut && is_sig_excl;
  mut_excl_is_sig = is_sig_mut && is_sig_excl;
  eyes_face_is_sig = is_sig_eyes && is_sig_face;
  
  eyes = get_data( subset(ind_eyes) );
  face = get_data( subset(ind_face) );
  mut = get_data( subset(ind_mut) );
  excl = get_data( subset(ind_excl) );

  eyes_over_face = (eyes-face) ./ (face + eyes);
  mut_over_excl = (mut-excl) ./ (mut + excl);

  x_coord = eyes_over_face * x_range;
  y_coord = mut_over_excl * y_range;

  pairs = field_label_pairs( one(subset) );

  res = res.append( Container([eyes_over_face, mut_over_excl], pairs{:}) );

  h = plot( x_coord, y_coord, sprintf('%so', current_color), 'markersize', 6 ); hold on;
  
  switch ( require_significant )
    case 'any'
      current_is_sig = is_sig_eyes || is_sig_face || is_sig_mut || is_sig_excl;
    case 'any_mut_excl'
      current_is_sig = is_sig_mut || is_sig_excl;
    case 'any_eyes_face'
      current_is_sig = is_sig_eyes || is_sig_face;
    case 'or'
      current_is_sig = mut_excl_is_sig || eyes_face_is_sig;
    case 'and'
      current_is_sig = all_is_sig;
    case 'eyes_face'
      current_is_sig = eyes_face_is_sig;
    case 'mut_excl'
      current_is_sig = mut_excl_is_sig;      
    otherwise
      error( 'Unrecognized require_significant type "%s".', require_significant );
  end
  
  if ( current_is_sig )
    h = plot( x_coord, y_coord, sprintf('%so', current_color), 'MarkerFaceColor', current_color, 'markersize', 6 ); hold on;
  end

  if ( ~legend_components.isKey(reg) )
    legend_components(reg) = h;
  end
end

[I, C] = res.get_indices( 'region' );

corred = Container();

for i = 1:numel(I)
  reg = res(I{i});
  reg( any(isnan(reg.data), 2) ) = [];
  [r, p] = corr( reg.data(:, 1), reg.data(:, 2) );
  corred = corred.append( set_data(one(reg), [r, p]) );
end

% title( 'ACCg' );

hold on;
plot( [-1, 1], [0, 0], 'k-' );
plot( [0, 0], [-1, 1], 'k-' );

xlabel( 'eyes over face' );
ylabel( 'mutual over exclusive' );

ylim( [-1, 1] );
xlim( [-1, 1] );

axis( 'square' );

leg_keys = legend_components.keys();
leg_elements = gobjects( 1, numel(leg_keys) );

for i = 1:numel(leg_keys)
  leg_elements(i) = legend_components(leg_keys{i}); 
end

legend( leg_elements, leg_keys );

%   save
kind = 'population_matrix_from_null';

fname = strjoin( res.flat_uniques({'session_name'}), '_' );
fname = sprintf( 'population_matrix_%s_%s', require_significant, fname );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'population_response' );
save_plot_p = fullfile( save_plot_p, date_dir, kind, psth_info_str );
shared_utils.io.require_dir( save_plot_p );

shared_utils.plot.save_fig( gcf, fullfile(save_plot_p, fname), {'epsc', 'png', 'fig'} );