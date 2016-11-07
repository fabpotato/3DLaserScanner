%file name set
i = 0;
 fn = strcat('recorded',num2str(i),'.avi');
while exist(fn,'file')==2 
    i=i+1;
    fn = strcat('recorded',num2str(i),'.avi');

end


%end set
vid = videoinput('winvideo',2,'YUY2_640x480');
aviObject = avifile(fn);
preview(vid)

      set(vid, 'ReturnedColorspace', 'rgb');
     
% Create a new AVI file
for iFrame = 1:520                    % Capture 100 frames
  I = getsnapshot(vid);
  F = im2frame(I);    % Convert I to a movie frame
  pause(.01);
  aviObject = addframe(aviObject,F);  % Add the frame to the AVI file
end
aviObject = close(aviObject);         % Close the AVI file
closepreview(vid)