
function rois = add_out_face_ROI(rois, i)

tag = 0;

faceRect = rois.m1.rects('face');
faceH = [faceRect(3) - faceRect(1)]/2;
faceV = [faceRect(4) - faceRect(2)]/2;

if tag == 1
% define out face ROI based on density based clustering method
x = load('out_face_cluster_ctr.mat'); % DBSCAN results
out_face_ctr = x.ctrs{i}.ctr;
% invert it back, we invert it for the plot, now we are using this to
% define new ROI, invert y back
out_face_ctr(2) = 768 - out_face_ctr(2);
rois.m1.rects('out face') = [out_face_ctr(1)-faceH out_face_ctr(2)-faceV out_face_ctr(1)+faceH out_face_ctr(2)+faceV];
rois.m2.rects('out face') = [1 2 3 4]; % I have not calculated this, do it later
end

% the center of out face cluster 1 in the upper right corner of the monitor
ctr1 = [2048 0];
rois.m1.rects('out face 1') = [ctr1(1)-faceH ctr1(2)-faceV ctr1(1)+faceH ctr1(2)+faceV];
rois.m2.rects('out face 1') = [ctr1(1)-faceH ctr1(2)-faceV ctr1(1)+faceH ctr1(2)+faceV];

% the center of out face cluster 1 in the upper right corner of the monitor
ctr2 = [1536 0];
rois.m1.rects('out face 2') = [ctr2(1)-faceH ctr2(2)-faceV ctr2(1)+faceH ctr2(2)+faceV];
rois.m2.rects('out face 2') = [ctr2(1)-faceH ctr2(2)-faceV ctr2(1)+faceH ctr2(2)+faceV];


