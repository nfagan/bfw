function [accept, label, m1_label, m2_label] = ...
  default_check_accept_mutual_event_func(m1p, m2p, m1_rects, m2_rects)

accept = false;
label = '';
m1_label = '';
m2_label = '';

m1_eyes = bfw.bounds.rect( m1p(1), m1p(2), m1_rects('eyes_nf') );
m1_face = bfw.bounds.rect( m1p(1), m1p(2), m1_rects('face') );

m2_eyes = bfw.bounds.rect( m2p(1), m2p(2), m2_rects('eyes_nf') );
m2_face = bfw.bounds.rect( m2p(1), m2p(2), m2_rects('face') );

if ( (m1_eyes && m2_face) || (m1_face && m2_eyes) )
  accept = true;
  label = 'face';
  
  if ( m1_eyes )
    m1_label = 'eyes_nf';
    m2_label = 'face';
  else
    m1_label = 'face';
    m2_label = 'eyes_nf';
  end
end

end