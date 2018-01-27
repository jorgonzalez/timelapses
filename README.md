# timelapses
Scripts to help processing images for timelapses

## add_mask_transparency.sh
 	Description:	Script to apply a mask to a set of pictures in an directory.

## align.sh
 	Description:	Script to align images in a directory. Uses align_image_stack binary from hugin.

## blend_videos.sh
 	Description:	Script to blend two videos together.

## compose.sh
 	Description:	Script to make a composition out of a base (static) image and a set of background images.

## create_time_lapse.sh
 	Description:	Script to create a video out of pictures. It can resize the pictures based on their width
			keeping the proportion, crawl through directories of the target directory where the
			pictures are, output a black and white movie, enhance the picutres by modifiying the
			contrast, normalize the contrast in the pictures (by histogram), and fade in-out.
			Requires imagemagick, ffmpeg and mencoder.

## deflicker.sh
 	Description:	Script to deflicker a video.

## perspective.sh
 	Description:	Script to change the perspective of a batch of images.
			Based on four points in the original image (A1, B1, C1, D1) that will be
			distorted (A2, B2, C2, D2). These points need to be input manually for each
			directory to be processed.
			Takes the directory to work on as argument.
			If there is a second argument, only generates the preview of the output.
## play.sh
 	Description:	Script to play a directory of images.

## repeat.sh
       Description:    Script to generate a given number of files out of a given directory and the number of wanted images.

## rotate_crop.sh
 	Description:	Script to align rotate and crop batches of images in the same directory.

## shake.sh
 	Description:	Script to shake an image using the base image and moving it to the sides using transparency.

## split.sh
 	Description:	Script to compose a batch of images using two directories as source.
