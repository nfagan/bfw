function pairs = bfw_get_non_overlapping_pairs()

pairs = { ...
    {'eyes_nf', 'face'} ...
  , {'mouth', 'face'} ...
  , {'eyes_nf', 'mouth'} ...
  , {'left_nonsocial_object', 'everywhere'} ...
  , {'right_nonsocial_object', 'everywhere'} ...
  , {'eyes_nf', 'everywhere'} ...
  , {'mouth', 'everywhere'} ...
  , {'face', 'everywhere'} ...
};

end