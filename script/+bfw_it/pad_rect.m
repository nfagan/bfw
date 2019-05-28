function rect = pad_rect(rect, amount)

pad_w = (rect(3) - rect(1)) * amount;
pad_h = (rect(4) - rect(2)) * amount;

rect(1) = rect(1) - pad_w/2;
rect(3) = rect(3) + pad_w/2;
rect(2) = rect(2) - pad_h/2;
rect(4) = rect(4) + pad_h/2;

end