function bfw_plot_one_event_timeline(...
    ax ...
  , m1_init_se ...
  , m2_init_se ...
  , inter_se ...
  , m1_term_se ...
  , m2_term_se ...
  , m1_excl_se ...
  , m2_excl_se)

height = 1;

segments = { m1_init_se, m2_init_se, inter_se, m1_term_se, m2_term_se, m1_excl_se, m2_excl_se };
leg_entries = { 'm1-init', 'm2-init', 'inter', 'm1-term', 'm2-term', 'm1-solo', 'm2-solo' };
y_offs = [ 0, 0, 0, 0, 0, height, height * 2 ];
assert( numel(leg_entries) == numel(segments) && numel(y_offs) == numel(segments) );
colors = jet( numel(segments) );

hold( ax, 'on' );

leg_hs = cell( numel(segments), 1 );

for i = 1:numel(segments)
  seg = segments{i};
  for j = 1:size(seg, 1)
    se = seg(j, :);
    
    if ( any(isnan(se)) )
      continue;
    end
    
    x0 = se(1);
    y0 = y_offs(i);
    w = se(2) - x0;
    
    h = rectangle( 'position', [x0, y0, w, height], 'parent', ax );
    set( h, 'facecolor', colors(i, :) );
    
    if ( isempty(leg_hs{i}) )
      leg_h = plot( x0, y0, 'k*' );
      set( leg_h, 'color', colors(i, :) );
      leg_hs{i} = leg_h;
    end
  end
end

xlabel( ax, 'Time from start (s)' );

if ( ~any(cellfun(@isempty, leg_hs)) )
  legend( vertcat(leg_hs{:}), leg_entries );
end

end