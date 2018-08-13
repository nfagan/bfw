function add_m_ordering(varargin)

defaults = bfw.get_common_make_defaults();

defaults.max_lag = 1; % s -- how far ahead can m2's event

params = bfw.parsestruct( defaults, varargin );

event_p = bfw.get_intermediate_directory( 'events' );

event_mats = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

m1_leads_key = 'm1_leads_m2';
m2_leads_key = 'm2_leads_m1';

for i = 1:numel(event_mats)
  fprintf( '\n %d of %d', i, numel(event_mats) );
  
  events = shared_utils.io.fload( event_mats{i} );
  
  un_filename = events.unified_filename;
  
  m1_col = events.monk_key( 'm1' );
  m2_col = events.monk_key( 'm2' );
  
  n_cols = size( events.times, 2 );
  
  if ( events.monk_key.isKey(m1_leads_key) )
    m1_leads_m2_col = events.monk_key(m1_leads_key);
  else
    m1_leads_m2_col = n_cols + 1;
  end
  
  if ( events.monk_key.isKey(m2_leads_key) )
    m2_leads_m1_col = events.monk_key(m2_leads_key);
  else
    m2_leads_m1_col = m1_leads_m2_col + 1;
  end
  
  rois = events.roi_key.keys();
  
  for j = 1:numel(rois)
    roi = rois{j};
    roi_row = events.roi_key( roi );
    
    m1_times = events.times{roi_row, m1_col};
    m2_times = events.times{roi_row, m2_col};
    
    m1_leads_m2 = get_ordered_events( m2_times, m1_times, params.max_lag );
    m2_leads_m1 = get_ordered_events( m1_times, m2_times, params.max_lag );    
    
    events.times{roi_row, m1_leads_m2_col} = m1_leads_m2;
    events.times{roi_row, m2_leads_m1_col} = m2_leads_m1;
    
    events.lengths{roi_row, m1_leads_m2_col} = nan( size(m1_leads_m2) );
    events.lengths{roi_row, m2_leads_m1_col} = nan( size(m2_leads_m1) );
    
    events.durations{roi_row, m1_leads_m2_col} = nan( size(m1_leads_m2) );
    events.durations{roi_row, m2_leads_m1_col} = nan( size(m2_leads_m1) );
    
    events.monk_key(m1_leads_key) = m1_leads_m2_col;
    events.monk_key(m2_leads_key) = m2_leads_m1_col;
  end
  
  events.identifiers = bfw.get_event_identifiers( events.times, un_filename );
  
  events.adjustments('m_ordering') = struct( 'params', params );
  
  save( event_mats{i}, 'events' );
end

end

function c = get_ordered_events( a, b, threshold )

c = nan( 1, numel(a) );
to_rem = true( size(c) );

for i = 1:numel(a)
  a_ = a(i);
  subset_b = b < a_ & (abs(b - a_) < threshold);
  ind_subset_b = find( subset_b, 1, 'last' );
  
  if ( isempty(ind_subset_b) ), continue; end
  
  c(i) = b( ind_subset_b );
  to_rem(i) = false; 
end

c(to_rem) = [];

end