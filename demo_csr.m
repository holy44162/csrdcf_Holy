function demo_csr()

% set this to tracker directory
tracker_path = 'M:\files\computerVision\videoTracking\csrdcf_Holy';
% add paths
addpath(tracker_path);
addpath(fullfile(tracker_path, 'mex'));
addpath(fullfile(tracker_path, 'utils'));
addpath(fullfile(tracker_path, 'features'));

visualize_tracker = true;
use_reinitialization = true;

% choose name of the VOT sequence
sequence_name = 'winding1';    

% path to the folder with VOT sequences
dataset_path = 'M:\files\computerVision\videoTracking\dataResultsOftracker_benchmark_v1.1\UAV123_10fps'; % added by Holy 1903081446
base_path = 'm:\files\computerVision\videoTracking\dataResultsOftracker_benchmark_v1.1\UAV123_10fps\data_seq\UAV123_10fps\';
base_path = fullfile(base_path, sequence_name);
img_dir = dir(fullfile(base_path, '*.jpg'));

% initialize bounding box - [x,y,width, height]
% hided by Holy 1903081451
% gt = read_vot_regions(fullfile(base_path, 'groundtruth.txt'));
% gt8 = dlmread(fullfile(base_path, 'groundtruth.txt'));
% end of hide 1903081451

% added by Holy 1903081447
gt = read_vot_regions(fullfile(dataset_path, 'anno', 'UAV123_10fps', ...
        sprintf('%s.txt', sequence_name)));
gt8 = dlmread(fullfile(dataset_path, 'anno', 'UAV123_10fps', ...
        sprintf('%s.txt', sequence_name)));
% end of addition 1903081447

start_frame = 1;
n_failures = 0;
time = zeros(numel(img_dir), 1);
n_tracked = 0;

if visualize_tracker
    figure(1); clf;
end

frame = start_frame;
while frame <= numel(img_dir)  % tracking loop
    tStartFrame = tic; % added by Holy 1903081125
	% read frame
    impath = fullfile(base_path, img_dir(frame).name);
    img = imread(impath);
    
    tic()
	% initialize or track
    if frame == start_frame
        
        bb = gt8(frame,:) + 1;  % add 1: ground-truth top-left corner is (0,0)
        tracker = create_csr_tracker(img, bb);
        bb = gt(frame,:);  % just to prevent error when plotting
        
    else
        
        [tracker, bb] = track_csr_tracker(tracker, img);
        
    end
    time(frame) = toc();
    
    n_tracked = n_tracked + 1;
    
    % visualization and failure detection
    if visualize_tracker
        % added by Holy 1903081126
        frameElapsedTime = toc(tStartFrame);
        fps = 1/frameElapsedTime;
        % end of addition 1903081126
        figure(1); if(size(img,3)<3), colormap gray; end
        imagesc(uint8(img))
        hold on;
        rectangle('Position',bb,'LineWidth',1,'EdgeColor','b');

        text(15, 25, num2str(n_failures), 'Color','r', 'FontSize', ...
            15, 'FontWeight', 'bold');
        
        text(10, 10, num2str(fps), 'color', [0 1 1]); % added by Holy 1903081127
        
        if use_reinitialization  % detect failures and reinit
            area = rectint(bb, gt(frame,:));
            if area < eps && use_reinitialization
                disp('Failure detected. Reinitializing tracker...');
                frame = frame + 4;  % skip 5 frames at reinit (like VOT)
                start_frame = frame + 1;
                n_failures = n_failures + 1;
            end
        end

        hold off;
        if frame == start_frame
            truesize;
        end
        drawnow; 
    end
    
    frame = frame + 1;

end

fps = n_tracked / sum(time);
fprintf('FPS: %.1f\n', fps);

end  % endfunction
