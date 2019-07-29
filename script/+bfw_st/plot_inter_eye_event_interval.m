% conf = bfw_st.default_config();

new_dat = bfw_st.inter_eye_event_interval( 'config', conf, 'is_parallel', true );
old_dat = bfw_st.inter_eye_event_interval( 'config', bfw.config.load(), 'is_parallel', true );

outs = struct();
outs.inter_event_intervals = [ new_dat.inter_event_intervals; old_dat.inter_event_intervals ];
outs.labels = [ new_dat.labels'; old_dat.labels ];

%%

pl = plotlabeled.make_common();

pltlabs = outs.labels';
pltdat = outs.inter_event_intervals;

bfw.add_monk_labels( pltlabs );

use_mask = fcat.mask( pltlabs ...
  , @find, 'm1_exclusive_event' ...
);

pltdat = pltdat(use_mask);
keep( pltlabs, use_mask );

[axs, inds] = pl.hist( pltdat, pltlabs, {'task_type', 'id_m1'}, 10000 );

for i = 1:numel(inds)

med = mean( pltdat(inds{i}) );
shared_utils.plot.hold( axs(i), 'on' );
shared_utils.plot.add_vertical_lines( axs(i), med, 'r--' );

text( axs(i), med, max(get(gca,'ylim')), sprintf('M = %0.2f', med) );

end

%%

