conf = bfw.config.load();

meas_type = 'coherence';
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
  
%   meas = meas.append( c_meas.measure );
  meas = meas.append( c_meas.coherence );
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

%%  plot regular

to_plt = meaned_meas;
to_plt = to_plt.rm( {'mouth', 'm2'} );

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

for i = 1
  
plt = meaned_meas;

if ( i == 1 )
  plt = plt({'mutual'}) - plt({'m1'});
  plt = plt.replace( 'mutual_minus_m1', 'mut-excl' );
else
  plt = plt({'mutual', 'm1'});
  plt = plt({'eyes'}) - plt({'face'});
  plt = plt.replace( 'eyes_minus_face', 'eyes-face' );
end

set( f, 'units', 'normalized' );
set( f, 'position', [0, 0, 1, 1] );

plt.spectrogram( specificity ...
  , 'shape', [2, 3] ...
  , 'frequencies', [0, 100] ...
  , 'time', [-200, 500] ...
  );

kind = 'subtracted_coherence';

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
shared_utils.plot.save_fig( gcf(), full_fname, {'epsc', 'png', 'fig'} );

end

