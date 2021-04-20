function rects = pad_rois(rects, rois, pad_amt)

rois = cellstr( rois );
for i = 1:numel(rois)
  rect = rects(rois{i});
  wp = shared_utils.rect.width( rect ) * pad_amt * 0.5;
  hp = shared_utils.rect.height( rect ) * pad_amt * 0.5;
  rects(rois{i}) = shared_utils.rect.expand( rect, wp, hp );
end

end