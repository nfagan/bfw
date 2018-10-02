function debug_stim_events(conf)

if ( nargin < 1 ), conf = bfw.config.load(); end

stim_p = bfw.gid( 'stim', conf );
events_p = bfw.gid( 'events_per_day', conf );

mats = bfw.require_intermediate_mats( [], stim_p );

starts = -1:0.01:5;
stops = starts + 0.25;

is_slide_window = true;

t_series = -1:0.01:5;

all_dat = [];
all_labs = fcat();

uuid_stp = 1;

for idx = 1:numel(mats)
  shared_utils.general.progress( idx, numel(mats) );
  
  stim_file = shared_utils.io.fload( mats{idx} );
  events_file = bfw.load1( 'events_per_day', stim_file.unified_filename, conf );
  
  if ( isempty(events_file) )
    fprintf( '\n No events for "%s".', stim_file.unified_filename );
    continue; 
  end
  
  if ( events_file.is_link )
    events_file = shared_utils.io.fload( fullfile(events_p, events_file.data_file) );
  end
  
  eventlabs = fcat.from( events_file.event_info.labels );
  event_times = events_file.event_info.data(:, events_file.event_info_key('times'));
  event_mask = find( eventlabs, stim_file.unified_filename );
  
  [evtlabs, I] = keepeach( eventlabs', {'looks_by', 'looks_to'}, event_mask );

  fs = { 'stimulation_times', 'sham_times' };
  stim_labs = { 'stim', 'sham' };

  for i = 1:numel(fs)
    times = stim_file.(fs{i});
    stim_type = stim_labs{i};

    c = combvec( 1:numel(times), 1:numel(I) );

    for j = 1:size(c, 2)
      col = c(:, j);

      stim_time = times(col(1));
      ind = I{col(2)};

      labs = fcat.create( ...
          'stim_type',  stim_type ...
        , 'trial',      sprintf('trial__%d', col(1)) ...
        , 'uuid',       sprintf('uuid__%d', uuid_stp) ...
      );
    
      join( labs, evtlabs(col(2)) );
    
      if ( is_slide_window )
        binned_times = slide_window_counts( event_times(ind), starts+stim_time, stops+stim_time );
      else
        binned_times = histc( event_times(ind), t_series + stim_time );
      end
      
      p_times = binned_times / numel( ind );

      append( all_labs, labs );
      all_dat = [ all_dat; p_times(:)' ];
      uuid_stp = uuid_stp + 1;
    end
  end
end

%%

t = ternary( is_slide_window, starts, t_series );

uselabs = all_labs';
usedat = all_dat;

[sumlabs, I] = keepeach( uselabs, {'unified_filename', 'stim_type', 'looks_to', 'looks_by'} );
sumdat = rowmean( usedat*100, I );

mask = fcat.mask( sumlabs, @find, {'eyes', 'm1'} );

gcats = { 'looks_to', 'stim_type' };
pcats = { 'looks_by' };

figure(1);
clf();

pl = plotlabeled.make_common();
pl.x = t;
axs = pl.lines( sumdat(mask, :), sumlabs(mask), gcats, pcats );

shared_utils.plot.hold( axs, 'on' );


end

function c = slide_window_counts(x, starts, stops)

assert( numel(starts) == numel(stops) );

c = zeros( 1, numel(starts) );

for i = 1:numel(starts)
  c(i) = sum( x >= starts(i) & x < stops(i) );
end

end