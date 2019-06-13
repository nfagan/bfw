event_outs = bfw_linearize_events();

%%
non_overlapping_inds = bfw_exclusive_events_from_linearized_events( event_outs );

%%

starts = event_outs.events(:, event_outs.event_key('start_time'));
stops = event_outs.events(:, event_outs.event_key('stop_time'));

durs = stops - starts;

ok_durs = durs(non_overlapping_inds);
labs = keep( event_outs.labels', non_overlapping_inds );

replace( labs, {'left_nonsocial_object', 'right_nonsocial_object'}, 'nonsocial_object' );
replace( labs, {'mouth', 'face'}, 'face' );

%%

pl = plotlabeled.make_common();
pl.summary_func = @nanmedian;

mask = fcat.mask( labs ...
  , @find, 'm1' ...
  , @find, {'eyes_nf', 'nonsocial_object', 'face'} ...
);

pcats = { 'roi' };

[p_I, p_C] = findall( labs, pcats, mask );

subshape = plotlabeled.get_subplot_shape( numel(p_I) );

for i = 1:numel(p_I)
  p_ind = p_I{i};
  comb = p_C(:, i);
  
  subset_durs = durs(p_ind);
  med_durs = nanmedian( subset_durs );
  
  ax = subplot( subshape(1), subshape(2), i );
  lims = get( ax, 'ylim' );
  
  hold( ax, 'off' );
  hist( ax, subset_durs, 200 );
  hold( ax, 'on' );
  plot( ax, [med_durs, med_durs], lims, 'r' );
  
  diffed = lims(2) - lims(1);
  
  text( med_durs, lims(2) - diffed*0.1, sprintf('M=%0.2f', med_durs) );
  
  title( ax, strrep(fcat.strjoin(comb, ' | '), '_', ' ') );
  xlim( ax, [0, 10] );
end

% axs = pl.hist( durs(mask), labs(mask), 'roi', 100 );



% I = findall( labs, 'roi', mask );
% 
% pltdat = durs;
% 
% for i = 1:numel(I)
%   med = nanmedian( durs(I{i}) );
%   pltdat(I{i}) = pltdat(I{i}) ./ med;  
% end
% 
% axs = pl.bar( pltdat(mask), labs(mask), 'roi', {}, {} );