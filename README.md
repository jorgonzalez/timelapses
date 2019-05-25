# timelapses
Scripts to help processing batches of images for timelapse photography.
All scripts expect the names of the photos begin with DSC and that the sorting
is ascendant (e.g. 0001-0100).

## 3scenes.sh
	Description:	Script to compose a batch of images using three 
			directories as a source.
```
	./3scenes.sh -m <VALUE> -s <VALUE> -t <VALUE> -b <VALUE> -w <VALUE> -o <VALUE>
	-m directory where the files for the main scene are
	-s directory where the files for the second scene are
	-t directory where the files for the third scene are
	-w width of the main scene (in percentage)
	-o output directory
	-b OPTIONAL pixels of the separation bar
	-v show version number
	-h show this help
```

## add_mask_transparency.sh
	Description:	Script to apply a mask to a set of pictures in a
			directory.
```
	./add_mask_transparency.sh -d <VALUE> -m <VALUE> -g -r
	-d directory where the files are
	-m path to the mask file
	-g OPTIONAL progressive, will apply mask from 100% transparency to 0%
	-r OPTIONAL reverse, will apply mask from 0% transparency to 100%
	-p OPTIONAL (preview) applies the modifications to the first foto to see the result
	-v show version number
	-h show this help
```

## align.sh
	Description:	Script to align images in a directory. Uses 
			align_image_stack binary from hugin.
```
	./align.sh -d <VALUE>
	-d directory where the files are
	-b OPTIONAL block number of images to process (default 3)
	-p OPTIONAL number of control points between images (default 40)
	-g OPTIONAL grid, break the image into a rectangular grid (default 1)
	-n OPTIONAL do not use first image as base model
	-y OPTIONAL copy original into ORIGINAL_aligned
	-v show version number
	-h show this help
```

## blend_videos.sh
	Description:	Script to blend two videos together.

## compose.sh
	Description:	Script to make a composition out of a base (static) 
			image and a set of background images.

```
	./compose.sh -d <VALUE>
	-s source image (foreground image)
	-b directory with the background images
	-d output directory
	-r OPTIONAL reverse order of background images
	-p OPTIONAL (preview) applies the modifications to the first foto to see the result
	-v show version number
	-h show this help
```
## courtain.sh
	
	Description:	Script to do a courtain transition between two sets of images.
```
	./courtain.sh -m <VALUE> -s <VALUE> -b <VALUE> -o <VALUE>
	-m directory where the files for the main scene are
	-s directory where the files for the second scene are
	-i transition images betwen scenes (in frames; default 10)
	-t OPTIONAL direction of the bars ltr, rtl, utd, dtu (default left-to-right)
	-o output directory
	-v show version number
	-h show this help
```

## create_time_lapse.sh
	Description:	Script to create a video out of pictures. It can resize
			the pictures based on their width keeping the 
			proportion, crawl through directories of the target
			directory where the pictures are, output a black and
			white movie, enhance the picutres by modifiying the
			contrast, normalize the contrast in the pictures
			(by histogram), and fade in-out. 
			Requires imagemagick, ffmpeg and mencoder.

```
	./create_time_lapse.sh -r <VALUE> -f <VALUE> -d -a <VALUE> -m -e <VALUE> -b <VALUE> -n -f <VALUE> -c <VALUE> -l <VALUE> -t <TEXT> -z <VALUE>
	-r OPTIONAL (resize) the value of the new width; new height will be in proportion (e.g.: 2560, 2048, 1920, 1600, 1440, 1280, 1024...)
	-f OPTIONAL (fade) the number of frames for the fade-in and fade-out
	-d OPTIONAL (directory) to execute this script
	-u OPTIONAL (recursive) recursively crawl through the directories to create videos
	-a OPTIONAL frames per second (default is 25)
	-m OPTIONAL (monochrome) grayscale video output
	-e OPTIONAL (enhance) modify image contrast stretching the range of intensity by black point white point percentage, e.g. <1x2%>
	-b OPTIONAL (brightness) modify the brightness-contrast in images by brightness contrast percentage, e.g. <0x3%>
	-w OPTIONAL (levels) modify the levels stretching the range of intensity by black point white point percentage, e.g. <0,90%>
	-n OPTIONAL (normalize) increase the image contrast stretching the range of intensity
	-c OPTIONAL (tint) use a color to tint the image; valid tints 'red', 'green' and 'blue' (requires tint value option -l <-200:200>)
	-t OPTIONAL (text) print a text in each picture (after applying the rest of the changes if any)
	-z OPTIONAL (zoom) zoom into an area with step; areas and step supported: <in1-5>, <out1-5>
	-s OPTIONAL (slide) move the focus -with step- of the images from <ltr1-2> to right, <rtl1-2> to left, <utd1-2> to down, <dtu1-2> to up
	-i OPTIONAL (tilt-shift) tilt-shift the images (very time consuming)
	-y OPTIONAL (hyperlapse) smooth the output of the hyperlapse
	-p OPTIONAL (preview) applies the modifications to the first photo to see the result
	-k OPTIONAL (kill output) no video output, just picture modification
	-x OPTIONAL Deflicker video
	-v show version number
	-h show this help
```

