function rect = rect_right_nonsocial_object_eyes_nf_matched(varargin)

rect = bfw.calibration.rect_nonsocial_object_eyes_nf_matched( ...
  @bfw.calibration.rect_right_nonsocial_object, varargin{:} ...
);

end