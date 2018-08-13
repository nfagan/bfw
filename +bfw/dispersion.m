function a = dispersion(x, y)

a = ( dispersion_one(x) + dispersion_one(y) ) / 2;

end

function max_disp = dispersion_one(xy)

max_disp = -inf;

for i = 1:numel(xy)
  for j = 1:numel(xy)
    if ( j == i ), continue; end
    a = xy(i);
    b = xy(j);
    
    max_disp = max( max_disp, abs(a-b) );
  end
end

end