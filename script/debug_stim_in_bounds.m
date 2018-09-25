function debug_stim_in_bounds()

mats = bfw.require_intermediate_mats( [], bfw.gid('aligned'), '04252018' );

for idx = 1:numel(mats)
  
  pos_file = shared_utils.io.fload( mats{idx} );

  stim_file = bfw.load1( 'stim', pos_file.m1.unified_filename );
  roi_file = bfw.load1( 'rois', pos_file.m1.unified_filename );

  %%

  lb = -0.5;
  la = 1;
  sr = 1e3;
  bin_size = 10;
  pad_amt = 4;

  t = lb:1/sr:la-1/sr;
  t = cellfun( @(x) x(1), shared_utils.vector.bin(t, bin_size) );

  m1_pos = pos_file.m1.position;
  m1_time = pos_file.m1.plex_time;

  rects = roi_file.m1.rects;
  roi_names = keys( rects );

  fs = { 'stimulation_times', 'sham_times' };
  stim_labs = { 'stim', 'sham' };

  all_ib = [];
  all_ts = [];
  all_labs = fcat();

  for i = 1:numel(fs)
    times = stim_file.(fs{i});
    stim_type = stim_labs{i};

    c = combvec( 1:numel(times), 1:numel(roi_names) );

    for j = 1:size(c, 2)
      col = c(:, j);

      time = times(col(1));
      roi = roi_names{col(2)};

      rect = rects(roi);
      rect = bfw.bounds.rect_pad( rect, pad_amt, pad_amt );

      t_ind = m1_time >= (time + lb) & m1_time <= (time + la);
      m1_t = m1_time(t_ind);
      ib = bfw.bounds.rect( m1_pos(1, t_ind), m1_pos(2, t_ind), rect );

      labs = fcat.create( ...
        'unified_filename', stim_file.unified_filename ...
      , 'roi', roi ...
      , 'stim_type', stim_type ...
      , 'trial', sprintf('trial__%d', col(1)) ...
      );

      binned_ib = shared_utils.vector.bin( ib, bin_size );
      binned_ib = cellfun( @pnz, binned_ib );
      binned_ib = binned_ib(1:numel(t));

      all_ib = [ all_ib; binned_ib ];

      append( all_labs, labs );
    end
  end
end

%%

pltdat = all_ib;
pltlabs = all_labs';

mask = fcat.mask( pltlabs, @find, {'eyes'}, @findnone, {'trial__2'} );

pltdat = pltdat(mask, :);
pltlabs = pltlabs(mask);

pl = plotlabeled();

pl.x = t;
pl.add_errors = false;

pcats = { 'roi', 'stim_type' };
gcats = { };

figure(1);
clf();

axs = pl.lines( pltdat, pltlabs, gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0], 'k--' );



