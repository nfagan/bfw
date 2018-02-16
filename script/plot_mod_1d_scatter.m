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
    psth_t = spikes.psth_t;
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

%%  calculate modulation index

window_pre = spk_params.window_pre;
window_post = spk_params.window_post;
window_not_minus_null = [-0.1, 0.2];

new_labs = bfw.reclassify_cells( c_at_psth, c_null_psth, c_z_psth, psth_t, window_pre, window_post, 0.025/2 );

%%  subtract null

to_sub_at = c_at_psth.rm( {'m1_leads_m2', 'm2_leads_m1'} );
psth_sub_null_at = bfw.subtract_null_psth( set_labels(to_sub_at, new_labs), c_null_psth, psth_t, window_pre, window_post, true );

%%  use_mean

start = -0.1;
stop = 0.2;
to_mean_at = c_at_psth.rm( {'m1_leads_m2', 'm2_leads_m1'} );
t_ind = psth_t >= start & psth_t < stop;

summary_func = @nanmean;
summary_func_str = func2str( summary_func );

meaned_at = set_data( to_mean_at, summary_func(to_mean_at.data(:, t_ind), 2) );

%%  select which to use

use_null = true;

if ( use_null ) 
  base_scatter = psth_sub_null_at;
else
  base_scatter = meaned_at;
end

%%  scatter mut vs. exclusive eyes

to_scatter = base_scatter;

[I, C] = to_scatter.get_indices( {'unit_uuid', 'channel'} );

full_to_scatter_mut_excl = Container();

for i = 1:numel(I)
  subset = to_scatter(I{i});
  
  mut_eyes = subset({'eyes', 'mutual'});
  excl_eyes = subset({'eyes', 'm1'});
  
  if ( isempty(mut_eyes) || isempty(excl_eyes) )
    continue;
  else
    assert( shapes_match(mut_eyes, excl_eyes) && shape(mut_eyes, 1) == 1 );
  end
  
  full_to_scatter_mut_excl = append( full_to_scatter_mut_excl, set_data(one(subset), [mut_eyes.data, excl_eyes.data]) );
end

%%  scatter excl eyes vs excl face

to_scatter = base_scatter;

[I, C] = to_scatter.get_indices( {'unit_uuid', 'channel'} );

full_to_scatter = Container();

for i = 1:numel(I)
  subset = to_scatter(I{i});
  
  excl_eyes = subset({'eyes', 'm1'});
  excl_face = subset({'face', 'm1'});
  
  if ( isempty(excl_face) || isempty(excl_eyes) )
    continue;
  else
    assert( shapes_match(excl_face, excl_eyes) && shape(excl_face, 1) == 1 );
  end
  
  full_to_scatter = append( full_to_scatter, set_data(one(subset), [excl_eyes.data, excl_face.data]) );
end

%%

conf = bfw.config.load();

all_c = allcomb( {{'eyes_vs_face', 'mut_vs_excl'}} );

save_p = fullfile( conf.PATHS.plots, 'population_response', datestr(now, 'mmddyy'), '1d_scatters' );
shared_utils.io.require_dir( save_p );

hist_ylim = 30;
scatter_ylim = 8;

