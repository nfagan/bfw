function bounds_file = bounds(files, varargin)

%   BOUNDS -- Create bounds file.
%
%     See also bfw.make.help, bfw.make.defaults.raw_bounds
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `varargin` ('name', value)
%     FILES:
%       - 'edf_raw_samples'
%       - 'rois'
%     OUT:
%       - `aligned_file` (struct)

bfw.validatefiles( files, {'edf_raw_samples', 'rois'} );

defaults = bfw.make.defaults.raw_bounds();
params = bfw.parsestruct( defaults, varargin );

samples_file = shared_utils.general.get( files, 'edf_raw_samples' );
roi_file = shared_utils.general.get( files, 'rois' );

unified_filename = bfw.try_get_unified_filename( samples_file );

monk_ids = intersect( {'m1', 'm2'}, fieldnames(samples_file) );

% Check which rois have been selected with the 'rois', {rois} parameter
[requested_roi_names, is_all_rois] = get_requested_roi_names( params.rois );

% Get the bounds file to which we'll be assigning bounds for m1 and m2.
% This file is either a struct with no fields, or an existing bounds file
% that will (by default) be loaded from disk.
bounds_file = get_base_bounds_file( unified_filename, is_all_rois, params );
bounds_file.unified_filename = unified_filename;
bounds_file.params = params;

for j = 1:numel(monk_ids)
  m_id = monk_ids{j};

  x = samples_file.(m_id).x;
  y = samples_file.(m_id).y;

  rects = roi_file.(m_id).rects;
  possible_roi_names = keys( rects );
  
  active_roi_names = try_get_active_roi_names( possible_roi_names, requested_roi_names, is_all_rois );

  % Get either a fresh containers.Map() object, or a reference to the
  % existing containers.Map() object in e.g. bounds_file.m1.bounds, if it
  % exists.
  bounds = get_bounds_container( bounds_file, m_id );

  for k = 1:numel(active_roi_names)
    roi_name = active_roi_names{k};

    roi = rects(roi_name);
    pad = get_padding( params.padding, roi_name );

    padded_roi = bfw.bounds.rect_pad_frac( roi, pad, pad );

    bounds(roi_name) = bfw.bounds.rect( x, y, padded_roi );
  end

  bounds_file.(m_id).bounds = bounds;
end

d = 10;

end

function p = get_padding(padding, roi)

if ( isnumeric(padding) )
  p = padding;
  return
end

if ( shared_utils.general.is_key(padding, roi) )
  p = shared_utils.general.get( padding, roi );
else
  p = 0;
end

end

function bounds = get_bounds_container(bounds_file, monk_id)

bounds = containers.Map();

if ( ~isfield(bounds_file, monk_id) )
  return
end

if ( ~isfield(bounds_file.(monk_id), 'bounds') )
  return
end

bounds = bounds_file.(monk_id).bounds;

end

function roi_names = try_get_active_roi_names(possible_rois, requested_rois, is_all_rois)

if ( is_all_rois )
  roi_names = possible_rois;
  return
end

assert( all(ismember(requested_rois, possible_rois)) ...
  , 'Some manually requested rois do not have an entry in the roi file.' );

roi_names = unique( requested_rois );

end

function [roi_names, is_all] = get_requested_roi_names(roi_names)

roi_names = cellstr( roi_names );
is_all = numel( roi_names ) == 1 && strcmp( roi_names, 'all' );

end

function file = get_base_bounds_file(unified_filename, is_all_rois, params)

file = struct();

if ( ~params.append || is_all_rois )
  return
end

conf = params.config;
raw_bounds_intermediate_directory_name = params.intermediate_directory_name;
get_current_file_func = params.get_current_bounds_file_func;

file = get_current_file_func( unified_filename, raw_bounds_intermediate_directory_name, conf );

end