conf = bfw.config.load();

meas_type = 'sfcoherence';
input_dir = sprintf( 'at_%s', meas_type );

input_p = bfw.get_intermediate_directory( input_dir );
coh_mats = bfw.require_intermediate_mats( [], input_p );
lfp_p = bfw.get_intermediate_directory( 'event_aligned_lfp' );

plot_p = fullfile( conf.PATHS.data_root, 'plots', meas_type, datestr(now, 'mmddyy') );

meas = Container();

got_freqs = false;
got_time = false;
did_ref_sub = true;

for i = 1:numel(coh_mats)
  fprintf( '\n %d of %d', i, numel(coh_mats) );
  
  c_meas = shared_utils.io.fload( coh_mats{i} );
  
  if ( c_meas.is_link ), continue; end;
  
  coh_params = c_meas.params;
  meas_trial_params = c_meas.within_trial_params;
  
  if ( ~got_time )
    lfp = shared_utils.io.fload( fullfile(lfp_p, c_meas.unified_filename) );
    if ( lfp.is_link )
      lfp = shared_utils.io.fload( fullfile(lfp_p, lfp.data_file) );
    end
    start = lfp.params.look_back;
    stop = lfp.params.look_ahead;
    window_size = lfp.params.window_size;
    step_size = meas_trial_params.step_size;
    sample_rate = lfp.params.sample_rate;
    got_time = true;
  end
  
  if ( ~got_freqs )
    frequencies = c_meas.frequencies;
    did_ref_sub = c_meas.within_trial_params.reference_subtract;
    got_freqs = true;
  end
  
  meas = meas.append( c_meas.measure );
%   meas = meas.append( c_meas.coherence );
end

meas = SignalContainer( meas );

meas.frequencies = frequencies;
meas.start = start;
meas.stop = stop;
meas.fs = sample_rate;
meas.window_size = window_size;
meas.step_size = step_size;

%%

specificity = { 'looks_to', 'looks_by', 'region' };

meaned_meas = meas.each1d( specificity, @rowops.nanmean );

%%

to_plt = meaned_meas({'eyes', 'm1'});

figure(1); clf();

spectrogram( to_plt, 'region' );

%%  plot regular

to_plt = meaned_meas;
to_plt = to_plt.rm( {'mouth', 'm2', 'outside1'} );

[I, C] = to_plt.get_indices( {'region'} );

for i = 1:numel(I)
  
plt = to_plt(I{i});

figure(1); clf();

plt.spectrogram( specificity ...
  , 'shape', [2, 2] ...
  , 'frequencies', [0, 100] ...
  );

kind = sprintf( 'non_subtracted_%s', meas_type );

if ( ~did_ref_sub )
  kind = sprintf( 'non_ref_subtracted_%s', kind );
end

fnames_are = { 'region', 'looks_to', 'looks_by' };
fname = strjoin( flat_uniques(plt, fnames_are), '_' );
full_plotp = fullfile( plot_p, kind );
full_fname = fullfile( full_plotp, fname );

shared_utils.io.require_dir( full_plotp );
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'}, true );

end

%%  plot subtracted

f = figure(1); 
clf( f );

[I, C] = meaned_meas.get_indices( {'region'} );

for idx = 1:numel(I)
  
to_plt = meaned_meas(I{idx});

for i = 2:4
  
plt = to_plt.collapse( {'look_order', 'unified_filename', 'session_name'} );
plt = plt.rm( {'mouth', 'm2'} );

%   mutual minus exclusive, across all
if ( i == 1 )
  plt = plt.rm( 'face' );
  plt = plt({'mutual'}) - plt({'m1'});
  plt = plt.replace( 'mutual_minus_m1', 'mut-excl' );
  sp_shape = [ 1, 1 ];
  
  %   eyes minus face
elseif ( i == 2 )
  plt = plt({'mutual', 'm1'});
  plt = plt.collapse( 'looks_by' );
  plt = plt.each1d( specificity, @rowops.nanmean );  
  plt = plt({'eyes'}) - plt({'face'});
  plt = plt.replace( 'eyes_minus_face', 'eyes-face' );
  sp_shape = [ 1, 1 ];
  
  %   face minus outside
