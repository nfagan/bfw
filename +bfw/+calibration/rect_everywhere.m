function bounds = rect_everywhere(varargin)

% RECT_EVERYWHERE -- ROI such that every point is in bounds.

% Using inf complicates things because inf * 0 is NaN, whereas
% huge_but_not_inf * 0 is 0
huge_but_not_inf = flintmax();

bounds = [ -huge_but_not_inf, -huge_but_not_inf, huge_but_not_inf, huge_but_not_inf ];

end