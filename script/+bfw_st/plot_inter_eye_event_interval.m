outs = bfw_st.inter_eye_event_interval( 'config', bfw.config.load, 'is_parallel', true );

%%

pl = plotlabeled.make_common();

pltlabs = outs.labels';
pltdat = outs.inter_event_intervals;

use_mask = fcat.mask( pltlabs ...
  , @find, 'm1_exclusive_event' ...
  , @find, 'free_viewing' ...
);

pltdat = pltdat(use_mask);
keep( pltlabs, use_mask );

axs = pl.hist( pltdat, pltlabs, {}, 10000 );

med = mean( pltdat );
hold on;
shared_utils.plot.add_vertical_lines( gca, med, 'r--' );

%%

