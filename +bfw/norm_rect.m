function rect = norm_rect(rect, min_x, max_x, min_y, max_y)

span_x = max_x - min_x;
span_y = max_y - min_y;

rect([1, 3]) = (rect([1, 3]) - min_x) / span_x;
rect([2, 4]) = (rect([2, 4]) - min_y) / span_y;

end