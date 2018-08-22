function bounds = rect_eyes_cc(calibration_data, key_map, padding_info, const, screen_rect)

%
%   EYES
%

% eyel = key_map( 'eyel' );
% eyer = key_map( 'eyer' );
% 
% eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
% eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );
% 
% eye_y = mean( [eyel_coord(2), eyer_coord(2)] );
% 
% dist_eyes_px = eyer_coord(1) - eyel_coord(1);
% dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
% ratio = dist_eyes_px / dist_eyes_cm;
% 
% eyel_px = eyel_coord(1) - (padding_info.eyes.x * ratio);
% eyer_px = eyer_coord(1) + (padding_info.eyes.x * ratio);
% eyeb_px = eye_y - (padding_info.eyes.y * ratio);
% eyet_px = eye_y + (padding_info.eyes.y * ratio);
% 
% bounds = [ eyel_px, eyeb_px, eyer_px, eyet_px ];
% 
% end

% new way of adding padding 

facetl = key_map('facetl');
facetr = key_map('facetr');
% facebl = key_map('facebl');
% facebr = key_map('facebr');
eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );

facetl_coord = bfw.calibration.get_coord( calibration_data, facetl );
facetr_coord = bfw.calibration.get_coord( calibration_data, facetr );
% facebl_coord = bfw.calibration.get_coord( calibration_data, facebl );
% facebr_coord = bfw.calibration.get_coord( calibration_data, facebr );
eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );

eye_y = mean( [eyel_coord(2), eyer_coord(2)] );
% 
% dist_eyes_px = eyer_coord(1) - eyel_coord(1);
% dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
% ratio = dist_eyes_px / dist_eyes_cm;

% padsize = ([facetr_coord(1) - facetl_coord(1)] - [eyer_coord(1) - eyel_coord(1)])*7/24;
padsizeY = ([facetr_coord(1) - facetl_coord(1)] - [eyer_coord(1) - eyel_coord(1)])*7/24;
padsizeX = ([facetr_coord(1) - facetl_coord(1)] - [eyer_coord(1) - eyel_coord(1)])*7/24; % 1, 1.5, 2
% somewhere between 1/3 and 1/4
eyel_px = eyel_coord(1) - (padsizeX);
eyer_px = eyer_coord(1) + (padsizeX);
eyeb_px = eye_y - (padsizeY);
eyet_px = eye_y + (padsizeY);

bounds = [ eyel_px, eyeb_px, eyer_px, eyet_px ];

end