## deflicker.sh
	Description:	Script to deflicker a video.

```
	./deflicker.sh -s <VALUE>
	-s source video to deflicker
	-v show version number
	-h show this help
```

## heartbeat.sh
	Description:	Script to create a heartbeat effect using the base image and zooming on it.

```
	./heartbeat.sh -d <VALUE> -z <VALUE> -r
	-d directory where the files are
	-z Zoom factor
	-r Random zoom factor
	-v show version number
	-h show this help
```

## merge.sh
	Description:	Script to merge two scenes into one using a number of frames from each.

```
	./merge.sh -m <VALUE> -s <VALUE> -f <VALUE> -o <VALUE>
	-m directory where the files for the first scene are
	-s directory where the files for the second scene are
	-t total number of images to have in the final scene
	-f frames to use from each scene before changing to another
	-o output directory
	-v show version number
	-h show this help
```

## perspective.sh
	Description:	Script to change the perspective of a batch of images.
			Based on four points in the original image (A1, B1, C1,
			D1) that will be distorted (A2, B2, C2, D2). These 
			points need to be input manually for each directory
			to be processed.
			Takes the directory to work on as argument.
			If there is a second argument, only generates the
			preview of the output.

```
	./perspective.sh -d <VALUE> -A <VALUE> -B <VALUE> -C <VALUE> -D <VALUE>
	-d directory where the files are
	-A -B -C -D pairs of coordinates to be mapped from (A1=600,1000;B1=600,2500;C1=3600,2500;D1=3600,1000)
	-p OPTIONAL (preview) applies the modifications to the first photo to see the result
	-f OPTIONAL force 16:9 perspective
	-v show version number
	-h show this help
```

## play.sh
	Description:	Script to play a directory of images.

## repeat.sh
	Description:    Script to generate a given number of files out of a
			given directory and the number of wanted images.
```
	./repeat.sh -d <VALUE> -n <VALUE>
	-d directory where the files are
	-n number of pictures to end up with
	-v show version number
	-h show this help
```

## resize.sh
	Description:	Script to resize batches of images given a directory
			and a new width and height.

```
	./resize.sh -d <VALUE> -w <VALUE> -e <VALUE>
	-d directory where the files are
	-w new width of the image
	-e new height of the image
	-y OPTIONAL copy original into ORIGINAL_NEW-WIDTHxNEW-HEIGHT
	-p OPTIONAL (preview) applies the modifications to the first photo to see the result
	-v show version number
	-h show this help
```

## rotate_crop.sh
	Description:	Script to align rotate and crop batches of images in
			the same directory.

```
	./rotate_crop.sh -d <VALUE> -r <VALUE> -z <VALUE> -t <VALUE>
	-d directory where the files are
	-r rotate the picture (- is anti-h; + is h)
	-z pixels to crop horizontally
	-t pixels to crop vertically
	-p OPTIONAL (preview) applies the modifications to the first foto to see the result
	-v show version number
	-h show this help
```

## shake.sh
	Description:	Script to shake an image using the base image and
			moving it to the sides using transparency.

```
	./shake.sh -d <VALUE> -z -t -b -s <VALUE> -p
	-d directory where the files are
	-z horizontal shake
	-t total shake
	-s OPTIONAL: shakeness percentage
	-p OPTIONAL: preview
	-v show version number
	-h show this help
```

## sliding_bars.sh
	Description:	Script to fade-in fade-out a video using bars of
			adjustable size that dissapear/appear.

```
	./sliding_bars.sh -d <VALUE> -o <VALUE> -b <VALUE> -a <VALUE> -f <VALUE> -t <VALUE> -r <VALUE>
	-d directory where the files are
	-o output directory
	-b OPTIONAL number of separating bars (default 16)
	-a OPTIONAL frames per bar (default is 4)
	-f OPTIONAL (fade) fade in or fade out (default in)
	-t OPTIONAL direction of the bars ltr or rtl (default left-to-right)
	-e OPTIONAL apply transparency to the bars
	-v show version number
	-h show this help
```

## split.sh
	Description:	Script to compose a batch of images using two
			directories as source.

```
	./split.sh -m <VALUE> -s <VALUE> -c <VALUE> -o <VALUE>
	-m directory where the files for the main scene are
	-s directory where the files for the second scene are
	-c chunk, percentage of the first image to take
	-o output directory
	-b OPTIONAL pixels of the separation bar
	-e OPTIONAL (compose) show whole main scene, then split in half showing both scenes, then show whole second scene
	-p OPTIONAL (preview) applies the modifications to the first foto to see the result
	-v show version number
	-h show this help
```
## stabilize.sh
	Description:	Script to stabilize a shaky video.

```
	./stabilize.sh -s <VALUE>
	-s source video to stabilize
	-v show version number
	-h show this help
```