for idx = 1:size(all_c, 1)

  % kind = 'eyes_vs_face';
  kind = all_c{idx, 1};

  if ( strcmp(kind, 'eyes_vs_face') )
    plt = full_to_scatter;
  elseif ( strcmp(kind, 'mut_vs_excl') )
    plt = full_to_scatter_mut_excl;
  else
    error( 'Unrecognized kind "%s".', kind );
  end

  [I, C] = plt.get_indices( {'region'} );

  f = figure(1);
  f2 = figure(2);
  
  clf( f );
  clf( f2 );

  h = gobjects( 1, numel(I) );
  axs = gobjects( 1, numel(I) );
  leg_items = cell( 1, numel(I) );
  leg_items_are = { 'region' };

  alpha = 0.05;

  colors = containers.Map();
  colors( 'bla' ) = 'r';
  colors( 'accg' ) = 'b';
  colors( 'ofc' ) = 'g';
  colors( 'dmpfc' ) = 'm';

  lims = [0, scatter_ylim];

  for i = 1:numel(I)
    sub_to_scatter = plt(I{i});
    
    figure(1);

    reg = char( flat_uniques(sub_to_scatter, 'region') );
    color = colors( reg );

    axs(i) = subplot( 2, 2, i );

    X = sub_to_scatter.data(:, 1);
    Y = sub_to_scatter.data(:, 2);

    h(i) = plot( X, Y, sprintf('%so', color), 'markersize', 1, 'markerfacecolor', color );

    xlim( lims );
    ylim( lims );

    xlims = get( gca, 'xlim' );
    leg_items{i} = char( flat_uniques(sub_to_scatter, leg_items_are) );

    if ( strcmp(kind, 'eyes_vs_face') )
      ylabel( 'Response exclusive face' );
      xlabel( 'Response exclusive eyes' );
    elseif ( strcmp(kind, 'mut_vs_excl') )
      ylabel( 'Response exclusive eyes' );
      xlabel( 'Response mutual eyes' );
    else
      error( 'Unrecognized kind "%s".', kind );
    end

    [r, p] = corr( X, Y ); 

    ps = polyfit( X, Y, 1 );
    res = polyval( ps, xlims );

    corr_p = p(1);
    corr_r = r(1);

    hold on;
    h_ = plot( xlims, res );
    set( h_, 'color', color );

    if ( corr_p <= alpha )
      plot( xlims(2), res(2) + 0.05, 'k*' );
    end

    if ( corr_p < .001 )
      p_str = sprintf( 'p < .001' );
    else
      p_str = sprintf( 'p = %0.3f', corr_p );
    end

    r_str = sprintf( 'r = %0.3f', corr_r );
    full_str = sprintf( '(%s, %s)', r_str, p_str );
    text( xlims(1) + (xlims(2)-xlims(1))/5, res(2) - 0.1, full_str );   
%     
    hold on;
    plot( xlims, ylims, 'k--' ); 

    title_str = strjoin( C(i, :), '_' );
    title( title_str );
    
    axis( 'square' );
    
    %   histogram of indices vs. 0
    figure(2);
    subplot( 2, 2, i );
    
    index = (X-Y) ./ (X+Y);
    
    histogram( index, -1:0.1:1, 'facecolor', color); hold on;
    ylim( [0, hist_ylim] );
    
    med = nanmedian( index );    
    title( title_str );
    ylim_hist = get( gca, 'ylim' );
    plot( [med; med], ylim_hist, 'k--' );
    
    hist_sig = signrank( index );
    
    if ( hist_sig <= 0.05 )
      plot( med+0.05, ylim_hist(2), 'k*' );
    end
    
    if ( strcmp(kind, 'eyes_vs_face') )
      xlabel( '<- Face | Eyes ->' );
    else
      xlabel( '<- Exclusive | Mutual ->' );
    end
    
    m_str = sprintf( 'med = %0.3f', med );
    p_str = sprintf( 'p = %0.3f', hist_sig );
    if ( hist_sig < .001 )
      p_str = sprintf( 'p < .001' );
    end
    text( med+0.1, ylim_hist(2), sprintf('%s, %s', m_str, p_str));
    
    axis( 'square' );
    
  end

  all_xlims = arrayfun( @(x) get(x, 'xlim'), axs, 'un', false );
  all_ylims = arrayfun( @(x) get(x, 'ylim'), axs, 'un', false );
  all_xlims = cell2mat( all_xlims(:) );
  all_ylims = cell2mat( all_ylims(:) );

  xlims = [ min(all_xlims(:, 1)), max(all_xlims(:, 2)) ];
  ylims = [ min(all_ylims(:, 1)), max(all_ylims(:, 2)) ];

  set( axs, 'xlim', xlims );
  set( axs, 'ylim', ylims );
  
  filename = strjoin( all_c(idx, :), '_' );
  
  if ( use_null )
    filename = sprintf( 'null__%s', filename );
  else
    filename = sprintf( '%s__%s', summary_func_str, filename );
  end
  
  formats = { 'epsc', 'fig', 'png' };
  sep_folders = true;
  
  shared_utils.plot.save_fig( f, fullfile(save_p, filename), formats, sep_folders );
  shared_utils.plot.save_fig( f2, fullfile(save_p, sprintf('hist_%s', filename)), formats, sep_folders );
end



