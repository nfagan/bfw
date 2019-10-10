function pairs = roi_pairs()

% pairs = { ...
%     {'eyes_nf', 'nonsocial_object'} ...
%   , {'eyes_nf', 'nonsocial_object_eyes_nf_matched'} ...
%   , {'eyes_nf', 'face_non_eyes'} ...
%   , {'face_non_eyes', 'nonsocial_object'} ...
%   , {'face', 'nonsocial_object'} ...
% };

pairs = { ...
    {'eyes_nf', 'nonsocial_object_eyes_nf_matched'} ...
  , {'eyes_nf', 'face_non_eyes'} ...
  , {'face', 'nonsocial_object'} ...
};

end