function [excl_roi_order, mut_roi_order] = default_roi_ordering(roi_file)

excl_roi_order = { 'eyes_nf', 'face', 'left_nonsocial_object', 'right_nonsocial_object' };
mut_roi_order = { 'eyes_nf', 'face' };

end