elseif ( i == 3 )
  plt = collapse( plt({'mutual', 'm1'}), 'looks_by' );
  plt = each1d( plt, specificity, @rowops.nanmean );
  plt = plt({'face', 'outside1'});
  plt = plt({'face'}) - plt({'outside1'});
  sp_shape = [ 1, 1 ];
  
  %   mutual minus exclusive, eyes and face
elseif ( i == 4 )
  plt = plt( {'mutual', 'm1'} );
  eyes = each1d( plt({'eyes'}), specificity, @rowops.nanmean );
  %   face in this case is face OR eyes
  face = set_field( plt({'eyes', 'face'}), 'looks_to', 'face' );
  face = each1d( face, specificity, @rowops.nanmean );
  face = face({'mutual'}) - face({'m1'});
  eyes = eyes({'mutual'}) - eyes({'m1'});
  plt = extend( face, eyes );
  sp_shape = [ 1, 2 ];
end

set( f, 'units', 'normalized' );
set( f, 'position', [0, 0, 1, 1] );

plt.spectrogram( specificity ...
  , 'shape', sp_shape ...
  , 'frequencies', [0, 100] ...
  , 'time', [-300, 500] ...
  );

kind = sprintf( 'subtracted_%s', meas_type );

if ( ~did_ref_sub )
  kind = sprintf( 'non_ref_subtracted_%s', kind );
else
  kind = sprintf( 'ref_subtracted_%s', kind );
end

fnames_are = { 'region', 'looks_to', 'looks_by' };
fname = strjoin( flat_uniques(plt, fnames_are), '_' );
full_plotp = fullfile( plot_p, kind );
full_fname = fullfile( full_plotp, fname );

shared_utils.io.require_dir( full_plotp );
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'}, true );

end

end

%%  lines

specificity = { 'looks_to', 'looks_by', 'region', 'session_name', 'channel' };

meaned_meas = meas.each1d( specificity, @rowops.nanmean );

meaned_meas = meaned_meas.collapse( 'channel' );
meaned_meas = meaned_meas.each1d( specificity, @rowops.nanmean );


%%  plot lines, mut v exclusive

pl = ContainerPlotter();

for idx = 1:2

to_plt = meaned_meas;
to_plt = to_plt.rm( {'mouth', 'm2'} );
to_plt = to_plt.replace( 'm1', 'exclusive' );

if ( idx == 1 )
  to_plt = to_plt.collapse( 'looks_by' );
  to_plt = to_plt.each1d( specificity, @rowops.nanmean );
  lines_are = { 'looks_to' };
  panels_are = { 'region', 'looks_by' };
else
  to_plt = to_plt.rm( 'face' );
  lines_are = { 'looks_by' };
  panels_are = { 'looks_to', 'region' };
end

[I, C] = to_plt.get_indices( {'region'} );

to_plt = to_plt.time_mean( [0, 300] );
to_plt = to_plt.keep_within_freqs( [0, 100] );

for i = 1:numel(I)
  
plt = to_plt(I{i});

figure(1); clf();

pl.default();
pl.y_lim = [-0.35, 0.35];
pl.main_line_width = 1.5;
pl.x = to_plt.frequencies;
pl.add_ribbon = true;
pl.summary_function = @nanmean;
pl.compare_series = true;
% pl.error_function = @(x, y) nanstd(x, [], 1);
% pl.add_smoothing = true;
% pl.smooth_function = @(x) smooth(x, 4);

pl.plot( plt, lines_are, panels_are );

kind = sprintf( 'lines_%s', meas_type );

if ( ~did_ref_sub )
  kind = sprintf( 'non_ref_subtracted_%s', kind );
end

fnames_are = { 'region', 'looks_to', 'looks_by' };
fname = strjoin( flat_uniques(plt, fnames_are), '_' );
full_plotp = fullfile( plot_p, kind );
full_fname = fullfile( full_plotp, fname );

shared_utils.io.require_dir( full_plotp );
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'}, true );

end

end
