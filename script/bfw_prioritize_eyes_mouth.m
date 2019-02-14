function tf = bfw_prioritize_eyes_mouth(roi1, roi2)

tf = true;

if ( strcmp(roi1, 'face') && strcmp(roi2, 'eyes_nf') )
  % If face overlaps eyes, and the event to be removed is eyes,
  % do not remove it.
  
  tf = false;
  
elseif ( strcmp(roi1, 'mouth') && strcmp(roi2, 'eyes_nf') )
  % If mouth overlaps eyes, and the event to be removed is eyes,
  % do not remove it.
  
  tf = false;
end

end