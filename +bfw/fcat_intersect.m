function [out, ia, ib] = fcat_intersect(a, b, cats, mask_a, mask_b)

if ( nargin < 3 )
  cats = intersect( getcats(a), getcats(b) );
end
if ( nargin < 4 )
  mask_a = rowmask( a );
end
if ( nargin < 5 )
  mask_b = rowmask( b );
end

cat_a = categorical( a, cats, mask_a );
cat_b = categorical( b, cats, mask_b );

[~, ia, ib] = intersect( cat_a, cat_b, 'rows' );
ia = mask_a(ia);
ib = mask_b(ib);

out = prune( a(ia) );

if ( isempty(out) )
  return
end

rest_cats = setdiff( intersect(getcats(a), getcats(b)), cats );

for i = 1:numel(rest_cats)  
  category = rest_cats{i};
  set_to = makecollapsed( a, category );
  
  is_un_a = isuncat( a, category, mask_a );
  is_un_b = isuncat( b, category, mask_b );
  
  if ( is_un_a && is_un_b )
    combs_a = combs( a, category, mask_a );
    combs_b = combs( b, category, mask_b );
    
    if ( isempty(combs_a) )
      set_to = combs_b;      
    elseif ( isempty(combs_b) || strcmp(combs_a, combs_b) )
      set_to = combs_a;
    end
  end
  
  setcat( out, category, set_to );
end

end