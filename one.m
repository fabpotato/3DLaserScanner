function [X,Y,Z,R] = onetyone(filename, laserColor, calFrame, camAngle)
clc;
%file name set
i = 0;
 fn = strcat('recorded',num2str(i),'.avi');
while exist(fn,'file')==2 
    i=i+1;
    fn = strcat('recorded',num2str(i),'.avi');

end


%end set

vid = videoinput('winvideo',2,'YUY2_640x480');
 set(vid,'FramesPerTrigger',1800);  %%this will define the length of video 200/frame rate = 6 seconds.
 set(getselectedsource(vid),'FrameRate','30');
[frames,time] = getdata(vid, get(vid,'FramesAvailable'));
framerate = 30  %fps= ??
set(vid,'FrameGrabInterval',1);  %this will take 1 frame out of 2 frames captured
capturetime = 30;  %%what is this doing??
interval = get(vid,'FrameGrabInterval');
numframes = floor(capturetime * framerate / interval) % 30*30/2=450 frames; 450/30 =15 seconds; ?? also frames per trigger/frame_rate =~6 sec ;
set(vid,'LoggingMode','disk');
avi = VideoWriter(fn);
set(vid,'DiskLogger',avi);
start(vid);
wait(vid,Inf); % Wait for the capture to complete before continuing.
avi = get(vid,'DiskLogger');
close(avi);

 
 

% if you don't know the camera angle, this just assumes its pi/16
if nargin<4
    camAngle = pi/16;
end;

% if no calibration frame is given, it uses the first frame
if nargin<3
    calFrame = 180; %%%gotta change it 
end;

% if no laser color is given, it assumes red.
if nargin<2
    laserColor = 'red';    
end;
switch laserColor
    case 'red'
        laserInd = 1;
    case 'green'
        laserInd = 2;
    case 'blue'
        laserInd = 3;
    otherwise
        laserInd = 1;
end;


% get the calibration image and filter out the laser color
m = VideoReader(fn);
calImg = read(m,calFrame);
calImg = calImg(:,:,1);

% show calibration image
% rotate image
figure(1);
imshow(calImg);
xlabel({'Calibrate rotation of image.','Draw line from top to bottom that should be verticle.', 'Left click to start. Right click to end.'});
[rotX, rotY] = getline(1);
rotAngle = 180/pi*atan2(rotY(2)-rotY(1),rotX(2)-rotX(1))-90;

figure(1);clf;
calImg = imrotate(calImg, rotAngle);
imshow(calImg);

% get center line
xlabel('Click mouse for center line');
set(gcf, 'Pointer', 'fullcrosshair');
[x,y]=ginput(1);
line([x, x], [1,size(calImg,2)]);

% get ROI
xlabel('Draw rectangle over region of interest');
rect = getrect;
% the math changes a little depending on whether
% your laser line is to the left or right of the
% camera

if rect(1)>x
    xoffset = rect(1)-x;
else    
    xoffset = (rect(1)+rect(3))-x;
end;
rectangle('Position', rect, 'EdgeColor', [1,0,0]);
set(gcf, 'Pointer', 'arrow');

% create blurring filter to smooth the
% image before finding the laser line
h = ones(5,1)/5;

% set threshold for detecting laser line
threshold = 0.1;
%%yahan tq chala tha
% iterate through frames, find laser line
nfo = m.NumberOfFrames;
Nframes = floor(nfo/360);%round(nfo.NumFrames/360);
frameTab = 1:Nframes:nfo;

for k=1:length(frameTab)
    disp(sprintf('Analyzing frame #%d', frameTab(k)));
    % read from from video file
    a = read(m,frameTab(k));
    %m = read(filename,frameTab(k));
    Img = imrotate(a(:,:,1), rotAngle);
    
    % crop image to the region of interest
    imgCrop = imcrop(Img, rect);
    
     % filter (i.e. blur) image, and convert from uint8 to double
    imgFilt = filter2(h,im2double(imgCrop));
    
     % for each row find maximum image intensity and x position of maximum 
    [mx(k,:), rtmp(k,:)] = max(imgFilt');

    % if there is a laser line, use interp to fill in any "holes"
    % if there is no laser line, set to 0
    if (length(find(mx(k,:)>threshold))>=2)
        r(k,:)=interp1(find(mx(k,:)>threshold),...
            rtmp(k,find(mx(k,:)>threshold)),1:size(rtmp,2));
    else
        r(k,:)=zeros(1,size(rtmp,2));
    end;
    
      % draw image and calculated laser line
    figure(2);clf;
    imshow(imgFilt);
    hold on;
    plot(r(k,:),1:size(r,2),'r');
end;
%%yahan tq bh chala h

% convert x position of laser line in image, to a real radius
if xoffset>0
    R = (r+xoffset)./sin(camAngle);
else
    R = (rect(3)-r-xoffset)./sin(camAngle);
end;
theta = linspace(0,2*pi,length(frameTab))';

% convert to surface coordinates
X = R.*repmat(cos(theta),1,size(imgFilt,1));
Y = R.*repmat(sin(theta),1,size(imgFilt,1));
Z = -repmat(1:size(imgFilt,1),length(theta),1);

% show image
figure(22);
S = surf(X,Y,Z,R);
set(S, 'LineStyle', 'none');
axis square;

    